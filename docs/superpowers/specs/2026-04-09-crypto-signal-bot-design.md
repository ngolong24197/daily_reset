# Crypto Signal Trading Bot — Design Spec

## Overview

A 24/7 bot that monitors Telegram signal groups via multiple accounts, parses trading signals using Ollama (cloud), and executes futures trades on Binance with progressive TP management. Deployed as a Docker container on a Raspberry Pi 4 (4GB).

## Architecture

```
┌──────────────────────────────────────────────────┐
│                 Docker Container                  │
│                                                   │
│  Telegram Client 1 (Account A) ──┐                │
│  Telegram Client 2 (Account B) ──┼──► Signal Pool │
│  Telegram Client N (Account N) ──┘    │           │
│                                       ▼           │
│                            Deduplication Engine    │
│                            (same pair+direction)  │
│                                       │           │
│                                       ▼           │
│                            Ollama Cloud Parser     │
│                            (extract trade params)  │
│                                       │           │
│                                       ▼           │
│                            Trade Executor           │
│                            (Binance Futures API)    │
│                                       │           │
│                                       ▼           │
│                            Notifier                 │
│                            (Telegram DM + Email)    │
│                                                   │
│  State Store (SQLite)                             │
│                                                   │
└──────────────────────────────────────────────────┘
```

Single async Python process. Ollama runs as a separate cloud service. Docker restart policy ensures automatic recovery.

## Components

### 1. Telegram Listener (`telegram_listener.py`)

- Uses **Telethon** as a userbot (not a bot API) for each account
- Each account monitors its configured group(s)
- Forwards all new messages to the signal parser pipeline
- Auto-reconnects on disconnect with exponential backoff
- Multiple Telethon client instances run concurrently via asyncio

### 2. Deduplication Engine (`dedup.py`)

- Before parsing, checks if a signal for the same **pair + direction** is already open
- Same pair + same direction = skip (duplicate)
- Same pair + opposite direction = allow (separate trade)
- Checks against the `positions` table (status = open or partial)
- Logs all duplicate detections for audit

### 3. Signal Parser (`signal_parser.py` + `ollama_client.py`)

- Sends raw signal text to Ollama cloud API
- Ollama returns structured JSON:
  ```json
  {
    "pair": "TRADOOR/USDT",
    "direction": "LONG",
    "leverage": 30,
    "tps": [4.650, 4.900, 5.500],
    "sl": 4.000,
    "dca_status": "pending",
    "dca_price": null,
    "margin_pct": 1
  }
  ```
- Handles varying signal formats from different groups
- If Ollama is unavailable, falls back to regex-based parsing
- Stores parsed signal in `signals` table

### 4. Trade Executor (`executor.py`)

- **Entry**: Market order immediately
- **Margin**: Uses the `margin_pct` value from config (default 2%), ignoring any margin % in the signal. The config value takes precedence.
- Sets leverage as specified in signal (recommended leverage)
- If signal has no SL or TP: still enter the trade, notify user to set manually
- Stores position in `positions` table

### 5. TP Manager (`tp_manager.py`)

- Monitors open positions against price ticks via Binance WebSocket
- Progressive close logic:
  - **TP1 hit**: close 50% of position, move SL to entry (breakeven)
  - **TP2 hit**: close 25% of remaining, move SL to TP1 price
  - **TP3 hit**: close 15% of remaining, activate trailing stop on last 10%
- **Trailing stop**: configurable callback rate (default 1.5%), activates after TP3
- SL modifications use Binance REST API (modify order, not cancel+recreate)

### 6. DCA Handler (`dca_handler.py`)

- When signal says "DCA: Update Later", position marked as `dca_pending`
- When a DCA update message arrives in the same group thread:
  - Ollama parses the DCA price
  - Adds to the existing position at market price
  - Adjusts entry price (weighted average)
- DCA entry uses same margin percentage as original trade

### 7. Notifier (`notifier.py`)

- **Telegram DM**: sends to your personal chat via bot API
- **Email**: sends via SMTP (async)
- Notifications sent for:
  - Trade opened
  - TP hit (which level, amount closed)
  - SL hit or trailing stop triggered
  - DCA entry placed
  - Signal missing SL/TP (entered anyway)
  - Errors (order failed, API issue)
  - Duplicate signal skipped

### 8. State Store (`db.py`)

SQLite with async wrapper (`aiosqlite`).

#### Tables:

**signals**
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| source_account | TEXT | Which Telegram account |
| source_group | TEXT | Which group |
| raw_text | TEXT | Original message |
| pair | TEXT | e.g., TRADOOR/USDT |
| direction | TEXT | LONG or SHORT |
| leverage | INTEGER | e.g., 30 |
| tps | TEXT | JSON array of TP prices |
| sl | REAL | Stop-loss price |
| dca_status | TEXT | none / pending / filled |
| dca_price | REAL | DCA entry price |
| parsed_at | DATETIME | When parsed |

