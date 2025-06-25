- Sample Usage Instructions
-- ================================================================

-- 1. Register a User
-- CALL RegisterUser('john_doe', 'john@example.com', SHA2('securepass', 256));

-- 2. Assign a 2FA Method (e.g., EMAIL)
-- INSERT INTO user_2fa_methods (user_id, method) VALUES (1, 'EMAIL');

-- 3. Generate 2FA Code
-- CALL Generate2FACode(1, '123456', 5);  -- Valid for 5 minutes

-- 4. Validate the Code
-- CALL Validate2FACode(1, '123456', @is_valid);
-- SELECT @is_valid;

-- 5. Log a Failed Login Attempt
-- CALL LogLoginAttempt(1, FALSE);

-- 6. Check if the User is Locked
-- SELECT is_locked FROM users WHERE user_id = 1;
