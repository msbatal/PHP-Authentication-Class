-- ---------------------------------------------------------------------------
-- SunAuth Test Database
--
-- Import this single file into a MySQL database, then open index.php.
-- It creates a demo `users` table with one sample user, plus the four
-- SunAuth support tables. (SunAuth.sql in this folder is the same support
-- tables on their own, for reference / production use with your own user table.)
--
-- Demo login  ->  email: demo@sunauth.test   password: demo1234
-- ---------------------------------------------------------------------------

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- Demo user table (this is YOUR table in a real project)
CREATE TABLE `users` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(100) DEFAULT NULL,
    `email` VARCHAR(190) NOT NULL,
    `password` VARCHAR(255) NOT NULL,
    `role` VARCHAR(50) DEFAULT 'user',
    `status` TINYINT(1) NOT NULL DEFAULT 1,
    `twofa_secret` VARCHAR(32) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Sample user (password "demo1234" hashed with password_hash / bcrypt)
INSERT INTO `users` (`id`, `username`, `email`, `password`, `role`, `status`, `twofa_secret`) VALUES
(1, 'demo', 'demo@sunauth.test', '$2y$10$km7V5CMf86PORN.EVwOhMu9ev74NKL3NaPwnU5z1UqNVJKPh1YT/C', 'admin', 1, NULL);

-- ------------------------- SunAuth support tables -------------------------

-- Active sessions (database backed, multi device aware)
CREATE TABLE IF NOT EXISTS `sun_sessions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INT UNSIGNED NOT NULL,
    `token_hash` CHAR(64) NOT NULL,
    `ip` VARCHAR(45) DEFAULT NULL,
    `user_agent` VARCHAR(255) DEFAULT NULL,
    `twofa_pending` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL,
    `last_activity` DATETIME NOT NULL,
    `expires_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `token_hash` (`token_hash`),
    KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Failed login attempts (brute force protection / lockout)
CREATE TABLE IF NOT EXISTS `sun_login_attempts` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(190) NOT NULL,
    `ip` VARCHAR(45) NOT NULL,
    `attempts` INT UNSIGNED NOT NULL DEFAULT 0,
    `last_attempt` DATETIME NOT NULL,
    `locked_until` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`, `ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Persistent remember-me tokens (selector + validator pattern)
CREATE TABLE IF NOT EXISTS `sun_remember_tokens` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INT UNSIGNED NOT NULL,
    `selector` CHAR(16) NOT NULL,
    `validator_hash` CHAR(64) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `selector` (`selector`),
    KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Password reset tokens
CREATE TABLE IF NOT EXISTS `sun_password_resets` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INT UNSIGNED NOT NULL,
    `token_hash` CHAR(64) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `used` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `token_hash` (`token_hash`),
    KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
