-- 1. Create the application user (run as postgres)
CREATE USER go_workshop WITH PASSWORD '<YOUR_SECURE_PASSWORD>';

-- 2. Grant Database level permissions
GRANT ALL PRIVILEGES ON DATABASE users_db TO go_workshop;

-- 3. Connect to the database
\c users_db;

-- 4. Grant Schema level permissions (Critical for creating new objects)
GRANT ALL ON SCHEMA public TO go_workshop;

-- 5. Create the table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL
);

-- 6. Ensure the application user owns the table and schema objects
ALTER TABLE users OWNER TO go_workshop;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO go_workshop;

-- 7. Insert data
INSERT INTO users (username, email) VALUES 
    ('cloud_runner', 'runner@example.com'),
    ('gopher_fan', 'go@example.com'),
    ('secure_armor', 'shield@example.com')
ON CONFLICT (username) DO NOTHING;
