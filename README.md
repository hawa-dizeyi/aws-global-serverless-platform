# 🌍 Project 02 — Global Serverless Platform (Multi-Region, Active-Active)

This project demonstrates the design and implementation of a **globally distributed, serverless platform on AWS**, built with **Terraform** and following **production-grade cloud engineering practices**.

The architecture is **multi-region (active-active)**, highly available, cost-aware, and designed for **zero-downtime regional failover**.

---

## 🎯 Project Goals

- Build a **multi-region serverless backend** using AWS native services
- Demonstrate **active-active architecture** across regions
- Implement **infrastructure as code** with Terraform
- Apply **cost controls and safe defaults**
- Produce **clear documentation and deployment proof** suitable for a professional portfolio

---

## 🌐 Region Strategy

| Role | AWS Region |
|------|-----------|
| Primary | eu-west-1 (Europe – Ireland) |
| Secondary | eu-central-1 (Europe – Frankfurt) |

**Why this choice:**
- Low latency for EU users
- Strong regional separation
- Common real-world production pairing in Europe
- Full service parity for serverless workloads

---

## 🏗️ Architecture (Current State)

### Implemented Components

### 1️⃣ Infrastructure Foundation
- Terraform multi-provider setup
- Explicit primary / secondary region aliasing
- Environment-scoped configuration (environments/dev)
- Centralized naming and tagging strategy
- Feature flags for optional services (CloudFront, WAF, health checks)

---

### 2️⃣ Global Data Layer — DynamoDB Global Tables
- DynamoDB Global Table spanning:
  - eu-west-1
  - eu-central-1
- PAY_PER_REQUEST billing (no capacity planning)
- TTL enabled for automatic cleanup of test data
- DynamoDB Streams enabled (required for global replication)

**Result:**  
Data written in one region is automatically replicated to the other region.

Screenshots location:
  screenshots/dynamodb/

---

### 3️⃣ Compute Layer — AWS Lambda (Multi-Region)
- Identical Lambda functions deployed in both regions
- Runtime: Python 3.12
- ZIP-based deployment using Terraform
- Shared execution role with least-privilege DynamoDB access
- Short CloudWatch log retention (cost-controlled)
- No reserved concurrency (avoids account-level constraints)

**Lambda capabilities:**
- /health — regional health endpoint
- /write — writes data to DynamoDB (replicated globally)

Screenshots location:
  screenshots/lambda/

---

## 🔐 Security & Cost Controls

- No static credentials committed
- IAM least-privilege policies
- No NAT gateways, EC2, or always-on services
- Short log retention
- Feature-flagged edge services to avoid accidental cost
- Terraform state kept clean and reproducible

---

## 📁 Repository Structure

.
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
│
├── modules/
│   ├── providers/
│   ├── dynamodb/
│   └── lambda/
│
├── src/
│   └── lambda/
│       └── app.py
│
├── screenshots/
│   ├── dynamodb/
│   └── lambda/
│
└── README.md

---

## 🚧 Planned Work (Roadmap)

### 4️⃣ API Layer — API Gateway (Active-Active)
- HTTP API Gateway in both regions
- Regional endpoints mapped to regional Lambdas
- Routes:
  - GET /health
  - POST /write
- Throttling and safe defaults enabled

---

### 5️⃣ Global Traffic Management — Route 53
- Latency-based routing
- Active-active DNS records
- Optional health-check routing (feature-flagged)
- Demonstrated regional failover

---

### 6️⃣ Event-Driven Architecture
- Amazon EventBridge
- Event producers and consumers
- Loose coupling between components
- Foundation for async workflows

---

### 7️⃣ Edge & Security Layer (Optional)
- Amazon CloudFront
- AWS WAF
- Minimal rule set
- Enabled only for demo and documentation

---

## 📌 Key Engineering Takeaways
- Designed for failure by default
- Infrastructure built incrementally and safely
- Real-world AWS constraints handled explicitly
- Terraform used as a first-class engineering tool
- Documentation treated as part of the deliverable

---

## 🧹 Cleanup

All infrastructure can be removed safely using:
  terraform destroy

---

## 📎 Notes

This project is part of a cloud engineering portfolio and intentionally favors:
- clarity over complexity
- correctness over shortcuts
- realism over “toy” examples
