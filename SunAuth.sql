-- ---------------------------------------------------------------------------
-- SunAuth Support Tables
--
-- Author    : Mehmet Selcuk Batal <batalms@gmail.com>
-- Copyright : Copyright (c) 2025, Sunhill Technology <www.sunhillint.com>
-- License   : https://opensource.org/licenses/lgpl-3.0.html (LGPL v3.0)
-- Link      : https://github.com/msbatal/PHP-Authentication-Class
--
-- These are the tables SunAuth needs in addition to your own user table.
-- The default table prefix is "sun_" (configurable via the "prefix" option).
-- The user table (e.g. `users`) is yours and is NOT created here.
-- ---------------------------------------------------------------------------

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
