# 🌍 Project 02 — Global Serverless Platform (Multi-Region, Active-Active)

This project demonstrates the design and implementation of a **globally distributed, serverless backend on AWS**, built with **Terraform** and aligned with **Staff / Principal Cloud Engineer–level practices**.

The platform is **multi-region (active-active)**, highly available, cost-aware, and designed for **regional isolation, fast recovery, and operational clarity**, using DNS-based traffic steering and health-check–driven failover.

---

## 🎯 Project Goals

- Design a **true active-active serverless backend** across AWS regions
- Demonstrate **failure-aware architecture**, not just high availability
- Implement **clean, modular Infrastructure as Code** with Terraform
- Apply **security, cost, and operational guardrails by default**
- Produce **verifiable, reproducible proof** suitable for senior-level interviews

---

## 🧭 Scope & Non-Goals (Intentional)

**In scope**
- Backend platform design
- Regional isolation & failover
- Data replication guarantees
- Observability and operational signals
- Security controls appropriate for a public API

**Explicitly out of scope**
- Authentication / authorization (Cognito, OAuth)
- CI/CD pipelines (intentionally skipped after validation)
- Business logic complexity
- Long-lived data modeling
- Frontend product development

> This project focuses on **platform correctness and resilience**, not feature completeness.

---

## 🌐 Region Strategy

| Role       | AWS Region |
|-----------|------------|
| Primary   | eu-west-1 (Europe – Ireland) |
| Secondary | eu-central-1 (Europe – Frankfurt) |

**Why this pairing**
- Low latency for EU traffic
- Strong geographic separation
- Common production pairing
- Full parity for serverless services

---

## 🏗️ Architecture Overview

### High-Level Components

- **Route 53** — DNS failover & health checks
- **API Gateway (HTTP API)** — regional ingress
- **AWS Lambda** — stateless compute per region
- **DynamoDB Global Tables** — active-active data layer
- **CloudWatch** — metrics, alarms, logs
- **Terraform** — single source of truth

---

## 🔄 End-to-End Request Flow

1. Client resolves `api.hawser-labs.online`
2. Route 53 evaluates regional health checks
3. DNS routes traffic to **PRIMARY** or **SECONDARY**
4. API Gateway receives request in selected region
5. Regional Lambda executes business logic
6. Write persists to DynamoDB Global Table
7. DynamoDB replicates change cross-region automatically

No synchronous cross-region calls.  
No shared regional dependencies.

---

## 🧱 Infrastructure Foundation

- Terraform multi-provider configuration
- Explicit primary / secondary provider aliasing
- Environment isolation (`environments/dev`)
- Centralized naming + tagging
- Feature flags for optional services (CloudFront, WAF, health checks)
- Safe defaults to minimize blast radius and cost

---

## 🗄️ Global Data Layer — DynamoDB Global Tables

- Single DynamoDB table replicated across:
  - eu-west-1
  - eu-central-1
- `PAY_PER_REQUEST` billing (no capacity tuning)
- TTL enabled for automatic data expiry
- Streams enabled (required for replication)

**Outcome:**  
Writes in either region propagate automatically without custom replication logic.

📸 Proof: `screenshots/dynamodb/`

---

## ⚙️ Compute Layer — AWS Lambda (Multi-Region)

- Identical Lambda deployed independently per region
- Runtime: **Python 3.12**
- ZIP-based deployment via Terraform
- Shared execution role with **least-privilege IAM**
- Short log retention (cost-controlled)
- Stateless, idempotent handlers

**Endpoints**
- `GET /health`
- `POST /write`

📸 Proof: `screenshots/lambda/`

---

## 🌐 API Layer — API Gateway (Active-Active)

- HTTP APIs deployed per region
- Each API integrates only with its local Lambda
- Throttling and burst limits enabled
- No cross-region coupling
- Explicit method enforcement (POST-only writes)

📸 Proof: `screenshots/api-gateway/`

---

## 🌍 Global Traffic Management — Route 53 (Failover)

