-- Database initialization script for Rubik Cube Game Platform
-- PostgreSQL Schema

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(32) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_admin BOOLEAN DEFAULT FALSE,
    banned_until TIMESTAMP NULL,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT NULL,
    CONSTRAINT check_username_length CHECK (LENGTH(username) >= 3),
    CONSTRAINT check_email_format CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Create game_scores table for tracking game history
CREATE TABLE IF NOT EXISTS game_scores (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_type VARCHAR(20) NOT NULL, -- '2048', 'sudoku', 'caro', 'rubik'
    score INTEGER DEFAULT 0,
    moves INTEGER DEFAULT 0,
    time_seconds INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    game_data JSONB NULL, -- Store additional game data
    CONSTRAINT check_game_type CHECK (game_type IN ('2048', 'sudoku', 'caro', 'rubik'))
);

-- Create rubik_solutions table for storing Rubik cube solutions
CREATE TABLE IF NOT EXISTS rubik_solutions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cube_state TEXT NOT NULL, -- 54 character string representing cube state
    solution TEXT NOT NULL, -- Solution steps (e.g., "R U R' U'")
    steps_count INTEGER NOT NULL,
    time_to_solve_ms INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sudoku_puzzles table
CREATE TABLE IF NOT EXISTS sudoku_puzzles (
    id SERIAL PRIMARY KEY,
    difficulty VARCHAR(10) NOT NULL, -- 'easy', 'medium', 'hard'
    puzzle_data TEXT NOT NULL, -- 81 character string (0 for empty)
    solution_data TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_difficulty CHECK (difficulty IN ('easy', 'medium', 'hard'))
);

-- Create game_2048_sessions table
CREATE TABLE IF NOT EXISTS game_2048_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    grid_state JSONB NOT NULL, -- 4x4 grid state
    score INTEGER DEFAULT 0,
    best_score INTEGER DEFAULT 0,
    game_over BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create caro_games table
CREATE TABLE IF NOT EXISTS caro_games (
    id SERIAL PRIMARY KEY,
    player1_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    player2_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- NULL for AI opponent
    board_size INTEGER DEFAULT 15, -- Standard caro board size
    board_state JSONB NOT NULL,
    current_turn VARCHAR(10) NOT NULL, -- 'player1' or 'player2'
    winner_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'in_progress', -- 'in_progress', 'finished', 'abandoned'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_status CHECK (status IN ('in_progress', 'finished', 'abandoned'))
);

-- Create user_activity_logs table
CREATE TABLE IF NOT EXISTS user_activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- 'login', 'logout', 'game_started', 'game_finished'
    activity_data JSONB NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create friendships table
CREATE TABLE IF NOT EXISTS friendships (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'rejected'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_friendship_status CHECK (status IN ('pending', 'accepted', 'rejected')),
    CONSTRAINT check_not_self_friend CHECK (user_id != friend_id),
    UNIQUE(user_id, friend_id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create announcements table
CREATE TABLE IF NOT EXISTS announcements (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'info', -- 'info', 'warning', 'success', 'error'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_announcement_type CHECK (type IN ('info', 'warning', 'success', 'error'))
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_game_scores_user_id ON game_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_game_scores_game_type ON game_scores(game_type);
CREATE INDEX IF NOT EXISTS idx_game_scores_score ON game_scores(score DESC);
CREATE INDEX IF NOT EXISTS idx_rubik_solutions_user_id ON rubik_solutions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_user_id ON user_activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

-- Insert default admin user (password: admin123, change this in production!)
-- Salt: 1234567890abcdef
-- Hash: SHA256(salt + password)
INSERT INTO users (username, email, password_hash, salt, is_admin)
VALUES ('admin', 'admin@rubikgame.com', 
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        '1234567890abcdef', TRUE)
ON CONFLICT (username) DO NOTHING;

-- Insert some sample sudoku puzzles
INSERT INTO sudoku_puzzles (difficulty, puzzle_data, solution_data) VALUES
('easy', '530070000600195000098000060800060003400803001700020006060000280000419005000080079',
        '534678912672195348198342567859761423426853791713924856961537284287419635345286179'),
('medium', '000075400000000008080190000300001060000000034000068170204000603900000020530200000',
          '693875412145632798782194356357421869816957234429368175274519683968743521531286947'),
('hard', '800000000003600000070090200050007000000045700000100030001000068008500010090000400',
        '812753649943682175675491283154237896369845721287169534431926857728534916596178432')
ON CONFLICT DO NOTHING;
