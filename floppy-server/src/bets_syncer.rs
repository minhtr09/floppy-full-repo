use crate::{db::bet_record, models::BetRecord};
use alloy::{
    primitives::{address, utils::format_units},
    providers::{ProviderBuilder, RootProvider},
    sol,
    transports::http::{reqwest::Url, Client, Http},
};
use eyre::Result;
use sqlx::PgPool;
use tokio::time::{interval, Duration};
use FloppyGamble::FloppyGambleInstance;

sol! {
    #[allow(missing_docs)]
    #[sol(rpc)]
    FloppyGamble,
    "abi/FloppyGamble.json"
}

sol! {
    #[allow(missing_docs)]
    #[sol(rpc)]
    FloppyVault,
    "abi/FloppyVault.json"
}

pub enum BetStatus {
    Unknown,
    Pending,
    Resolved,
    Canceled,
}

pub struct BetsSyncer {
    url: Url,
    db_pool: PgPool,
    provider: RootProvider<Http<Client>>,
    gamble_contract: FloppyGambleInstance<Http<Client>, RootProvider<Http<Client>>>,
}

impl BetsSyncer {
    pub fn new(rpc_url: String, db_pool: PgPool) -> Result<Self> {
        let url = Url::parse(&rpc_url)?;
        let provider = ProviderBuilder::new().on_http(url.clone());
        let gamble_contract: FloppyGambleInstance<Http<Client>, RootProvider<Http<Client>>> =
            FloppyGamble::new(
                address!("ec6be1d0c53489de129b2c13ac3edb393865c22f"),
                provider.clone(),
            );
        Ok(Self {
            url,
            db_pool,
            provider,
            gamble_contract,
        })
    }

    pub async fn run(&self) -> Result<()> {
        println!("Starting Contract client...");
        let mut interval = interval(Duration::from_secs(60));

        loop {
            tokio::select! {
                _ = interval.tick() => {
                    if let Err(e) = self.fetch_bets().await {
                        eprintln!("Error fetching bets: {}", e);
                    }
                }
            }
        }
    }

    async fn sync_bets_in_db(
        &self,
        bet_ids: Vec<alloy::primitives::Uint<256, 4>>,
        bet_infos: Vec<IFloppyGamble::BetInfo>,
    ) -> Result<()> {
        let length = bet_ids.len();
        for i in 0..length {
            let bet_id = bet_ids[i];
            let bet_info = bet_infos[i].clone();
            if !bet_record::bet_exists(&self.db_pool, bet_id.to_string().parse()?).await? {
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
                bet_record::create_bet_record(&self.db_pool, bet_record).await?;
            }
        }
        Ok(())
    }

    async fn fetch_bets(&self) -> Result<()> {
        let result = self
            .gamble_contract
            .getBetsByStatus(BetStatus::Pending as u8)
            .call()
            .await?;
        let bet_ids: Vec<alloy::primitives::Uint<256, 4>> = result._0;
        let bet_infos: Vec<IFloppyGamble::BetInfo> = result._1;

        self.sync_bets_in_db(bet_ids, bet_infos).await?;
        Ok(())
    }
}
