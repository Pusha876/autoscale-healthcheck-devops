```
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

FLOW:
1. Developer pushes code → Azure DevOps CI/CD pipeline triggers
2. Pipeline builds Docker image → pushes to Azure Container Registry
3. ACI pulls image → deploys Flask health check API
4. App generates logs/metrics → sent to Log Analytics Workspace
5. KQL alert rules monitor logs → detect errors, downtime, or performance issues
6. Alerts trigger Action Groups → send notifications and webhook to Azure Function
7. Azure Function evaluates alerts → performs health checks → restarts container if needed
8. Managed Identity provides secure authentication → no hardcoded secrets
9. Container restarts gracefully → health verified → service restored

KEY FEATURES:
• Automated monitoring and alerting
• Self-healing container restart
• Infrastructure as Code with Terraform
• Secure authentication with Managed Identity
• Multiple alert scenarios and recovery methods
• Comprehensive logging and audit trail
```
