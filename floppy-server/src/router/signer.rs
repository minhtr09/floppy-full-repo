use std::str::FromStr;

use crate::{
    db::{bet_record, match_record},
    signer::{sign_gamble_permit, Permit},
    state::AppState,
};
use actix_web::{get, post, web, HttpResponse, Responder, Scope};
use alloy::{
    hex,
    primitives::{address, Address, U256},
    signers::{local::PrivateKeySigner, Signature, Signer},
    sol_types::{eip712_domain, SolStruct},
};
use serde::{Deserialize, Serialize};

// Define a scope for match_record routes
pub fn signer_scope() -> Scope {
    web::scope("/signer").service(get_gamble_signature)
}

// Define a struct to represent the incoming data
#[derive(Deserialize, Serialize)]
struct GamblePermitData {
    bet_id: U256,
    requester: Address,
    receiver: Address,
    points: U256,
    bet_amount: U256,
}

#[derive(Deserialize, Serialize)]
struct VaultPermitData {
    bet_id: U256,
    requester: Address,
    recipient: Address,
    amount: U256,
}

#[get("/gamble-signature/{bet_id}")]
async fn get_gamble_signature(bet_id: web::Path<i64>, data: web::Data<AppState>) -> impl Responder {
    let bet_id_value = bet_id.into_inner();
    let bet_record = bet_record::get_bet_record_by_id(&data.db_pool, bet_id_value)
        .await
        .unwrap();
    let points =
        match_record::get_player_point_by_match_id(&data.db_pool, bet_record.match_id as i32)
            .await
            .unwrap();
    let result = sign_gamble_permit(
        U256::from(bet_id_value),
        Address::from_str(&bet_record.requester_address).unwrap(),
        Address::from_str(&bet_record.receiver_address).unwrap(),
        U256::from(points.unwrap_or(0)),
        U256::from(10000000000000000001 as i128),
    )
    .await;

    match result {
        Ok(sign_data) => {
            let bytes: [u8; 65] = sign_data.signature.into();
            HttpResponse::Ok().json(format!("0x{}", hex::encode(bytes)))
        }
        Err(e) => HttpResponse::InternalServerError().json(e.to_string()),
    }
}

pub fn recover_gamble_signature(
    signature: &str,
    data: Permit,
) -> Result<Address, alloy::primitives::SignatureError> {
    let domain = eip712_domain! {
        name: "FloppyGamble",
        version: "1",
        chain_id: 2021,
        verifying_contract: address!("ec6Be1D0c53489dE129b2C13ac3EDb393865c22F"),
    };

    let hash = data.eip712_signing_hash(&domain);
    let signature = Signature::from_str(signature).unwrap();

    let address = signature.recover_address_from_prehash(&hash)?;
    Ok(address)
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, App};
    use alloy::primitives::{Address, U256};

    #[actix_web::test]
    async fn test_get_gamble_signature() {
        let app = test::init_service(App::new().service(signer_scope())).await;

        let permit_data = GamblePermitData {
            bet_id: U256::from(1),
            requester: Address::ZERO,
            receiver: Address::ZERO,
            points: U256::from(10),
            bet_amount: U256::from(100),
        };

        let req = test::TestRequest::post()
            .uri("/signer/gamble-signature")
            .set_json(&permit_data)
            .to_request();

        let resp = test::call_service(&app, req).await;

        println!("resp: {:?}", resp.into_body());
    }
}
