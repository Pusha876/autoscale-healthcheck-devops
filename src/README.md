# 🚀 Health Check API

> *Because even your apps need a doctor sometimes* 🩺

A lightweight Flask API designed to help your infrastructure know when things are healthy... or when they need to crash and burn 🔥

## 🎯 What's This About?

Ever deployed an app and wondered "Is it actually working?" This little health check API is your canary in the coal mine. It's simple, reliable, and comes with a self-destruct button (because sometimes you need to test your auto-scaling 😈).

## ⚡ Quick Start

### 🐍 Python Setup
```bash
# Navigate to the API directory
cd src/healthcheck-api

# Install dependencies
pip install -r requirements.txt
```

### 🚀 Launch Options

#### Option 1: Gunicorn (Recommended for Linux/Production)
```bash
gunicorn --bind 0.0.0.0:5000 --workers 2 app:app
```

#### Option 2: Waitress (Recommended for Windows)
```bash
waitress-serve --host=0.0.0.0 --port=5000 app:app
```

#### Option 3: Flask Dev Server (Quick & Dirty)
```bash
python app.py
```

#### Option 4: Flask CLI (The "Proper" Way)
```bash
flask run --host=0.0.0.0 --port=5000
```

## 🔌 API Endpoints

### 🟢 Health Check
```
GET /health
```
Returns a simple "I'm alive!" message. Perfect for load balancers and worried DevOps engineers.

**Response:**
```json
{
  "status": "healthy"
}
```

### 💥 Crash Test Dummy
```
GET /crash
```
**⚠️ WARNING:** This endpoint will terminate the application immediately. Use responsibly!

Perfect for testing:
- Auto-scaling policies
- Container orchestration recovery
- Your stress levels 📈

## 🛠️ Tech Stack

- **Flask** - Because sometimes simple is better
- **Gunicorn** - Production-ready WSGI server for Linux deployments
- **Waitress** - WSGI server that actually works on Windows
- **Flask-CORS** - For when your frontend and backend need to talk

## 🎨 Development Notes

### Windows Users 💻
We use Waitress for Windows development because Gunicorn thinks Windows is "not cool enough" (it lacks Unix-specific modules). Waitress doesn't judge your OS choices.

### Linux/Azure Deployment 🐧☁️
For production deployments on Linux systems (like our Azure Container Instance), we use Gunicorn:
```bash
# Production deployment with multiple workers
gunicorn app:app --bind 0.0.0.0:5000 --workers 2

# Or the simple version
gunicorn app:app --bind 0.0.0.0:5000
```

### 🚀 Current Azure Deployment
This API is currently running on **Azure Container Instances** with:
- **OS**: Linux
- **Server**: Gunicorn with 2 workers
- **Resources**: 0.5 CPU, 1.5GB RAM
- **Access**: Public IP with DNS label

## 🧪 Testing

Want to make sure everything works? Hit these URLs:

- 🟢 **Health Check**: http://localhost:5000/health
- 💥 **Crash Test**: http://localhost:5000/crash *(use with caution!)*

## 🚨 Pro Tips

1. **Don't hit `/crash` in production** unless you're testing auto-recovery
2. **Use this with load balancers** to automatically remove unhealthy instances
3. **Monitor the `/health` endpoint** to track uptime and availability
4. **Have fun!** This is just code, not rocket science 🚀

---

*Made with ❤️ and probably too much coffee ☕*