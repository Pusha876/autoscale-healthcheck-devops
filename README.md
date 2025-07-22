AutoScale HealthCheck – Infrastructure & App Recovery Platform
    ╔══════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                                                                          ║
    ║      ████╗  ██╗   ██╗████████╗ ██████╗ ███████╗ ██████╗ █████╗ ██╗     ███████╗       ║
    ║     ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔════╝██╔════╝██╔══██╗██║     ██╔════╝       ║
    ║     ███████║██║   ██║   ██║   ██║   ██║███████╗██║     ███████║██║     █████╗         ║
    ║     ██╔══██║██║   ██║   ██║   ██║   ██║╚════██║██║     ██╔══██║██║     ██╔══╝         ║
    ║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝███████║╚██████╗██║  ██║███████╗███████╗       ║
    ║     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝       ║
    ║                                                                                          ║
    ║     ██╗  ██╗███████╗ █████╗ ██╗  ████████╗██╗  ██╗ ██████╗██╗  ██╗███████╗ ██████╗██╗ ║
    ║     ██║  ██║██╔════╝██╔══██╗██║  ╚══██╔══╝██║  ██║██╔════╝██║  ██║██╔════╝██╔════╝██║ ║
    ║     ███████║█████╗  ███████║██║     ██║   ███████║██║     ███████║█████╗  ██║     ██║ ║
    ║     ██╔══██║██╔══╝  ██╔══██║██║     ██║   ██╔══██║██║     ██╔══██║██╔══╝  ██║     ██║ ║
    ║     ██║  ██║███████╗██║  ██║███████╗██║   ██║  ██║╚██████╗██║  ██║███████╗╚██████╗██║ ║
    ║     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝ ║
    ║                                                                                          ║
    ║                    🚀 Infrastructure & App Recovery Platform 🚀                         ║
    ║                                                                                          ║
    ║               🔄 Automated Monitoring • Self-Healing • Zero Downtime 🔄                 ║
    ╚══════════════════════════════════════════════════════════════════════════════════════════╝
Project Banner

🌍 Real-World Problem
Unexpected outages and performance degradation often go unnoticed until users are impacted. Manual recovery wastes time and increases downtime.

🎯 Solution
An automated healthcheck and self-healing platform deployed on Azure using:

✅ Containerized Python API.
✅ Azure Container Instances (ACI).
✅ Azure Monitor + Log Analytics for alerts.
✅ Terraform for Infrastructure as Code.
✅ Azure DevOps CI Pipeline.
✅ Auto-healing via Azure Function or Runbook.
🧱 Architecture
Visual Overview: Interactive Architecture Diagram

