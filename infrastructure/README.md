# 🏗️ Infrastructure Documentation

> *When Plan A meets reality, sometimes you need Plan B, C, and D* 😅

## 🎯 Project Overview

This infrastructure deploys a health check API using **Azure Container Instances (ACI)** instead of the originally planned Azure App Service. This document explains why we made this architectural decision and what restrictions led us there.

## 🚧 Why Azure Container Instances? The Journey

### 🎪 The Original Plan
We initially designed this infrastructure to use:
- **Azure App Service** with Python runtime
- **Free Tier (F1)** for cost optimization
- Simple deployment model for a basic health check API

### 💥 Reality Check: Quota Restrictions Encountered

#### 1. **Free Tier Quota Limitations** 
```
Error: Current Limit (Free VMs): 0
```
- **Issue**: Azure subscription had zero quota for F1 (Free) App Service plans
- **Common in**: Student subscriptions, trial accounts, restricted enterprise accounts
- **Impact**: Couldn't deploy free tier resources

#### 2. **Basic Tier Quota Limitations**
```
Error: Current Limit (Basic VMs): 0  
```
- **Issue**: Even B1 (Basic) tier had zero quota available
- **Reason**: Some subscription types have limited compute quotas across all tiers
- **Cost Factor**: B1 would have cost ~$13-15/month anyway

#### 3. **Regional Quota Variations**
- **Initial Region**: East US - No quota available
- **Attempted**: West US 2 - Same quota restrictions
- **Learning**: Quota limits often apply subscription-wide, not per-region

## 🎯 Azure Container Instances: The Solution

### ✅ Why ACI Worked
- **Different Quota Pool**: ACI uses separate quota allocations from App Service
- **Flexible Compute**: More granular resource allocation (0.5 CPU, 1.5GB RAM)
- **Container-First**: Perfect for containerized applications
- **Public IP**: Built-in external access without additional networking setup

### 🏗️ Architecture Benefits

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Internet      │───▶│  Azure Container │───▶│  Health Check   │
│   Traffic       │    │    Instance      │    │      API        │
│                 │    │                  │    │                 │
│ Port 5000       │    │  Public DNS      │    │  Flask + Waitress│
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📋 Current Infrastructure Components

### 🔧 Resources Deployed
| Component | Type | Purpose | Specifications |
|-----------|------|---------|----------------|
| **Resource Group** | `azurerm_resource_group` | Container for all resources | Location: West US 2 |
| **Container Instance** | `azurerm_container_group` | Hosts the health check API | 0.5 CPU, 1.5GB RAM |
| **Public IP** | Built-in with ACI | External access | Auto-assigned |
| **DNS Label** | Built-in with ACI | Friendly URL | `{app-name}.westus2.azurecontainer.io` |

### 🐳 Container Configuration
- **Base Image**: `mcr.microsoft.com/azure-functions/python:4-python3.11-appservice`
- **Runtime**: Python 3.11 with Flask and Waitress
- **Ports**: 5000 (TCP)
- **Health Endpoints**: `/health` and `/crash`

## 🚨 Common Azure Subscription Restrictions

### 📚 Types of Restricted Subscriptions

#### 🎓 **Student Subscriptions**
- Limited free tier quotas
- Restricted premium SKUs
- Regional limitations
- **Workaround**: Use alternative services like ACI, Azure Functions

#### 🆓 **Free Trial Accounts**
- $200 credit limit
- 30-day expiration
- No free tier after credits expire
- **Workaround**: Switch to pay-as-you-go for continued free tiers

#### 🏢 **Enterprise Restricted Accounts**
- Company-imposed quota limits
- Specific region restrictions
- Approved service catalogs only
- **Workaround**: Request quota increases or use approved alternatives

#### 💳 **Pay-as-You-Go with Spending Limits**
- Spending caps can block resource creation
- Credit card verification required for some services
- **Workaround**: Remove spending limits or add payment method

## 🛠️ Alternative Solutions Considered

### Option 1: **Azure Functions** ⚡
- **Pros**: Serverless, automatic scaling, generous free tier
- **Cons**: Cold start latency, different development model
- **Status**: Could be future migration target

### Option 2: **Azure Static Web Apps** 🌐
- **Pros**: Free tier available, integrated CI/CD
- **Cons**: Limited to static content, no server-side logic
- **Status**: Not suitable for this API

### Option 3: **Request Quota Increase** 📈
- **Pros**: Would enable original App Service plan
- **Cons**: Approval process, potential costs, not guaranteed
- **Status**: Long-term consideration

### Option 4: **Different Azure Region** 🌍
- **Pros**: Sometimes quotas vary by region
- **Cons**: Same subscription-level restrictions applied
- **Status**: Attempted, unsuccessful

## 🎯 Deployment Commands

### 🚀 Quick Deploy
```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform
tf init

# Plan the deployment
tf plan

# Apply the infrastructure
tf apply
```

### 🧪 Test Your Deployment
```bash
# Health check endpoint
curl http://autoscale-healthcheck.westus2.azurecontainer.io:5000/health

# Expected response: {"status": "healthy"}
```

## 💡 Lessons Learned

### 🎯 **Always Have a Plan B**
Cloud quotas can be unpredictable. Design flexibility into your infrastructure choices.

### 🔍 **Understand Your Subscription Type**
Different Azure subscription types have vastly different limitations and capabilities.

### 🏗️ **Container Instances Are Underrated**
ACI provides excellent value for simple, containerized workloads with fewer restrictions.

### 📊 **Cost vs. Complexity Trade-offs**
Sometimes a slightly more complex solution (ACI) is more cost-effective than fighting quotas.

## 🚀 Future Improvements

### 📈 **Scaling Options**
- Migrate to **Azure Kubernetes Service (AKS)** for multi-container orchestration
- Use **Azure Container Apps** for serverless container experience
- Implement **Azure Front Door** for global distribution

### 🔒 **Security Enhancements**
- Add **Azure Key Vault** for secrets management
- Implement **Azure AD authentication**
- Set up **private networking** with VNet integration

### 📊 **Monitoring & Observability**
- Add **Azure Application Insights** for telemetry
- Set up **Azure Monitor** alerts
- Implement **Azure Log Analytics** for centralized logging

---

*Built with determination, deployed with creativity, and documented with coffee ☕*

## 🆘 Troubleshooting

**Getting quota errors?**
1. Check your subscription type in Azure Portal
2. Try different regions
3. Consider alternative services (Functions, Container Instances)
4. Request quota increases (if budget allows)

**Container not starting?**
1. Check Azure Portal logs
2. Verify image availability
3. Review environment variables
4. Test locally with Docker first
