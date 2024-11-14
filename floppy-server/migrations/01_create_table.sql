-- Create tables
CREATE TABLE IF NOT EXISTS player (
    wallet_id TEXT PRIMARY KEY,
    balance REAL DEFAULT 0,
    created_date BIGINT,
    update_date BIGINT,
    status TEXT DEFAULT 'Offline'  -- Changed from player_status to TEXT
);

CREATE TABLE IF NOT EXISTS vault_transaction (
    id SERIAL PRIMARY KEY,
    wallet_id TEXT,
    transaction_type INTEGER,
    amount REAL DEFAULT 0,
    transaction_date BIGINT,
    status INTEGER DEFAULT 1,
    transaction_id TEXT
);

CREATE TABLE IF NOT EXISTS match_record (
    id SERIAL PRIMARY KEY,
    wallet_id TEXT,
    start_time BIGINT,
    end_time BIGINT,
    play_data TEXT,
    player_point INTEGER DEFAULT 0,
    status TEXT DEFAULT 'OffMatch'  -- Changed from match_status to TEXT
);

CREATE TABLE IF NOT EXISTS bet_record (
    id BIGINT PRIMARY KEY,
    match_id BIGINT NOT NULL,
    requester_address TEXT NOT NULL,
    receiver_address TEXT NOT NULL,
    bet_tier TEXT DEFAULT 'Unknown',  -- Changed from bet_tier to TEXT
    bet_amount float NOT NULL,
    dead_line BIGINT NOT NULL,
    timestamp BIGINT NOT NULL,
    status TEXT DEFAULT 'Unknown'
);