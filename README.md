# 🌍 Project 02 — Global Serverless Platform (Multi-Region, Active-Active)

This project demonstrates the design and implementation of a **globally distributed, serverless backend on AWS**, built with **Terraform** and following **production-grade cloud engineering practices**.

The platform is **multi-region (active-active)**, highly available, cost-aware, and designed for **zero-downtime regional resilience** using DNS-based traffic steering.

---

## 🎯 Project Goals

- Build a **multi-region serverless backend** using AWS native services
- Demonstrate **active-active architecture** across regions
- Implement infrastructure as code with **Terraform**
- Apply **cost controls and safe defaults**
- Produce clear documentation and deployment proof suitable for a professional portfolio

---

## 🌐 Region Strategy

| Role       | AWS Region |
|-----------|------------|
| Primary   | eu-west-1 (Europe – Ireland) |
| Secondary | eu-central-1 (Europe – Frankfurt) |

**Why this pairing:**
- Low latency for EU users
- Strong regional separation
- Common real-world production pairing in Europe
- Full service parity for serverless workloads

---

## 🏗️ Architecture (Current State)

### 1️⃣ Infrastructure Foundation

- Terraform multi-provider setup
- Explicit primary/secondary provider aliasing
- Environment-scoped configuration (`environments/dev`)
- Centralized naming and tagging strategy
- Feature flags for optional services (CloudFront, WAF, Route 53 health checks)
- Safe defaults to reduce accidental cost/blast radius

---

### 2️⃣ Global Data Layer — DynamoDB Global Tables

- DynamoDB Global Table spanning:
  - eu-west-1
  - eu-central-1
- `PAY_PER_REQUEST` billing (no capacity planning)
- TTL enabled for automatic cleanup of test data
- DynamoDB Streams enabled (required for global replication)

**Result:** Writes in one region automatically replicate to the other.

📸 Screenshots: `screenshots/dynamodb/`

---

### 3️⃣ Compute Layer — AWS Lambda (Multi-Region)

- Identical Lambda functions deployed in both regions
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

- HTTP API Gateway deployed independently in both regions
- Regional APIs integrated with regional Lambdas
- Identical routes in each region:
  - `GET /health`
  - `POST /write`
- Throttling + safe defaults enabled
- Regions are decoupled (no cross-region dependency)

📸 Screenshots: `screenshots/api-gateway/`

---

### 5️⃣ Global Traffic Management — Route 53 (Latency-Based Routing)

- Public hosted zone for real domain: **hawser-labs.online**
- Subdomain: **api.hawser-labs.online**
- Active-active latency routing:
  - `A` records (IPv4) for Ireland + Frankfurt
  - `AAAA` records (IPv6) for Ireland + Frankfurt
- Alias records point to regional API Gateway custom domains
- Clients are routed to the lowest-latency region automatically
- Health-check routing is available but feature-flagged

📸 Screenshots: `screenshots/route53/`

---

## 🔐 Security & Cost Controls

- No static credentials committed
- IAM least-privilege policies
- No EC2, NAT Gateways, or always-on infrastructure
- Short log retention across services
- Feature-flagged edge services (CloudFront, WAF)
- Clean, reproducible Terraform state

---

## 📁 Repository Structure

```text
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
│   └── route53/
└── README.md

---

## 📌 Key Engineering Takeaways

- Designed for failure by default (no single-region dependency)
- True active-active architecture with independent regional stacks
- DNS-based traffic steering via Route 53 latency routing
- Global replication handled by DynamoDB Global Tables (not custom code)
- Cost-aware defaults: no NAT/EC2, short log retention, feature flags
- Incremental rollout with low blast radius (enable features in phases)
- Terraform configuration structured for maintainability and reuse (modules + envs)

---

## 🧹 Cleanup

All infrastructure can be removed safely with:
```text
terraform destroy

This project avoids hidden dependencies and is designed to teardown cleanly.

---

## 📎 Notes

This repository is part of a cloud engineering portfolio and intentionally prioritizes:
- clarity over complexity
- correctness over shortcuts
- realism over “toy” examples
- Design decisions reflect real-world AWS tradeoffs rather than tutorial-style shortcuts.
