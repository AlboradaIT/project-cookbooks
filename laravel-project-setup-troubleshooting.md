# Laravel Project Setup - Complete Troubleshooting Guide

## Project: kaleria
**Date**: August 24, 2025  
**Setup Duration**: ~2 hours  
**Final Status**: ✅ Successfully deployed

---

## 📋 Project Summary

- **Project Name**: kaleria
- **Framework**: Laravel (latest) with PHP 8.2-FPM
- **Database**: MySQL 8.0
- **Web Server**: Nginx (Alpine)
- **Reverse Proxy**: Traefik v3.2
- **Location**: `/home/desarrollo/projects/kaleria`
- **URL**: https://kaleria.local
- **Database Password**: `dElQnVd4VJkP`

---

## 🛠️ Setup Process

### 1. Initial Setup
Following the AlboradaIT cookbook standards, we created the Laravel project using the automated setup script:

```bash
# Clone cookbook repository to temporary location
git clone https://github.com/AlboradaIT/project-cookbooks.git /tmp/project-cookbooks

# Navigate to Laravel template and make executable
cd /tmp/project-cookbooks/laravel-web-app
chmod +x setup.sh

# Run setup script with project parameters
./setup.sh "kaleria" "kaleria" "kaleria.local"

# Clean up temporary files
rm -rf /tmp/project-cookbooks
```

**Configuration Used:**
| Parameter | Value |
|-----------|-------|
| Project | kaleria |
| Directory | kaleria |
| Database | kaleria |
| Domain | kaleria.local |
| Password | dElQnVd4VJkP |

### 2. Initial Docker Startup
Started the containers:
```bash
cd /home/desarrollo/projects/kaleria
docker-compose up -d
```

---

## 🐛 Issues Encountered & Solutions

### Issue 1: Container Name Conflicts
**Problem**: Docker containers with conflicting names from previous projects.
```
Error: The container name "/mysql" is already in use
Error: The container name "/app" is already in use
```

**Solution**: 
```bash
# Remove conflicting containers
docker rm mysql app nginx queue scheduler redis

# Restart with orphan cleanup
docker-compose up -d --remove-orphans
```

### Issue 2: Traefik Configuration Issues
**Problem**: Empty environment section causing YAML validation errors.
```
services.traefik.environment must be a mapping
```

**Solution**: Removed empty environment section from `docker/reverse-proxy/traefik/docker-compose.yml`:
```yaml
# BEFORE (causing error)
environment:
  # Production environment variables (comment out for development)
  # - DO_AUTH_TOKEN=${DO_AUTH_TOKEN}

# AFTER (fixed)
# Removed entire environment section
```

### Issue 3: HTTPS 404 Error (Main Issue)
**Problem**: Application accessible via HTTP but returning 404 on HTTPS requests.

**Symptoms**:
- ✅ HTTP redirect working: `http://kaleria.local` → `https://kaleria.local`
- ❌ HTTPS returning: `404 page not found`
- ✅ Traefik service discovery working
- ✅ Container networking functional
- ✅ Nginx serving Laravel internally

**Debugging Process**:

1. **Verified Basic Connectivity**:
```bash
# Direct nginx test (worked)
docker exec nginx curl http://localhost/

# Traefik to nginx test (worked with curl, failed with wget)
docker exec traefik curl -H 'Host: kaleria.local' http://172.20.0.3:80/
```

2. **Checked Traefik Service Discovery**:
```bash
curl -s http://localhost:8080/api/rawdata
```
Found service correctly registered but HTTPS routing failing.

3. **Container Restart Attempts**:
```bash
# Restarted nginx container
docker-compose restart nginx

# Restarted Traefik
docker restart traefik
```

4. **Network Analysis**:
```bash
# Verified nginx on both networks
docker inspect nginx --format='{{json .NetworkSettings.Networks}}'
# Result: Connected to both 'kaleria_internal' and 'traefik' networks
```

**Root Cause**: Missing TLS termination configuration in Traefik labels.

**Solution Steps**:

1. **Temporarily disabled global redirect** to test HTTP routing:
```yaml
# Commented out in traefik/docker-compose.yml
# - "--entryPoints.web.http.redirections.entryPoint.to=websecure"
# - "--entryPoints.web.http.redirections.entryPoint.scheme=https"
```

2. **Confirmed HTTP routing worked** (proved basic setup was correct).

3. **Fixed service name mismatch** in labels:
```yaml
# BEFORE (incorrect - app service name in nginx labels)
- 'traefik.http.routers.app.rule=Host(`kaleria.local`)'
- 'traefik.http.routers.app.entrypoints=websecure'
- 'traefik.http.services.app.loadbalancer.server.port=80'

# AFTER (correct - nginx service name)
- 'traefik.http.routers.nginx.rule=Host(`kaleria.local`)'
- 'traefik.http.routers.nginx.entrypoints=websecure'
- 'traefik.http.services.nginx.loadbalancer.server.port=80'
```

4. **Added missing TLS configuration** (THE FIX):
```yaml
# Final working configuration
labels:
  - 'traefik.enable=true'
  - 'traefik.docker.network=traefik'
  - 'traefik.http.routers.nginx.rule=Host(`kaleria.local`)'
  - 'traefik.http.routers.nginx.entrypoints=web,websecure'
  - 'traefik.http.routers.nginx.tls=true'  # ← THIS WAS THE KEY
  - 'traefik.http.services.nginx.loadbalancer.server.port=80'
```

