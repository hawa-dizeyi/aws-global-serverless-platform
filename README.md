# 🌍 Project 02 — Global Serverless Platform (Multi-Region, Active-Active)

This project demonstrates the design and implementation of a **globally distributed, serverless backend on AWS**, built with **Terraform** and following **production-grade cloud engineering practices**.

The platform is **multi-region (active-active)**, highly available, cost-aware, and designed for **zero-downtime regional resilience** using DNS-based traffic steering and health-check–driven failover.

---

## 🎯 Project Goals

- Build a **multi-region serverless backend** using AWS native services
- Demonstrate **true active-active architecture** across regions
- Implement infrastructure as code with **Terraform**
- Apply **cost controls and safe defaults**
- Produce **verifiable deployment proof** suitable for a senior-level portfolio

---

## 🌐 Region Strategy

| Role       | AWS Region |
|-----------|------------|
| Primary   | eu-west-1 (Europe – Ireland) |
| Secondary | eu-central-1 (Europe – Frankfurt) |

**Why this pairing:**
- Low latency for EU users
- Strong regional separation
- Common real-world production pairing
- Full service parity for serverless workloads

---

## 🏗️ Architecture (Current State)

### 1️⃣ Infrastructure Foundation

- Terraform multi-provider setup
- Explicit primary / secondary provider aliasing
- Environment-scoped configuration (`environments/dev`)
- Centralized naming and tagging strategy
- Feature flags for optional services (CloudFront, WAF, Route 53 health checks)
- Safe defaults to reduce accidental cost or blast radius

---

### 2️⃣ Global Data Layer — DynamoDB Global Tables

- DynamoDB Global Table spanning:
  - eu-west-1
  - eu-central-1
- `PAY_PER_REQUEST` billing (no capacity planning)
- TTL enabled for automatic cleanup of test data
- DynamoDB Streams enabled for global replication

**Result:**  
Writes in one region automatically replicate to the other without custom code.

📸 Screenshots: `screenshots/dynamodb/`

---

### 3️⃣ Compute Layer — AWS Lambda (Multi-Region)

- Identical Lambda functions deployed independently in both regions
- Runtime: **Python 3.12**
- ZIP-based deployment using Terraform (`archive_file`)
- Shared execution role with **least-privilege** DynamoDB access
- Short CloudWatch log retention (cost-controlled)
- No reserved concurrency (avoids account-level constraints)

**Endpoints:**
- `GET /health` — regional health response
- `POST /write` — writes to DynamoDB (replicated globally)

📸 Screenshots: `screenshots/lambda/`

---

### 4️⃣ API Layer — API Gateway (Active-Active)

- HTTP API Gateway deployed independently per region
- Regional APIs integrated with regional Lambdas
- Identical routes in each region
- Throttling and safe defaults enabled
- No cross-region dependencies

📸 Screenshots: `screenshots/api-gateway/`

---

### 5️⃣ Global Traffic Management — Route 53 (Failover + Health Checks)

- Public hosted zone: **hawser-labs.online**
- API subdomain: **api.hawser-labs.online**
- **Failover routing policy** (PRIMARY / SECONDARY)
- HTTPS health checks against `/health` per region
- Automatic removal of unhealthy region from DNS
- IPv4 (`A`) and IPv6 (`AAAA`) records

📸 Screenshots: `screenshots/route53/`

---

## 🔁 Regional Isolation & Active-Active Replication (Proof)

This section provides **explicit, reproducible proof** of active-active behavior and regional isolation.

### ✅ Independent Regional Health

Each region responds independently:

- eu-west-1 reports `region: eu-west-1`
- eu-central-1 reports `region: eu-central-1`

📸 Evidence:
- `screenshots/dynamodb/regional-health-eu.png`
- `screenshots/dynamodb/regional-health-de.png`

---

### ✅ Cross-Region Data Replication

1. Write executed in **Ireland**
2. Item read from **Frankfurt**
3. Write executed in **Frankfurt**
4. Item read from **Ireland**

Replication is handled entirely by DynamoDB Global Tables.

📸 Evidence:
- `screenshots/dynamodb/write-eu-output.png`
- `screenshots/dynamodb/get-from-de-eu-item.png`
- `screenshots/dynamodb/write-de-output.png`
- `screenshots/dynamodb/get-from-eu-de-item.png`

---

### ✅ Automated Failover (Controlled Failure)

- Health check intentionally failed for PRIMARY (eu-west-1)
- Route 53 marked PRIMARY as unhealthy
- DNS automatically routed traffic to SECONDARY (eu-central-1)
- No client-side changes required

📸 Evidence:
- `screenshots/route53/failover-routing.png`
- `screenshots/route53/primary-unhealthy.png`

---

### ✅ Frontend Validation (CORS + Visibility)

A minimal public UI is hosted on **Vercel** (`ui.hawser-labs.online`) to:

- Justify **strict CORS** configuration
- Visualize routing decisions
- Display:
  - Region badge
  - Request latency
  - Failover detection banner
  - Animated response cards

📸 Evidence:
- `screenshots/frontend/frontend-global-health.png`
- `screenshots/frontend/frontend-latency.png`
- `screenshots/frontend/frontend-failover-banner.png`

---

## 🔐 Security & Cost Controls

- No static credentials committed
- IAM least-privilege policies
- No EC2, NAT Gateways, or always-on infrastructure
- Short log retention across services
- Strict CORS (no wildcard origins)
- Feature-flagged edge services (CloudFront, WAF)
- Clean, reproducible Terraform state

---

## 📁 Repository Structure

~~~text
.
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── modules/
│   ├── providers/
│   ├── dynamodb/
│   ├── lambda/
│   └── api/
├── src/
│   └── lambda/
│       └── app.py
├── screenshots/
│   ├── dynamodb/
│   ├── lambda/
│   ├── api-gateway/
│   ├── route53/
│   └── frontend/
└── README.md
~~~

---

## 📌 Key Engineering Takeaways

- Designed for failure by default (no single-region dependency)
- True active-active architecture with independent regional stacks
- Health-check driven DNS failover using Route 53
- Global replication handled by DynamoDB Global Tables (not custom code)
- Cost-aware defaults: no NAT/EC2, short log retention, feature flags
- Incremental rollout with low blast radius (enable features in phases)
- Terraform configuration structured for maintainability and reuse (modules + envs)

---

## 🧹 Cleanup

All infrastructure can be removed safely with:

~~~text
terraform destroy
~~~

This project avoids hidden dependencies and is designed to teardown cleanly.

---

## 📎 Notes

This repository is part of a cloud engineering portfolio and intentionally prioritizes:
- clarity over complexity
- correctness over shortcuts
- realism over “toy” examples

Design decisions reflect real-world AWS tradeoffs rather than tutorial-style shortcuts.