- Public hosted zone: **hawser-labs.online**
- API entrypoint: **api.hawser-labs.online**
- **Failover routing policy**
  - PRIMARY: eu-west-1
  - SECONDARY: eu-central-1
- HTTPS health checks on `/health`
- IPv4 (`A`) and IPv6 (`AAAA`) records
- Automatic DNS failover on health degradation

📸 Proof: `screenshots/route53/`

---

## 🔁 Regional Isolation & Active-Active Replication (Proof)

### Independent Regional Health

Each region responds independently:

- eu-west-1 → `region: eu-west-1`
- eu-central-1 → `region: eu-central-1`

📸 Evidence:
- `screenshots/dynamodb/regional-health-eu.png`
- `screenshots/dynamodb/regional-health-de.png`

---

### Cross-Region Data Replication

1. Write in Ireland
2. Read in Frankfurt
3. Write in Frankfurt
4. Read in Ireland

Replication is native to DynamoDB Global Tables.

📸 Evidence:
- `screenshots/dynamodb/write-eu-output.png`
- `screenshots/dynamodb/get-from-de-eu-item.png`
- `screenshots/dynamodb/write-de-output.png`
- `screenshots/dynamodb/get-from-eu-de-item.png`

---

### Controlled Failover Test

- PRIMARY health check intentionally failed
- Route 53 marked PRIMARY unhealthy
- Traffic automatically routed to SECONDARY
- No client-side changes required

📸 Evidence:
- `screenshots/route53/primary-unhealthy.png`
- `screenshots/route53/failover-routing.png`

---

## 🧪 Frontend as an Engineering Instrument

A minimal UI is hosted on **Vercel** (`ui.hawser-labs.online`) to:

- Justify strict CORS configuration
- Visualize routing behavior
- Display region badges
- Measure request latency
- Detect failover events
- Animate responses for clarity

This UI is a **diagnostic surface**, not a product frontend.

📸 Evidence:
- `screenshots/frontend/`

---

## 🔐 Security & Cost Controls

- No static AWS credentials
- IAM least-privilege enforcement
- Strict CORS (no wildcard origins)
- Payload size limits (abuse protection)
- Method enforcement (POST-only writes)
- Security headers on all responses
- No EC2, NAT Gateways, or idle resources
- Feature-flagged edge services

---

## 📈 Observability

### SLIs Tracked Per Region

- API Gateway 5XX (service faults)
- API Gateway 4XX (client misuse signals)
- API Gateway latency
- Lambda errors

### SLO Targets (Demo)

- Availability: **99.9%**
- Sustained 5XX: **0**
- 4XX alert threshold: **>20/min**
- Average latency: **<1500ms**

### Tooling

- CloudWatch alarms per region
- Side-by-side regional dashboards
- Logs Insights queries for:
  - Error analysis
  - Slow request identification

📸 Proof: `screenshots/observability/`

---

## ⚖️ Tradeoffs & Alternatives Considered

- **Route 53 vs Global Accelerator**  
  → Route 53 chosen for simplicity, transparency, and cost

- **DynamoDB Global Tables vs custom replication**  
  → Native replication preferred over operational complexity

- **API Gateway vs ALB**  
  → API Gateway fits serverless scaling and cost model

- **CloudFront in front of API**  
  → Intentionally omitted; not required for latency or availability here

---

## 🧨 Failure Modes & Blast Radius

| Failure | Impact | Recovery |
|------|------|--------|
| Regional Lambda failure | Traffic shifts | Automatic |
| API Gateway outage | Region isolated | Automatic |
| DynamoDB regional issue | Writes rerouted | Automatic |
| DNS / health check misconfig | Global impact | Manual |
| Code bug | Logical failure | Redeploy |

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
│   ├── observability/
│   └── security/
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

This project is part of a **Staff / Principal Cloud Engineering portfolio** and intentionally prioritizes:

- architectural clarity
- operational realism
- explicit tradeoff documentation
- reproducibility over polish

Design decisions reflect real-world AWS tradeoffs rather than tutorial-style shortcuts.