5. **Re-enabled global redirect** and tested full functionality.

### Issue 4: Database Sessions Error
**Problem**: After fixing HTTPS, application showed:
```
SQLSTATE[42S02]: Base table or view not found: 1146 Table 'kaleria.sessions' doesn't exist
```

**Analysis**: Laravel configured for database sessions but migrations not run.

**Solution**:
```bash
# Run Laravel migrations
docker-compose exec app php artisan migrate
```

**Discovered**: In modern Laravel, the sessions table is created within the users migration file (`0001_01_01_000000_create_users_table.php`) along with:
- `users` table
- `password_reset_tokens` table  
- `sessions` table

---

## 🔧 Final Working Configuration

### Docker Compose Labels (nginx service)
```yaml
labels:
  - 'traefik.enable=true'
  - 'traefik.docker.network=traefik'
  - 'traefik.http.routers.nginx.rule=Host(`kaleria.local`)'
  - 'traefik.http.routers.nginx.entrypoints=web,websecure'
  - 'traefik.http.routers.nginx.tls=true'
  - 'traefik.http.services.nginx.loadbalancer.server.port=80'
```

### Traefik Configuration
```yaml
command:
  - "--api.insecure=true"
  - "--providers.docker=true"
  - "--providers.docker.exposedbydefault=false"
  - "--entryPoints.web.address=:80"
  - "--entryPoints.web.http.redirections.entryPoint.to=websecure"
  - "--entryPoints.web.http.redirections.entryPoint.scheme=https"
  - "--entryPoints.websecure.address=:443"
  - "--log.level=DEBUG"
```

---

## ✅ Verification Tests

### 1. HTTP Redirect Test
```bash
curl -H "Host: kaleria.local" http://localhost/ -v
# Expected: 301 redirect to https://kaleria.local/
```

### 2. HTTPS Access Test  
```bash
curl -H "Host: kaleria.local" https://localhost/ -k -s | head -5
# Expected: Laravel welcome page HTML
```

### 3. Container Health Check
```bash
docker-compose ps
# Expected: All containers healthy/running
```

### 4. Database Connection Test
```bash
docker-compose exec app php artisan migrate:status
# Expected: Show migrated tables
```

---

## 🎯 Key Lessons Learned

### 1. Critical Traefik TLS Configuration
The most important discovery was that **`traefik.http.routers.nginx.tls=true`** is absolutely required for HTTPS entrypoint routing to work properly, even when using self-signed certificates.

### 2. Service Discovery vs. Routing
- ✅ Service discovery can work perfectly (Traefik finds containers)
- ❌ But routing can still fail due to missing TLS termination config
- Always verify both discovery AND actual request routing

### 3. Laravel Sessions in Modern Versions
- Laravel now includes sessions table in the main users migration
- Always run `php artisan migrate` after initial setup
- Database sessions are the default in new Laravel installations

### 4. Debugging Methodology
1. **Test basic connectivity** (container to container)
2. **Verify service discovery** (Traefik API)
3. **Isolate the protocol** (HTTP vs HTTPS)
4. **Check TLS termination** configuration
5. **Test incrementally** (disable redirects, test HTTP, add HTTPS)

### 5. Container Name Management
- Previous projects can leave conflicting container names
- Always clean up with `--remove-orphans` flag
- Consider unique naming schemes for different projects

---

## 🚀 Post-Setup Next Steps

### Development Commands
```bash
cd /home/desarrollo/projects/kaleria

# Laravel Artisan Commands
docker-compose exec app php artisan make:model YourModel
docker-compose exec app php artisan make:controller YourController
docker-compose exec app php artisan make:migration create_your_table
docker-compose exec app php artisan migrate

# Container Management
docker-compose logs -f app          # View logs
docker-compose exec app bash        # Access container shell
docker-compose restart nginx        # Restart specific service

# Database Operations
docker-compose exec mysql mysql -u root -p
docker-compose exec app php artisan db:dump  # Custom dump command
```

### GitHub Repository Setup (Optional)
```bash
cd /home/desarrollo/projects/kaleria
gh repo create AlboradaIT/kaleria --private --source=. --push
```

---

## 📚 References

- **AlboradaIT Cookbook**: https://github.com/AlboradaIT/project-cookbooks
- **Laravel Documentation**: https://laravel.com/docs
- **Traefik v3 Documentation**: https://doc.traefik.io/traefik/
- **Docker Compose Reference**: https://docs.docker.com/compose/

---

## 🏆 Final Status

**✅ PROJECT SUCCESSFULLY DEPLOYED**

- **URL**: https://kaleria.local
- **Status**: Fully functional Laravel application
- **Database**: Connected and migrated
- **SSL**: Working with self-signed certificates
- **Development**: Ready for feature development

**Total Setup Time**: ~2 hours (including troubleshooting)  
**Main Blocker**: Missing `tls=true` in Traefik configuration  
**Resolution**: Systematic debugging approach identifying TLS termination issue

---

*This document serves as a comprehensive reference for future Laravel project setups using the AlboradaIT cookbook and troubleshooting common Traefik + Docker + Laravel issues.*
