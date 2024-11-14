use std::fmt;

use alloy::primitives::{I256, U256, U8};
use chrono::{NaiveDate, NaiveDateTime};
use serde::{Deserialize, Deserializer, Serialize};
use sqlx::FromRow;

// Enum types
#[derive(Debug, Serialize, Deserialize, PartialEq, Eq)]
pub enum PlayerStatus {
    Online,
    Offline,
}

#[derive(Debug, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
pub enum MatchStatus {
    OnMatch,
    OffMatch,
}

#[derive(Debug, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
pub enum BetStatus {
    Unknown,
    Pending,
    Resolved,
    Canceled,
}

#[derive(Debug, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
pub enum BetTier {
    Unknown,
    Bronze,
    Silver,
    Gold,
    Diamond,
}

#[derive(Debug, PartialEq)]
pub enum GameResult {
    Win = 1,
    Lose = 2,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Player {
    wallet_id: String,
    balance: U256,
    created_date: NaiveDateTime,
    update_date: NaiveDateTime,
    status: PlayerStatus,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct VaultTransaction {
    pub id: U256,
    pub wallet_id: String,
    pub transaction_type: U256,
    pub amount: U256,
    pub transaction_date: NaiveDateTime,
    pub status: U8,
    pub transaction_id: String,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct MatchRecord {
    pub id: i32,
    pub wallet_id: Option<String>,
    pub start_time: Option<i64>,
    pub end_time: Option<i64>,
    pub play_data: Option<String>,
    pub player_point: Option<i32>,
    pub status: Option<MatchStatus>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct BetRecord {
    pub id: i64,
    pub match_id: i64,
    pub requester_address: String,
    pub receiver_address: String,
    pub bet_tier: Option<BetTier>,
    pub bet_amount: f64,
    pub dead_line: i64,
    pub timestamp: i64,
    pub status: Option<BetStatus>,
}

impl fmt::Display for MatchStatus {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:?}", self) // Adjust this to your desired string representation
    }
}

impl fmt::Display for BetStatus {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:?}", self) // Adjust this to your desired string representation
    }
}

impl fmt::Display for BetTier {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:?}", self) // Adjust this to your desired string representation
    }
}

impl From<u8> for BetTier {
    fn from(value: u8) -> Self {
        match value {
            0 => BetTier::Unknown,
            1 => BetTier::Bronze,
            2 => BetTier::Silver,
            3 => BetTier::Gold,
            4 => BetTier::Diamond,
            _ => BetTier::Unknown,
        }
    }
}

impl From<u8> for BetStatus {
    fn from(value: u8) -> Self {
        match value {
            0 => BetStatus::Unknown,
            1 => BetStatus::Pending,
            2 => BetStatus::Resolved,
            3 => BetStatus::Canceled,
            _ => BetStatus::Unknown,
        }
    }
}
