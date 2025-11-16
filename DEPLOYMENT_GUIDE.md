# World Clock Application - Deployment Guide

## Quick Start for Testing

### Prerequisites
- Docker Hub account (victorthegreat7)
- Azure account with AKS cluster
- GitHub repository secrets configured

### Building Docker Images Locally (Optional)

```bash
# Build backend
cd backend
docker build -t victorthegreat7/world-clock-backend:latest .
docker push victorthegreat7/world-clock-backend:latest

# Build frontend
cd frontend
docker build -t victorthegreat7/world-clock-frontend:latest .
docker push victorthegreat7/world-clock-frontend:latest
```

### Testing Locally

#### 1. Start Backend
```bash
cd backend
python app.py
# Available at http://localhost:5000
# Test: curl http://localhost:5000/api/world-clocks
```

#### 2. Start Frontend
```bash
cd frontend
npm install
npm run dev
# Available at http://localhost:5173
```

#### 3. Test Full Stack
Open http://localhost:5173 in your browser. The frontend will connect to the backend at localhost:5000.

### Kubernetes Deployment

#### 1. Deploy to AKS
The GitHub Actions workflow will:
1. Build both Docker images
2. Test containers
3. Push to Docker Hub
4. Apply Terraform configuration to deploy to AKS

#### 2. Verify Deployment
```bash
# Get cluster credentials
az aks get-credentials --resource-group <resource-group> --name <cluster-name>
kubelogin convert-kubeconfig -l azurecli

# Check deployments
kubectl get deployments -n time-api
kubectl get services -n time-api
kubectl get ingress -n time-api

# Check pods
kubectl get pods -n time-api
kubectl logs -l app=world-clock-backend -n time-api
kubectl logs -l app=world-clock-frontend -n time-api
```

#### 3. Test the Application
```bash
# Get the ingress IP
kubectl get ingress world-clock-ingress -n time-api

# Test backend API
curl http://<ingress-ip>/api/world-clocks

# Test frontend (open in browser)
open http://<ingress-ip>/
```

### Architecture

```
Client Browser
     ↓
Ingress (nginx)
     ├─→ / → Frontend Service (port 80) → Frontend Pods (nginx + React)
     └─→ /api/* → Backend Service (port 80) → Backend Pods (Flask on port 5000)
```

### Ingress Routing

- **Frontend**: `http://<ingress-ip>/` → world-clock-frontend-service
- **Backend API**: `http://<ingress-ip>/api/*` → world-clock-backend-service

The rewrite rule in the ingress strips the `/api` prefix when forwarding to the backend, so:
- `http://<ingress-ip>/api/world-clocks` → `http://backend-service/world-clocks`

### Troubleshooting

#### Backend Issues
```bash
# Check backend logs
kubectl logs -l app=world-clock-backend -n time-api --tail=50

# Check backend health
kubectl exec -it <backend-pod> -n time-api -- curl http://localhost:5000/health

# Test backend internally
kubectl run test-pod --image=busybox -it --rm -- wget -qO- http://world-clock-backend-service.time-api.svc.cluster.local:80/api/world-clocks
```

#### Frontend Issues
```bash
# Check frontend logs
kubectl logs -l app=world-clock-frontend -n time-api --tail=50

# Check frontend health
kubectl exec -it <frontend-pod> -n time-api -- wget -qO- http://localhost/health

# Test frontend internally
kubectl run test-pod --image=busybox -it --rm -- wget -qO- http://world-clock-frontend-service.time-api.svc.cluster.local:80/
```

#### Ingress Issues
```bash
# Check ingress configuration
kubectl describe ingress world-clock-ingress -n time-api

# Check nginx ingress controller logs
kubectl logs -l app.kubernetes.io/name=ingress-nginx -n nginx-ingress

# Test ingress paths
curl -v http://<ingress-ip>/
curl -v http://<ingress-ip>/api/world-clocks
```

### Load Testing

The Terraform deployment includes automatic load tests:
- `backend-loadtest`: 30 requests to `/api/world-clocks`
- `frontend-loadtest`: 30 requests to `/`

Check load test results:
```bash
kubectl get jobs -n time-api
kubectl logs job/backend-loadtest -n time-api
kubectl logs job/frontend-loadtest -n time-api
```

### Security Summary

✅ **Vulnerabilities Scanned:**
- No vulnerabilities found in Python dependencies (Flask 3.0.0, flask-cors 4.0.0, pytz 2024.1)
- No vulnerabilities found in npm dependencies (React 19.2.0, Vite 7.2.2)
- No CodeQL security alerts in actions, Python, or JavaScript code

✅ **Security Features:**
- Multi-stage Docker builds minimize attack surface
- Health check endpoints for monitoring
- CORS properly configured for API access
- Network policies restrict inter-pod communication
- Kubernetes RBAC for access control
- Container resource limits prevent resource exhaustion

### Monitoring

After deployment, monitor the application:
```bash
# Watch pod status
kubectl get pods -n time-api -w

# Monitor resource usage
kubectl top pods -n time-api

# Check service endpoints
kubectl get endpoints -n time-api
```

### Cleanup

To remove the deployment:
```bash
cd terraform
terraform destroy
```

Or use the GitHub Actions "Destroy Infrastructure" workflow.
