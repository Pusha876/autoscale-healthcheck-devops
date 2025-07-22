# AutoScale HealthCheck – Infrastructure & App Recovery Platform

![Project Banner](docs/architecture-diagram.png)

## 🌍 Real-World Problem

Unexpected outages and performance degradation often go unnoticed until users are impacted. Manual recovery wastes time and increases downtime.

## 🎯 Solution

An automated healthcheck and self-healing platform deployed on Azure using:

- ✅ Containerized Python API.
- ✅ Azure Container Instances (ACI).
- ✅ Azure Monitor + Log Analytics for alerts.
- ✅ Terraform for Infrastructure as Code.
- ✅ Azure DevOps CI Pipeline.
- ✅ Auto-healing via Azure Function or Runbook.

---

## 🧱 Architecture

![Architecture Diagram](docs/architecture-diagram.png)

---

## ⚙️ Technologies Used

| Category           | Tool |
|-------------------|------|
| IaC               | Terraform |
| CI/CD             | Azure DevOps |
| Runtime           | Azure Container Instances |
| Monitoring        | Azure Monitor, Log Analytics |
| Recovery          | Azure Function / Automation Runbook |
| App Language      | Python (Flask) |
| Containerization  | Docker |

---

## 🚀 How it Works

1. Developer pushes code ➡ CI pipeline runs tests and builds Docker image
2. Image is deployed to Azure Container Instances
3. Azure Monitor tracks logs and metrics
4. Alerts are triggered via KQL
5. Azure Function or Runbook restarts the container automatically

---

## 📦 Repository Structure

```bash
├── src/healthcheck-api/      # Python Flask app
├── infrastructure/           # Terraform files
├── scripts/                  # Recovery scripts (PowerShell/Azure CLI)
├── monitor/                  # KQL and alert config
├── .azure-pipelines/         # CI pipeline YAML
├── docs/                     # Architecture, demo script, etc.
