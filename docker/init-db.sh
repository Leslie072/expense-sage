#!/bin/bash

# Database initialization script for Expense Sage
set -e

DB_PATH="/app/data/expense_sage.db"
BACKUP_PATH="/app/backup"

echo "Initializing Expense Sage database..."

# Create directories
mkdir -p /app/data
mkdir -p /app/backup

# Check if database exists
if [ ! -f "$DB_PATH" ]; then
    echo "Creating new database at $DB_PATH"
    
    # Create database with initial schema
    sqlite3 "$DB_PATH" <<EOF
-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    username TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    security_question TEXT,
    security_answer_hash TEXT,
    two_factor_secret TEXT,
    two_factor_enabled INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    user_type TEXT DEFAULT 'personal',
    business_name TEXT,
    business_registration_number TEXT
);

-- Admins table
CREATE TABLE IF NOT EXISTS admins (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    username TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    role INTEGER NOT NULL,
    permissions TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    last_login_at TEXT,
    profile_image_url TEXT,
    phone_number TEXT,
    department TEXT
);

-- Admin sessions table
CREATE TABLE IF NOT EXISTS admin_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    admin_id INTEGER NOT NULL,
    token TEXT UNIQUE NOT NULL,
    expires_at TEXT NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (admin_id) REFERENCES admins (id)
);

-- Admin login attempts table
CREATE TABLE IF NOT EXISTS admin_login_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    ip_address TEXT,
    success INTEGER NOT NULL,
    created_at TEXT NOT NULL
);

-- Accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    holderName TEXT,
    accountNumber TEXT,
    icon INTEGER,
    color INTEGER,
    isDefault INTEGER DEFAULT 0,
    user_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    icon INTEGER,
    color INTEGER,
    budget REAL DEFAULT 0,
    user_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL,
    description TEXT,
    date TEXT NOT NULL,
    category_id INTEGER,
    account_id INTEGER,
    user_id INTEGER,
    FOREIGN KEY (category_id) REFERENCES categories (id),
    FOREIGN KEY (account_id) REFERENCES accounts (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Recurring transactions table
CREATE TABLE IF NOT EXISTS recurring_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    description TEXT,
    frequency TEXT NOT NULL,
    next_date TEXT NOT NULL,
    category_id INTEGER,
    account_id INTEGER,
    user_id INTEGER,
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories (id),
    FOREIGN KEY (account_id) REFERENCES accounts (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(email);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_token ON admin_sessions(token);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(date);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);

EOF

    echo "Database schema created successfully"
else
    echo "Database already exists at $DB_PATH"
fi

# Set proper permissions
chmod 644 "$DB_PATH"
chown nginx:nginx "$DB_PATH" 2>/dev/null || true

echo "Database initialization completed"
