<?php
// Database Configuration
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'telegram_ad_bot');

// Telegram Bot Configuration
define('BOT_TOKEN', 'YOUR_BOT_TOKEN');
define('BOT_USERNAME', 'YOUR_BOT_USERNAME');
define('WEBHOOK_URL', 'https://your-domain.com/webhook.php');

// Mini App Configuration
define('MINI_APP_URL', 'https://your-domain.com/mini-app');

// Admin Configuration
define('ADMIN_USER_IDS', [123456789]); // Array of admin Telegram user IDs

// Campaign Settings
define('MIN_CAMPAIGN_BUDGET', 1000);
define('MAX_CAMPAIGN_BUDGET', 1000000);
define('DEFAULT_HOURLY_RATE', 1000);
define('DEFAULT_DAILY_RATE', 20000);

// Security
define('JWT_SECRET', 'your-secret-key');
define('ENCRYPTION_KEY', 'your-encryption-key');

// Error Reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Time Zone
date_default_timezone_set('Asia/Tehran');

// Database Connection
function getDBConnection() {
    try {
        $conn = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME,
            DB_USER,
            DB_PASS,
            array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8'")
        );
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $conn;
    } catch(PDOException $e) {
        die("Connection failed: " . $e->getMessage());
    }
} 