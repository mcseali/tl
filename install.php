<?php
require_once __DIR__ . '/vendor/autoload.php';

use Dotenv\Dotenv;
use App\Database;
use App\TelegramBot;

class Installer
{
    private $db;
    private $telegram;
    private $config = [];
    private $errors = [];

    public function __construct()
    {
        $this->checkRequirements();
        $this->getConfigFromUser();
    }

    /**
     * دریافت تنظیمات از کاربر
     */
    private function getConfigFromUser()
    {
        echo "🔧 به نصب خودکار ربات تبلیغچی خوش آمدید!\n\n";

        // تنظیمات دیتابیس
        echo "📊 تنظیمات دیتابیس:\n";
        $this->config['db_host'] = $this->ask("آدرس هاست دیتابیس (پیش‌فرض: localhost): ", "localhost");
        $this->config['db_name'] = $this->ask("نام دیتابیس (پیش‌فرض: telegram_ads): ", "telegram_ads");
        $this->config['db_user'] = $this->ask("نام کاربری دیتابیس (پیش‌فرض: root): ", "root");
        $this->config['db_pass'] = $this->ask("رمز عبور دیتابیس: ");

        // تنظیمات تلگرام
        echo "\n🤖 تنظیمات تلگرام:\n";
        $this->config['bot_token'] = $this->ask("توکن بات تلگرام: ");
        $this->config['admin_id'] = $this->ask("شناسه عددی مدیر (Chat ID): ");

        // تنظیمات دامنه و SSL
        echo "\n🌐 تنظیمات دامنه و SSL:\n";
        $this->config['domain'] = $this->ask("دامنه سایت (مثال: example.com): ");
        $this->config['ssl_enabled'] = $this->ask("آیا می‌خواهید SSL فعال شود؟ (بله/خیر): ", "بله");
        $this->config['ssl_enabled'] = strtolower($this->config['ssl_enabled']) === 'بله' ? 'true' : 'false';

        // تنظیمات امنیتی
        echo "\n🔒 تنظیمات امنیتی:\n";
        $this->config['jwt_secret'] = bin2hex(random_bytes(32));
        echo "کلید امنیتی JWT به طور خودکار تولید شد.\n";

        // نمایش خلاصه تنظیمات
        echo "\n📝 خلاصه تنظیمات:\n";
        echo "----------------------------------------\n";
        echo "دیتابیس:\n";
        echo "  هاست: {$this->config['db_host']}\n";
        echo "  نام: {$this->config['db_name']}\n";
        echo "  کاربر: {$this->config['db_user']}\n";
        echo "  رمز عبور: " . str_repeat('*', strlen($this->config['db_pass'])) . "\n\n";
        echo "تلگرام:\n";
        echo "  توکن بات: {$this->config['bot_token']}\n";
        echo "  شناسه مدیر: {$this->config['admin_id']}\n\n";
        echo "دامنه و SSL:\n";
        echo "  دامنه: {$this->config['domain']}\n";
        echo "  SSL: " . ($this->config['ssl_enabled'] === 'true' ? 'فعال' : 'غیرفعال') . "\n";
        echo "----------------------------------------\n\n";

        // تایید نهایی
        $confirm = $this->ask("آیا تنظیمات وارد شده صحیح است؟ (بله/خیر): ");
        if (strtolower($confirm) !== 'بله') {
            die("نصب متوقف شد.\n");
        }
    }

    /**
     * دریافت ورودی از کاربر
     */
    private function ask($question, $default = '')
    {
        echo $question;
        $answer = trim(fgets(STDIN));
        return $answer ?: $default;
    }

    /**
     * بررسی پیش‌نیازهای سیستم
     */
    private function checkRequirements()
    {
        $requirements = [
            'PHP Version (>= 7.4)' => version_compare(PHP_VERSION, '7.4.0', '>='),
            'PDO Extension' => extension_loaded('pdo'),
            'PDO MySQL Extension' => extension_loaded('pdo_mysql'),
            'CURL Extension' => extension_loaded('curl'),
            'JSON Extension' => extension_loaded('json'),
            'OpenSSL Extension' => extension_loaded('openssl')
        ];

        foreach ($requirements as $requirement => $met) {
            if (!$met) {
                $this->errors[] = $requirement . ' نصب نشده است';
            }
        }

        if (!empty($this->errors)) {
            die("❌ پیش‌نیازهای سیستم نصب نشده‌اند:\n" . implode("\n", $this->errors) . "\n");
        }
    }

