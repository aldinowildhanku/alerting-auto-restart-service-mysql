# Auto Restart Database Service (cPanel) + Discord Webhook

A lightweight script to monitor and automatically restart **MySQL/MariaDB** services on **cPanel servers**.  
When the database service is down, it will restart the service and send an alert to **Discord via webhook**.

---

## Features
- Auto restart MySQL / MariaDB
- Discord webhook notifications
- Cron-based execution
- Lightweight & cPanel compatible

---

## Requirements
- cPanel server (root / sudo access)
- MySQL or MariaDB
- curl
- Discord webhook URL

---

## Installation
```bash
git clone https://github.com/yourusername/auto-restart-db-cpanel.git
cd auto-restart-db-cpanel
chmod +x monitor-db.sh
