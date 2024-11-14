use crate::error::Error;
use crate::models::{MatchRecord, MatchStatus};
use sqlx::PgPool;

pub async fn get_match_by_id(pool: &PgPool, match_id: i32) -> Result<MatchRecord, Error> {
    sqlx::query_as!(
        MatchRecord,
        "SELECT id, wallet_id, start_time, end_time, play_data, player_point, status AS \"status: MatchStatus\" FROM match_record WHERE id = $1",
        match_id
    )
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => Error::NotFound,
        _ => Error::Database(e),
    })
}

pub async fn get_player_point_by_match_id(
    pool: &PgPool,
    match_id: i32,
) -> Result<Option<i32>, Error> {
    let point = sqlx::query_scalar!(
        "SELECT player_point FROM match_record WHERE id = $1",
        match_id
    )
    .fetch_one(pool)
    .await
    .map_err(Error::Database)?;
    Ok(point)
}

pub async fn get_all_match_records(pool: &PgPool) -> Result<Vec<MatchRecord>, Error> {
    sqlx::query_as!(
        MatchRecord,
        "SELECT id, wallet_id, start_time, end_time, play_data, player_point, status AS \"status: MatchStatus\" FROM match_record"
    )
    .fetch_all(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => Error::NotFound,
        _ => Error::Database(e),
    })
}

pub async fn create_match_record(pool: &PgPool, match_record: MatchRecord) -> Result<i32, Error> {
    let result = sqlx::query!(
        "INSERT INTO match_record (wallet_id, start_time, end_time, play_data, player_point, status) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id ",
        match_record.wallet_id,
        match_record.start_time,
        match_record.end_time,
        match_record.play_data,
        match_record.player_point,
        match_record.status.map(|s| s.to_string()).unwrap_or_default()
    )
    .fetch_one(pool)
    .await
    .map_err(Error::Database)?;
    Ok(result.id)
}

pub async fn create_match_with_bet_records(
    pool: &PgPool,
    match_record: MatchRecord,
    bet_id: i64,
) -> Result<(), Error> {
    let match_id = create_match_record(pool, match_record).await?;
    sqlx::query!(
        "INSERT INTO bet_record (id, match_id, requester_address, receiver_address, bet_tier, bet_amount, dead_line, timestamp, status) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
        bet_id,
        match_id as i64,
        "", // requester_address
        "", // receiver_address
        "", // bet_tier
        0.0, // bet_amount
        0, // dead_line
        0, // timestamp
        "" // status
    )
    .execute(pool)
    .await
    .map_err(Error::Database)?;

    Ok(())
}

pub async fn get_latest_match_id(pool: &PgPool) -> Result<Option<i32>, Error> {
    sqlx::query_scalar!("SELECT MAX(id) FROM match_record")
        .fetch_one(pool)
        .await
        .map_err(Error::Database)
}
