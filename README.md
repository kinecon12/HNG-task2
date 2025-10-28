# 🚀 Blue/Green Deployment with Nginx & Docker Compose

This repository demonstrates a **Blue/Green Node.js service deployment** behind **Nginx**, using pre-built container images and health-based automatic failover — all without rebuilding or modifying the application images.

---

## 🧩 Overview

### Architecture

Client → Nginx (port 8080)
├── Blue App (active, port 8081)
└── Green App (backup, port 8082)


### Behavior

- ✅ Normal state: all traffic served by **Blue**
- ⚠️ On Blue failure (5xx or timeout): **Nginx retries to Green automatically**
- 🔁 Blue is primary; Green is backup
- 🧠 Health checks & retries ensure **zero failed client requests**
- 🪶 Nginx forwards all app headers unchanged

---

## 🧱 Exposed Endpoints

| Path | Description |
|------|--------------|
| `GET /version` | Returns JSON + headers: `X-App-Pool`, `X-Release-Id` |
| `GET /healthz` | Returns 200 if app is healthy |
| `POST /chaos/start` | Simulates downtime (500s or timeout) |
| `POST /chaos/stop` | Ends simulated downtime |

---

## ⚙️ Environment Configuration

All runtime configuration is handled via a `.env` file:

```bash
# .env
BLUE_IMAGE=example/blue-service:latest
GREEN_IMAGE=example/green-service:latest

ACTIVE_POOL=blue           # blue or green
RELEASE_ID_BLUE=v1.0.0
RELEASE_ID_GREEN=v1.0.1

PORT=8080                  # optional public port

🐳 Docker Compose Setup
1️⃣ Clone the repo

git clone https://github.com/your-org/blue-green-nginx.git
cd blue-green-nginx

2️⃣ Create .env file

cp .env.example .env

Update with your image tags and release IDs.
3️⃣ Start all services

docker compose up -d

4️⃣ Verify baseline

curl -i http://localhost:8080/version

Expected response:

HTTP/1.1 200 OK
X-App-Pool: blue
X-Release-Id: v1.0.0

💥 Simulate Failover

Trigger downtime on Blue:

curl -X POST http://localhost:8081/chaos/start?mode=error

Then call again:

curl -i http://localhost:8080/version

Expected response:

HTTP/1.1 200 OK
X-App-Pool: green
X-Release-Id: v1.0.1

To recover Blue:

curl -X POST http://localhost:8081/chaos/stop

🧠 Nginx Configuration Details

    Uses backup directive for Green.

    Detects failures quickly with:

max_fails=1 fail_timeout=5s;
proxy_connect_timeout 1s;
proxy_read_timeout 1s;
proxy_next_upstream error timeout http_500 http_502 http_503 http_504;

Forwards headers transparently:

    proxy_pass_header X-App-Pool;
    proxy_pass_header X-Release-Id;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $remote_addr;

🧪 Verification Logic (for CI)
Test	Expected Result
Baseline	All /version requests → 200 from Blue
After Chaos	All /version requests → 200 from Green
Stability	0 failed requests after chaos, ≥95% served by Green
Header Integrity	X-App-Pool and X-Release-Id correct before/after switch
🔄 Restart or Reload Nginx

If you update .env or change ACTIVE_POOL:

docker compose exec nginx nginx -s reload

🧹 Tear Down

docker compose down

🧰 Directory Structure

blue-green-nginx/
├── docker-compose.yml
├── nginx.conf.template
├── .env.example
└── README.md
