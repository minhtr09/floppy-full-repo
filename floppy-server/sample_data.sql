-- Sample data for player table
INSERT INTO player (wallet_id, balance, created_date, update_date, status) VALUES
('wallet1', 100.0, 1633036800, 1633036800, 'Online'),
('wallet2', 50.0, 1633036800, 1633036800, 'Offline');

-- Sample data for vault_transaction table
INSERT INTO vault_transaction (wallet_id, transaction_type, amount, transaction_date, status, transaction_id) VALUES
('wallet1', 1, 20.0, 1633036800, 1, 'txn1'),
('wallet2', 2, 15.0, 1633036800, 1, 'txn2');

-- Sample data for match_record table
INSERT INTO match_record (wallet_id, start_time, end_time, play_data, player_point, status) VALUES
('wallet1', 1633036800, 1633036900, 'data1', 10, 'OnMatch'),
('wallet2', 1633037000, 1633037100, 'data2', 5, 'OffMatch');

-- Sample data for bet_record table
INSERT INTO bet_record (id, match_id, requester_address, receiver_address, bet_tier, bet_amount, dead_line, timestamp, status) VALUES
(1, 1, 'address1', 'address2', 'Gold', 10.0, 1633037200, 1633036800, 'Unknown'),
(2, 2, 'address3', 'address4', 'Silver', 5.0, 1633037300, 1633037000, 'Unknown');