AutoScale HealthCheck - Architecture Diagram

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AZURE CLOUD ENVIRONMENT                           │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────┐    ┌─────────────────────┐    ┌──────────────────────┐ │
│  │   Azure DevOps      │    │ Azure Container     │    │  Azure Container     │ │
│  │   CI/CD Pipeline    │───▶│     Registry        │───▶│    Instances (ACI)   │ │
│  │                     │    │   (autoscalehc...   │    │  healthcheck-api     │ │
│  │ • Build & Test      │    │    ...ackacr)       │    │  (Flask App)         │ │
│  │ • Docker Build      │    │                     │    │                      │ │
│  │ • Image Push        │    │                     │    │  Port: 5000          │ │
│  └─────────────────────┘    └─────────────────────┘    │  Health: /health     │ │
│                                                         │  Errors: /error      │ │
│                                                         └──────────┬───────────┘ │
│                                                                    │             │
│                                                                    │ Logs &      │
│                                                                    │ Metrics     │
│                                                                    ▼             │
│  ┌─────────────────────┐    ┌─────────────────────┐    ┌──────────────────────┐ │
│  │ Azure Monitor       │    │  Log Analytics      │    │   Alert Rules        │ │
│  │                     │    │   Workspace         │    │                      │ │
│  │ • Diagnostic        │◀───│                     │───▶│ • Container Downtime │ │
│  │   Settings          │    │ • ContainerLog      │    │ • High Error Rate    │ │
│  │ • Metrics           │    │ • KQL Queries       │    │ • No Logs Received   │ │
│  │ • Alerts            │    │ • Log Retention     │    │ • Auto-Heal Trigger  │ │
│  └─────────────────────┘    └─────────────────────┘    └──────────┬───────────┘ │
│                                                                    │             │
│                                                                    │ Webhook     │
│                                                                    │ Trigger     │
│                                                                    ▼             │
│  ┌─────────────────────┐    ┌─────────────────────┐    ┌──────────────────────┐ │
│  │   Action Groups     │    │   Azure Function    │    │   Auto-Heal Logic   │ │
│  │                     │    │   App (Linux)       │    │                      │ │
│  │ • Email Alerts      │    │                     │    │ • HTTP Trigger       │ │
│  │ • Function Webhook  │◀───│ autoscale-heal-func │───▶│ • Timer Trigger      │ │
│  │ • Notification      │    │                     │    │ • Simple CLI Trigger │ │
│  │   Management        │    │ Python 3.11         │    │ • Health Verification│ │
│  └─────────────────────┘    └─────────────────────┘    └──────────┬───────────┘ │
│                                                                    │             │
│                                                                    │ Restart     │
│                                                                    │ Command     │
│                                                                    ▼             │
│  ┌─────────────────────┐    ┌─────────────────────┐    ┌──────────────────────┐ │
│  │  Managed Identity   │    │   RBAC Permissions  │    │   Container Restart  │ │
│  │                     │    │                     │    │                      │ │
│  │ • User-Assigned     │───▶│ • Contributor Role  │───▶│ • Graceful Restart   │ │
│  │ • Secure Auth       │    │ • Resource Group    │    │ • Health Verification│ │
│  │ • No Secrets        │    │   Scope             │    │ • Zero Downtime      │ │
│  └─────────────────────┘    └─────────────────────┘    └──────────────────────┘ │
│                                                                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                            INFRASTRUCTURE AS CODE                              │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                              TERRAFORM                                      │ │
│  │  • Resource Group  • Storage Account  • Function App  • Alert Rules        │ │
│  │  • Container Group • Log Analytics    • Action Groups • Role Assignments   │ │
│  │  • Managed Identity• Service Plan     • Diagnostic    • Monitoring         │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
🔄 Flow: Code Push → Build → Deploy → Monitor → Alert → Auto-Heal

Architecture Diagram