    /**
     * نصب سیستم
     */
    public function install()
    {
        try {
            echo "\n🚀 شروع نصب...\n\n";

            // 1. ایجاد دیتابیس
            $this->createDatabase();

            // 2. ایجاد جداول
            $this->createTables();

            // 3. تنظیم SSL
            if ($this->config['ssl_enabled'] === 'true') {
                $this->setupSSL();
            }

            // 4. تنظیم وب‌هوک
            $this->setupWebhook();

            // 5. تنظیم فایل‌های پیکربندی
            $this->setupConfigFiles();

            echo "\n✨ نصب با موفقیت انجام شد!\n\n";
            echo "🔗 آدرس وب‌هوک: https://{$this->config['domain']}/telegram/webhook.php\n";
            echo "🔑 توکن بات: {$this->config['bot_token']}\n";
            echo "👤 شناسه مدیر: {$this->config['admin_id']}\n\n";
            echo "💡 برای شروع کار، لطفاً به ربات تلگرام پیام دهید.\n";

        } catch (Exception $e) {
            die("\n❌ خطا در نصب: " . $e->getMessage() . "\n");
        }
    }

    /**
     * ایجاد دیتابیس
     */
    private function createDatabase()
    {
        try {
            $pdo = new PDO(
                "mysql:host={$this->config['db_host']}",
                $this->config['db_user'],
                $this->config['db_pass']
            );
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $pdo->exec("CREATE DATABASE IF NOT EXISTS {$this->config['db_name']} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
            echo "✅ دیتابیس با موفقیت ایجاد شد\n";
        } catch (PDOException $e) {
            throw new Exception("خطا در ایجاد دیتابیس: " . $e->getMessage());
        }
    }

    /**
     * ایجاد جداول
     */
    private function createTables()
    {
        try {
            $pdo = new PDO(
                "mysql:host={$this->config['db_host']};dbname={$this->config['db_name']}",
                $this->config['db_user'],
                $this->config['db_pass']
            );
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            // اجرای فایل‌های SQL
            $sqlFiles = glob(__DIR__ . '/database/migrations/*.sql');
            foreach ($sqlFiles as $file) {
                $sql = file_get_contents($file);
                $pdo->exec($sql);
            }

            echo "✅ جداول با موفقیت ایجاد شدند\n";
        } catch (PDOException $e) {
            throw new Exception("خطا در ایجاد جداول: " . $e->getMessage());
        }
    }

    /**
     * تنظیم SSL
     */
    private function setupSSL()
    {
        try {
            $domain = $this->config['domain'];
            $email = 'admin@' . $domain;

            echo "📝 نصب Certbot...\n";
            exec('apt-get update && apt-get install -y certbot python3-certbot-nginx');

            echo "📝 دریافت گواهینامه SSL...\n";
            exec("certbot --nginx -d {$domain} --non-interactive --agree-tos --email {$email}");

            echo "✅ گواهینامه SSL با موفقیت نصب شد\n";
        } catch (Exception $e) {
            throw new Exception("خطا در تنظیم SSL: " . $e->getMessage());
        }
    }

    /**
     * تنظیم وب‌هوک
     */
    private function setupWebhook()
    {
        try {
            $this->telegram = new TelegramBot();
            $webhookUrl = "https://{$this->config['domain']}/telegram/webhook.php";
            
            echo "📝 تنظیم وب‌هوک تلگرام...\n";
            $result = $this->telegram->setWebhook($webhookUrl);
            
            if (!$result['ok']) {
                throw new Exception("خطا در تنظیم وب‌هوک: " . ($result['description'] ?? 'خطای نامشخص'));
            }

            echo "✅ وب‌هوک با موفقیت تنظیم شد\n";
        } catch (Exception $e) {
            throw new Exception("خطا در تنظیم وب‌هوک: " . $e->getMessage());
        }
    }

    /**
     * تنظیم فایل‌های پیکربندی
     */
    private function setupConfigFiles()
    {
        try {
            echo "📝 ایجاد فایل‌های پیکربندی...\n";

            // ایجاد فایل .env
            $envContent = "DB_HOST={$this->config['db_host']}\n";
            $envContent .= "DB_NAME={$this->config['db_name']}\n";
            $envContent .= "DB_USER={$this->config['db_user']}\n";
            $envContent .= "DB_PASS={$this->config['db_pass']}\n";
            $envContent .= "TELEGRAM_BOT_TOKEN={$this->config['bot_token']}\n";
            $envContent .= "ADMIN_CHAT_ID={$this->config['admin_id']}\n";
            $envContent .= "DOMAIN={$this->config['domain']}\n";
            $envContent .= "SSL_ENABLED={$this->config['ssl_enabled']}\n";
            $envContent .= "JWT_SECRET={$this->config['jwt_secret']}\n";

            file_put_contents('.env', $envContent);

            // تنظیم دسترسی‌های فایل
            chmod('.env', 0600);
            chmod('public/telegram/webhook.php', 0755);

            echo "✅ فایل‌های پیکربندی با موفقیت ایجاد شدند\n";
        } catch (Exception $e) {
            throw new Exception("خطا در تنظیم فایل‌های پیکربندی: " . $e->getMessage());
        }
    }
}

// اجرای نصب
if (php_sapi_name() === 'cli') {
    $installer = new Installer();
    $installer->install();
} else {
    die("این اسکریپت فقط از طریق خط فرمان قابل اجراست.");
} 