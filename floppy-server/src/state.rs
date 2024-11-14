use sqlx::PgPool;

pub struct AppState {
    pub db_pool: PgPool,
    pub rpc_url: String,
}

impl AppState {
    pub fn new(db_pool: PgPool, rpc_url: String) -> Self {
        Self { db_pool, rpc_url }
    }
}