⚙️ Technologies Used
Category	Technology
Infrastructure	Terraform
CI/CD	Azure DevOps Pipelines
Container Runtime	Azure Container Instances (ACI)
Container Registry	Azure Container Registry (ACR)
Monitoring	Azure Monitor + Log Analytics
Auto-Healing	Azure Functions (Python 3.11)
Application	Python Flask API
Containerization	Docker
Authentication	Azure Managed Identity
Alerting	KQL Queries + Action Groups
Category	Tool
IaC	Terraform
CI/CD	Azure DevOps
Runtime	Azure Container Instances
Monitoring	Azure Monitor, Log Analytics
Recovery	Azure Function / Automation Runbook
App Language	Python (Flask)
Containerization	Docker
🚀 How it Works
📝 Developer Push → Code committed to repository triggers Azure DevOps pipeline
🔨 CI/CD Pipeline → Runs tests, builds Docker image, pushes to Azure Container Registry
🐳 Container Deployment → ACI pulls latest image and deploys Flask health check API
📊 Monitoring → Azure Monitor collects logs/metrics, sends to Log Analytics Workspace
🚨 Alert Detection → KQL queries detect errors, downtime, or performance issues
📧 Notifications → Action Groups send email alerts and trigger webhook to Azure Function
🔄 Auto-Healing → Azure Function evaluates alerts, performs health checks, restarts containers
🔒 Secure Operations → Managed Identity provides authentication without secrets
✅ Verification → Container restart verified, health confirmed, service restored
🔄 Auto-Heal Approaches
Alert-Based: Responds to Azure Monitor alerts via HTTP webhook
Timer-Based: Scheduled health checks every 5 minutes
Simple CLI: Backup approach using direct Azure CLI commands
Developer pushes code ➡ CI pipeline runs tests and builds Docker image
Image is deployed to Azure Container Instances
Azure Monitor tracks logs and metrics
Alerts are triggered via KQL
Azure Function or Runbook restarts the container automatically
📦 Repository Structure
autoscale-healthcheck-devops/
├── 📁 src/
│   ├── 📁 healthcheck-api/          # Python Flask application
│   │   ├── app.py                   # Main Flask app with health endpoints
│   │   ├── Dockerfile               # Container configuration
│   │   ├── requirements.txt         # Python dependencies
│   │   └── 📁 tests/                # Unit tests
│   │       └── test_app.py          # Flask app tests
│   └── README.md                    # Application documentation
│
├── 📁 infrastructure/               # Terraform Infrastructure as Code
│   ├── main.tf                      # Main infrastructure resources
│   ├── variables.tf                 # Input variables
│   ├── outputs.tf                   # Output values
│   ├── versions.tf                  # Provider versions
│   ├── terraform.tfvars             # Environment-specific values
│   └── README.md                    # Infrastructure documentation
│
├── 📁 auto-heal-function/           # Azure Function for auto-healing
│   ├── 📁 auto_heal_trigger/        # HTTP trigger function (alert-based)
│   │   ├── __init__.py              # Alert processing logic
│   │   └── function.json            # Function binding configuration
│   ├── 📁 timer_heal_trigger/       # Timer trigger function (scheduled)
│   │   ├── __init__.py              # Scheduled health check logic
│   │   └── function.json            # Timer binding configuration
│   ├── 📁 simple_heal_trigger/      # Simple CLI-based trigger
│   │   ├── __init__.py              # Simple restart logic
│   │   └── function.json            # Timer binding configuration
│   ├── host.json                    # Function app configuration
│   ├── requirements.txt             # Python dependencies
│   ├── README.md                    # Function documentation
│   └── DEPLOYMENT_GUIDE.md          # Deployment instructions
│
├── 📁 scripts/                      # Deployment and utility scripts
│   ├── deploy-auto-heal.sh          # Bash deployment script
│   ├── deploy-functions.ps1         # PowerShell deployment script
│   ├── test-auto-heal.sh           # Testing and verification script
│   ├── pre-deploy.sh               # Pre-deployment setup
│   └── import-existing.sh          # Import existing resources
│
├── 📁 monitor/                      # Monitoring and alerting
│   └── log-analytics.kql           # KQL queries for alerts and dashboards
│
├── 📁 .azure-pipelines/            # CI/CD pipeline definitions
│   ├── ci-pipeline.yml             # Basic CI pipeline
│   └── ci-pipeline-enhanced.yml    # Enhanced CI pipeline with testing
│
├── 📁 docs/                        # Documentation and visuals
│   ├── architecture-diagram.md     # ASCII architecture diagram
│   ├── architecture-visual.html    # Interactive visual diagram
│   └── project-banner.md          # ASCII project banner
│
├── AUTO_HEAL_SUMMARY.md           # Auto-heal implementation summary
├── AZURE_DEVOPS_SETUP.md          # Azure DevOps configuration guide
├── README.md                       # This file - project overview
├── LICENSE                         # Project license
└── .gitignore                      # Git ignore patterns
✨ Key Features
🔄 Automated Self-Healing
Multiple Trigger Types: HTTP webhooks, scheduled timers, and CLI-based approaches
Health Verification: Pre and post-restart health checks ensure successful recovery
Intelligent Alerting: KQL-based rules detect errors, downtime, and performance issues
Zero-Touch Recovery: Fully automated container restart without manual intervention
🔒 Security & Best Practices
Managed Identity: No hardcoded secrets or connection strings
Least Privilege: RBAC with minimal required permissions
Audit Trail: Comprehensive logging of all auto-heal actions
Secure Communication: HTTPS endpoints and encrypted connections
🏗️ Infrastructure as Code
Terraform: Complete infrastructure definition and versioning
Reproducible: Consistent deployments across environments
State Management: Remote state with locking and backup
Modular Design: Reusable components and configurations
📊 Comprehensive Monitoring
Real-time Alerts: Multiple alert rules for different failure scenarios
Custom Dashboards: KQL queries for deep insights and troubleshooting
Performance Metrics: Container resource usage and health trends
Historical Analysis: Log retention and trend analysis
🚀 Getting Started
Prerequisites
Azure subscription with necessary permissions
Azure CLI installed and configured
Terraform >= 1.0
Docker (for local development)
Git
Quick Start
Clone Repository

