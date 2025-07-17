-- This SQL script to implement a basic 2FA system using MySQL only.
-- Author: [Takshil Khurana]
-- Date: [19-06-2025]

-- ================================================================
-- Table Definitions
-- ================================================================
use 2fa;
-- 1. Users Table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash CHAR(64) NOT NULL,
    is_locked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. User 2FA Methods
CREATE TABLE user_2fa_methods (
    method_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    method ENUM('SMS', 'EMAIL', 'TOKEN') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- 3. Two-Factor Codes
CREATE TABLE twofa_codes (
    code_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    code VARCHAR(10) NOT NULL,
    expiration_time DATETIME NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- 4. Login Attempts
CREATE TABLE login_attempts (
    attempt_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    attempt_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- 5. Audit Logs
CREATE TABLE audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    activity_type ENUM('LOGIN', '2FA_VERIFICATION', 'ACCOUNT_LOCKED') NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ================================================================
-- Stored Procedures
-- ================================================================

DELIMITER $$

-- Register a new user
CREATE PROCEDURE RegisterUser(IN uname VARCHAR(100), IN email VARCHAR(100), IN pwd_hash CHAR(64))
BEGIN
    INSERT INTO users (username, email, password_hash) VALUES (uname, email, pwd_hash);
END$$

-- Generate a new 2FA code
CREATE PROCEDURE Generate2FACode(IN uid INT, IN generated_code VARCHAR(10), IN expire_in_minutes INT)
BEGIN
    INSERT INTO twofa_codes (user_id, code, expiration_time)
    VALUES (uid, generated_code, DATE_ADD(NOW(), INTERVAL expire_in_minutes MINUTE));
END$$

-- Validate the 2FA code
CREATE PROCEDURE Validate2FACode(IN uid INT, IN input_code VARCHAR(10), OUT is_valid BOOLEAN)
BEGIN
    DECLARE code_valid INT;
    SELECT COUNT(*) INTO code_valid
    FROM twofa_codes
    WHERE user_id = uid AND code = input_code AND is_used = FALSE AND expiration_time > NOW();

    SET is_valid = (code_valid > 0);

    IF is_valid THEN
        UPDATE twofa_codes SET is_used = TRUE WHERE user_id = uid AND code = input_code;
    END IF;
END$$

-- Log login attempts and apply lockout policy
CREATE PROCEDURE LogLoginAttempt(IN uid INT, IN was_success BOOLEAN)
BEGIN
    INSERT INTO login_attempts (user_id, success) VALUES (uid, was_success);

    DECLARE recent_failures INT;
    SELECT COUNT(*) INTO recent_failures FROM login_attempts
    WHERE user_id = uid AND success = FALSE AND attempt_time > DATE_SUB(NOW(), INTERVAL 15 MINUTE);

    IF recent_failures >= 5 THEN
        UPDATE users SET is_locked = TRUE WHERE user_id = uid;
        INSERT INTO audit_logs (user_id, activity_type, details)
        VALUES (uid, 'ACCOUNT_LOCKED', 'Too many failed attempts');
    END IF;
END$$

