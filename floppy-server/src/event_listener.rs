use alloy::{
    primitives::{address, utils::format_units, Address, U256},
    providers::{Provider, ProviderBuilder, RootProvider},
    rpc::types::{BlockNumberOrTag, Filter},
    sol,
    sol_types::SolEvent,
    transports::http::Http,
};
use alloy_transport_http::{reqwest::Url, Client};
use eyre::Result;
use sqlx::PgPool;
use tokio::time::{interval, Duration};

use crate::{
    db::{bet_record, match_record},
    models::BetRecord,
};

pub struct EventListener {
    provider: RootProvider<Http<Client>>,
    db_pool: PgPool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BetPlaced {
    pub requester: Address,
    pub bet_id: U256,
}

sol! {
    #[allow(missing_docs)]
    #[sol(rpc)]
    FloppyGamble,
    "abi/FloppyGamble.json"
}

impl EventListener {
    pub fn new(rpc_url: String, db_pool: PgPool) -> Result<Self> {
        let url = Url::parse(&rpc_url)?;
        let provider = ProviderBuilder::new().on_http(url.clone());

        Ok(Self { provider, db_pool })
    }

    pub async fn run(&self) -> Result<()> {
        println!("Running event listener");
        let contract_address = address!("ec6be1d0c53489de129b2c13ac3edb393865c22f");

        let bet_placed_filter = Filter::new()
            .address(contract_address)
            .event("BetPlaced(address,uint256)");

        let mut interval = interval(Duration::from_secs(5));
        let mut last_block = BlockNumberOrTag::Latest;
        let gamble_contract = FloppyGamble::new(
            address!("ec6be1d0c53489de129b2c13ac3edb393865c22f"),
            self.provider.clone(),
        );

        loop {
            interval.tick().await;

            // Listen for BetPlaced events
            let bet_filter = bet_placed_filter.clone().from_block(last_block);
            match self.provider.get_logs(&bet_filter).await {
                Ok(logs) => {
                    for log in logs {
                        // Extract requester address and bet ID from the log
                        match log.topic0() {
                            // Match the `BetPlaced(address,uint256)` event.
                            Some(&FloppyGamble::BetPlaced::SIGNATURE_HASH) => {
                                let FloppyGamble::BetPlaced { requester, betId } =
                                    log.log_decode()?.inner.data;
                                println!("New bet placed by: {}, bet ID: {}", requester, betId);
                                let bet_info = gamble_contract.getBetInfoById(betId).call().await?;
                                self.sync_bet(betId, bet_info._0).await?;
                            }
                            _ => (),
                        }
                    }
                }
                Err(e) => eprintln!("Error fetching bet logs: {}", e),
            }
            // Update last block
            if let Ok(current_block) = self.provider.get_block_number().await {
                last_block = BlockNumberOrTag::Number(current_block);
            }
        }
    }

    async fn sync_bet(&self, bet_id: U256, bet_info: IFloppyGamble::BetInfo) -> Result<()> {
        let bet_record = BetRecord {
            id: bet_id.to_string().parse()?,
            match_id: 0,
            requester_address: bet_info.requester.to_string(),
            receiver_address: bet_info.receiver.to_string(),
            bet_tier: Some(bet_info.tier.into()),
            bet_amount: format_units(bet_info.amount, "ether")?.parse::<f64>()?,
            timestamp: bet_info.timestamp.to_string().parse()?,
            status: Some(bet_info.status.into()),
            dead_line: 0,
        };
        if bet_record::is_bet_exists(&self.db_pool, bet_record.id).await? {
            bet_record::update_bet_record(&self.db_pool, bet_record).await?;
        } else {
            bet_record::create_bet_record(&self.db_pool, bet_record).await?;
        }
        Ok(())
    }
}