git clone <repository-url>
cd autoscale-healthcheck-devops
Configure Environment

# Copy and customize Terraform variables
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
# Edit variables for your environment
Deploy Infrastructure

cd infrastructure
terraform init
terraform plan
terraform apply
Deploy Application

# Build and push container image
cd ../src/healthcheck-api
docker build -t healthcheck-api .
# Push to Azure Container Registry (ACR)
Deploy Auto-Heal Functions

cd ../../auto-heal-function
# Use PowerShell script
../scripts/deploy-functions.ps1
# Or use Bash script
bash ../scripts/deploy-auto-heal.sh
Test and Verify

# Run comprehensive testing
bash scripts/test-auto-heal.sh
Manual Testing
# Test health endpoint
curl http://your-container-instance.azure.com:5000/health

# Generate test errors to trigger alerts
for i in {1..5}; do
  curl http://your-container-instance.azure.com:5000/error
done

# Check function logs
az webapp log tail -g your-resource-group -n your-function-app
📈 Project Status
✅ Completed Features
 Infrastructure: Complete Terraform setup with all Azure resources
 Application: Python Flask API with health check endpoints
 Monitoring: Azure Monitor integration with Log Analytics
 Alerting: Multiple alert rules for comprehensive coverage
 Auto-Healing: Three different auto-heal approaches implemented
 Security: Managed Identity and RBAC configuration
 Documentation: Comprehensive guides and testing scripts
 CI/CD: Azure DevOps pipeline configuration
🚧 In Progress
 Enhanced Dashboards: Custom Azure Monitor workbooks
 Multi-Region: Cross-region deployment and failover
 Advanced Metrics: Custom application performance indicators
🔮 Future Enhancements
 Kubernetes Support: Migration to Azure Kubernetes Service (AKS)
 Advanced Analytics: Machine learning-based anomaly detection
 Integration Testing: Automated end-to-end testing pipeline
 Cost Optimization: Intelligent scaling based on usage patterns
🤝 Contributing
Fork the repository
Create a feature branch (git checkout -b feature/amazing-feature)
Commit your changes (git commit -m 'Add amazing feature')
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🆘 Support & Troubleshooting
Common Issues
Functions not deploying:

Ensure function app is in "Running" state
Check deployment logs in Azure portal
Verify all environment variables are set
Container restart failing:

Check managed identity permissions
Verify container group exists and is accessible
Review function execution logs
Alerts not triggering:

Confirm Log Analytics is receiving container logs
Validate KQL query syntax in alert rules
Check alert rule evaluation frequency
Getting Help
📖 Documentation: Check the /docs folder for detailed guides
🔍 Troubleshooting: Review the DEPLOYMENT_GUIDE.md for common issues
🧪 Testing: Use scripts/test-auto-heal.sh for verification
📊 Monitoring: Check Azure Monitor for system health and alerts
🏆 Acknowledgments
Built with ❤️ using Azure Cloud Services
Inspired by modern DevOps and SRE practices
Designed for production reliability and scalability
🎯 Ready to deploy? Start with terraform apply and let the automation begin!

├── src/healthcheck-api/      # Python Flask app
├── infrastructure/           # Terraform files
├── scripts/                  # Recovery scripts (PowerShell/Azure CLI)
├── monitor/                  # KQL and alert config
├── .azure-pipelines/         # CI pipeline YAML
├── docs/                     # Architecture, demo script, etc.