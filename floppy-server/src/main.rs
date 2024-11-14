use actix_web::{get, web, App, HttpServer, Responder};
use alloy::transports::http::reqwest::Url;
use serde_json::{json, Value};
use sqlx::{postgres::PgPoolOptions, PgPool};
use std::fs;
use tokio::task;

mod bets_syncer;
mod db;
mod error;
mod event_listener;
mod models;
mod router;
mod signer;
mod state;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv::dotenv().ok();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to create pool");

    let event_listener = event_listener::EventListener::new(
        std::env::var("RPC_URL").expect("RPC_URL must be set"),
        pool.clone(),
    )
    .expect("Failed to create BetsSyncer");

    task::spawn(async move {
        if let Err(e) = event_listener.run().await {
            eprintln!("Error running event listener: {}", e);
        }
    });

    let server = HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(state::AppState {
                db_pool: pool.clone(),
                rpc_url: std::env::var("RPC_URL").expect("RPC_URL must be set"),
            }))
            .service(router::match_record::match_record_scope()) // Ensure this line is present
            .service(router::bet_record::bet_record_scope())
            .service(router::signer::signer_scope())
    })
    .bind(("127.0.0.1", 8080))?
    .run();

    server.await
}