**positions**
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| signal_id | INTEGER FK | Link to signal |
| pair | TEXT | Trading pair |
| direction | TEXT | LONG or SHORT |
| entry_price | REAL | Average entry price |
| quantity | REAL | Total quantity |
| remaining_pct | REAL | % of position still open |
| leverage | INTEGER | Leverage used |
| status | TEXT | open / partial / closed |
| tp1_hit | BOOLEAN | Whether TP1 triggered |
| tp2_hit | BOOLEAN | Whether TP2 triggered |
| tp3_hit | BOOLEAN | Whether TP3 triggered |
| trailing_active | BOOLEAN | Trailing stop active |
| current_sl | REAL | Current SL price |
| created_at | DATETIME | Position opened |
| closed_at | DATETIME | Position closed |

**dca_entries**
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| position_id | INTEGER FK | Link to position |
| price | REAL | DCA entry price |
| quantity | REAL | Added quantity |
| status | TEXT | pending / filled |
| created_at | DATETIME | When DCA placed |

**trade_log**
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| position_id | INTEGER FK | Link to position |
| action | TEXT | open / tp1 / tp2 / tp3 / sl / trail / dca |
| price | REAL | Execution price |
| quantity | REAL | Amount traded |
| pnl | REAL | Realized PnL for this action |
| timestamp | DATETIME | When executed |

## Configuration (`config.yaml`)

```yaml
telegram:
  accounts:
    - name: "Account1"
      api_id: "YOUR_API_ID"
      api_hash: "YOUR_API_HASH"
      phone: "+1234567890"
      groups: ["signal_group_1"]
    - name: "Account2"
      api_id: "YOUR_API_ID"
      api_hash: "YOUR_API_HASH"
      phone: "+0987654321"
      groups: ["signal_group_2"]

binance:
  api_key: "YOUR_API_KEY"
  api_secret: "YOUR_API_SECRET"
  margin_pct: 2  # % of wallet balance per trade

ollama:
  base_url: "https://your-ollama-cloud-endpoint"
  model: "qwen2:1.5b"
  api_key: ""  # optional, if your cloud requires auth

notifications:
  telegram:
    bot_token: "YOUR_BOT_TOKEN"
    chat_id: "YOUR_CHAT_ID"
  email:
    smtp_host: "smtp.gmail.com"
    smtp_port: 587
    from_addr: "bot@example.com"
    to_addr: "you@example.com"
    password: "APP_PASSWORD"

trailing_stop:
  callback_rate: 1.5  # % trailing distance after TP3

dedup:
  same_direction_only: true  # true = allow opposite direction on same pair
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Market order fails | Log error, notify user, skip signal |
| Partial TP close fails | Retry 3x with 5s delay, then alert user |
| SL modification fails | Retry 3x, then alert (old SL still active) |
| Telegram disconnects | Auto-reconnect with exponential backoff |
| Binance API rate limit | Retry with backoff |
| Ollama unavailable | Fall back to regex-based parsing |
| Signal missing SL or TP | Enter trade anyway, notify user to set manually |
| Duplicate signal (same pair+direction) | Skip, log as duplicate |
| DCA message with no pending position | Skip, notify user |
| Docker container crashes | `restart: always` policy |

## Tech Stack

- **Python 3.11** (slim Docker image, ARM64 for Pi)
- **Telethon** — Telegram userbot (multi-account)
- **python-binance** — Binance Futures API
- **aiosqlite** — async SQLite
- **aiosmtplib** — async email
- **PyYAML** — config parsing
- **Ollama cloud** — signal parsing via HTTP API
- **Docker + docker-compose** — deployment on Pi 4

## Project Structure

```
trading-bot/
├── docker-compose.yml
├── Dockerfile
├── config.yaml
├── requirements.txt
├── src/
│   ├── main.py
│   ├── telegram_listener.py
│   ├── signal_parser.py
│   ├── dedup.py
│   ├── executor.py
│   ├── tp_manager.py
│   ├── dca_handler.py
│   ├── notifier.py
│   ├── db.py
│   ├── models.py
│   └── ollama_client.py
├── prompts/
│   └── parse_signal.txt
└── tests/
    └── ...
```

## Deployment (Raspberry Pi 4)

1. Install Docker + docker-compose on Pi
2. Clone repo, edit `config.yaml` with credentials
3. `docker-compose up -d`
4. First run: Telethon will prompt for login codes per account (interactive once)
5. After auth, sessions are saved — subsequent runs are headless
6. Monitor via Telegram DM notifications and logs (`docker logs -f`)

## Signal Parsing Prompt (Ollama)

The prompt sent to Ollama will instruct it to extract structured JSON from signal text, handling the known format variations:

- Pair name (always USDT quote)
- Direction (Long/Short)
- Leverage (use recommended value)
- TP levels (array of prices)
- Stop-loss price
- DCA status and price if present
- Margin percentage if specified

The prompt will include 3-5 few-shot examples from the known signal format to ensure consistent extraction.