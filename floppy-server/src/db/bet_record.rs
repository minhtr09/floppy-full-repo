use crate::error::Error;
use crate::models::{BetRecord, BetStatus, BetTier};
use sqlx::PgPool;

pub async fn get_bet_record_by_id(pool: &PgPool, bet_id: i64) -> Result<BetRecord, Error> {
    sqlx::query_as!(
        BetRecord,
        "SELECT id, match_id, requester_address, receiver_address, bet_tier AS \"bet_tier: BetTier\", bet_amount, dead_line, timestamp, status AS \"status: BetStatus\" FROM bet_record WHERE id = $1",
        bet_id
    )
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => Error::NotFound,
        _ => Error::Database(e),
    })
}

pub async fn get_all_pending_bet_ids(pool: &PgPool) -> Result<Vec<i64>, Error> {
    sqlx::query!(
        "SELECT id FROM bet_record WHERE status = $1",
        BetStatus::Pending.to_string()
    )
    .fetch_all(pool)
    .await
    .map(|rows| rows.into_iter().map(|row| row.id).collect())
    .map_err(Error::Database)
}

// pub async fn get_all_match_records(pool: &PgPool) -> Result<Vec<MatchRecord>, Error> {
//     sqlx::query_as!(
//         MatchRecord,
//         "SELECT id, wallet_id, start_time, end_time, play_data, player_point, status AS \"status: MatchStatus\" FROM match_record"
//     )
//     .fetch_all(pool)
//     .await
//     .map_err(|e| match e {
//         sqlx::Error::RowNotFound => Error::NotFound,
//         _ => Error::Database(e),
//     })
// }

pub async fn create_bet_record(pool: &PgPool, bet_record: BetRecord) -> Result<(), Error> {
    sqlx::query!(
        "INSERT INTO bet_record (id, match_id, requester_address, receiver_address, bet_tier, bet_amount, dead_line, timestamp, status) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id ",
        bet_record.id,
        bet_record.match_id as i32,
        bet_record.requester_address,
        bet_record.receiver_address,
        bet_record.bet_tier.map(|s| s.to_string()).unwrap_or_default(),
        bet_record.bet_amount,
        bet_record.dead_line,
        bet_record.timestamp,
        bet_record.status.map(|s| s.to_string()).unwrap_or_default()
    )
    .fetch_one(pool)
    .await
    .map_err(Error::Database)?;

    Ok(())
}

pub async fn bet_exists(pool: &PgPool, bet_id: i64) -> Result<bool, Error> {
    let result = sqlx::query!(
        "SELECT EXISTS(SELECT 1 FROM bet_record WHERE id = $1)",
        bet_id
    )
    .fetch_one(pool)
    .await
    .map_err(Error::Database)?;

    Ok(result.exists.unwrap_or(false))
}

pub async fn is_bet_exists(pool: &PgPool, bet_id: i64) -> Result<bool, Error> {
    let result = sqlx::query!(
        "SELECT EXISTS(SELECT 1 FROM bet_record WHERE id = $1)",
        bet_id
    )
    .fetch_one(pool)
    .await
    .map_err(Error::Database)?;

    Ok(result.exists.unwrap_or(false))
}

pub async fn is_bet_exists_in_match(
    pool: &PgPool,
    bet_id: i64,
    match_id: i64,
) -> Result<bool, Error> {
    let result = sqlx::query!(
        "SELECT EXISTS(SELECT 1 FROM bet_record WHERE id = $1 AND match_id = $2)",
        bet_id,
        match_id
    )
    .fetch_one(pool)
    .await
    .map_err(Error::Database)?;

    Ok(result.exists.unwrap_or(false))
}

pub async fn update_bet_record(pool: &PgPool, bet_record: BetRecord) -> Result<(), Error> {
    sqlx::query!(
        "UPDATE bet_record SET requester_address = $1, receiver_address = $2, bet_tier = $3, bet_amount = $4, dead_line = $5, timestamp = $6, status = $7 WHERE id = $8",
        bet_record.requester_address,
        bet_record.receiver_address,
        bet_record.bet_tier.map(|s| s.to_string()).unwrap_or_default(),
        bet_record.bet_amount,
        bet_record.dead_line,
        bet_record.timestamp,
        bet_record.status.map(|s| s.to_string()).unwrap_or_default(),
        bet_record.id
    )
    .execute(pool)
    .await
    .map_err(Error::Database)?;
    Ok(())
}

pub async fn update_match_id(pool: &PgPool, bet_id: i64, match_id: i64) -> Result<(), Error> {
    sqlx::query!(
        "UPDATE bet_record SET match_id = $1 WHERE id = $2",
        match_id,
        bet_id
    )
    .execute(pool)
    .await
    .map_err(Error::Database)?;
    Ok(())
}
