<?php

require_once __DIR__ . '/vendor/autoload.php';

use App\Bot;
use Longman\TelegramBot\Telegram;
use Longman\TelegramBot\Exception\TelegramException;

// Load environment variables
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

try {
    // Create Telegram API object
    $telegram = new Telegram(
        getenv('TELEGRAM_BOT_TOKEN'),
        getenv('TELEGRAM_BOT_USERNAME')
    );

    // Handle webhook request
    $telegram->handle();

    // Initialize bot
    $bot = new Bot();

    // Get update from Telegram
    $update = $telegram->getUpdate();

    // Handle the update
    $bot->handleUpdate($update);

} catch (TelegramException $e) {
    // Log telegram errors
    error_log($e->getMessage());
    http_response_code(500);
    echo "Error: " . $e->getMessage();
} catch (\Exception $e) {
    // Log other errors
    error_log($e->getMessage());
    http_response_code(500);
    echo "Error: " . $e->getMessage();
} 