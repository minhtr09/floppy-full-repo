//! Example of signing a permit hash using a wallet.

use actix_web::cookie::time::format_description::modifier::UnixTimestamp;
use alloy::{
    primitives::{address, Address, U256},
    signers::{local::PrivateKeySigner, Signature, Signer},
    sol,
    sol_types::{eip712_domain, SolStruct},
};
use eyre::Result;
use serde::{Deserialize, Serialize};

sol! {
    #[allow(missing_docs)]
    #[derive(Deserialize, Serialize)]
    struct Permit {
        uint256 betId;
        address requester;
        address receiver;
        uint256 points;
        uint256 betAmount;
        uint256 deadline;
    }
}

pub struct SignData {
    pub permit: Permit,
    pub signature: Signature,
}

pub async fn sign_gamble_permit(
    bet_id: U256,
    requester: Address,
    receiver: Address,
    points: U256,
    bet_amount: U256,
) -> Result<SignData> {
    dotenv::dotenv().ok();

    let domain = eip712_domain! {
        name: "FloppyGamble",
        version: "1",
        chain_id: 2021,
        verifying_contract: address!("ec6Be1D0c53489dE129b2C13ac3EDb393865c22F"),
    };

    let signer: PrivateKeySigner = std::env::var("SIGNER_PK")
        .expect("SIGNER_PK must be set")
        .parse()
        .expect("should parse private key");

    let deadline = U256::from(chrono::Utc::now().timestamp() + 3600); // 1 hour in seconds

    let permit = Permit {
        betId: bet_id,
        requester,
        receiver,
        points,
        betAmount: bet_amount,
        deadline: deadline,
    };

    // Derive the EIP-712 signing hash.
    let hash = permit.eip712_signing_hash(&domain);

    // Sign the hash asynchronously with the wallet.
    let signature = signer.sign_hash(&hash).await?;
    Ok(SignData { permit, signature })
}

#[cfg(test)]
mod tests {
    use std::ops::Add;

    use super::*;
    use alloy::signers::local::PrivateKeySigner;

    #[tokio::test]
    async fn test_sign_gamble_permit() {
        // Define test inputs
        let bet_id = U256::from(1);
        let requester = address!("193542e0C9746e8a428b2a4430545AFdb87d95E8");
        let receiver = address!("193542e0C9746e8a428b2a4430545AFdb87d95E8");
        let points = U256::from(100);
        let bet_amount: alloy_primitives::Uint<256, 4> = U256::from(10);

        // Call the function
        let result = sign_gamble_permit(bet_id, requester, receiver, points, bet_amount).await;

        // Assert the result
        assert!(result.is_ok());
        let signature = result.unwrap();
    }
}
