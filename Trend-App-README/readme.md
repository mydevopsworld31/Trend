# 📈 Trend App — End-to-End DevOps CI/CD Pipeline

A complete DevOps implementation for deploying a React application using Jenkins, Docker, Kubernetes (AWS EKS), Terraform, and Prometheus + Grafana monitoring.

---

## 📌 Project Overview

This project demonstrates a full DevOps lifecycle — from source code on GitHub to a live, publicly accessible application on AWS — using industry-standard tools for CI/CD automation, containerization, Kubernetes orchestration, infrastructure-as-code, and observability.

---

## 🏗️ Architecture

```
Developer → GitHub → Jenkins (CI/CD) → Docker Build → DockerHub
                                                         ↓
CloudWatch ← Grafana ← Prometheus ← Kubernetes (EKS) ← Image Pull
                                          ↓
                                    LoadBalancer → Internet
```

---

## ⚙️ Tech Stack

| Category | Tools |
|---|---|
| Cloud & Infrastructure | AWS EC2, AWS EKS, AWS VPC, IAM |
| CI/CD | Jenkins (Pipeline as Code) |
| Containerization | Docker, DockerHub |
| Orchestration | Kubernetes (kubectl) |
| Infrastructure as Code | Terraform |
| Monitoring | Prometheus, Grafana |
| Version Control | Git, GitHub |

---

## 📦 Application Details

| Property | Value |
|---|---|
| Application | Trend App (React) |
| Source Repository | https://github.com/Vennilavanguvi/Trend.git |
| My Project Repository | https://github.com/mydevopsworld31/Trend |
| Docker Image | `mydockerimage31/trend-app-image:<build_number>` |
| Local Port | 3000 |
| Container / K8s Port | 80 |

---

## 📁 Repository Structure

```
Trend/
├── Snapshot/           # Project screenshots
├── Terraform-Code/     # IaC for AWS infrastructure
├── Trend-Project/      # Application source files
├── YAML/               # Kubernetes manifests
├── dist/               # Production build output
├── Dockerfile          # Container definition
├── Jenkinsfile         # CI/CD pipeline definition
├── nginx.conf          # Custom Nginx configuration
└── README.md
```

---

## 🚀 Step-by-Step Deployment

### Step 1 — Infrastructure Provisioning with Terraform

Terraform provisions all required AWS infrastructure before any deployment:

```hcl
# Resources provisioned:
# - VPC and Subnets
# - EC2 instance (Jenkins server)
# - IAM roles and permissions
```

```bash
cd Terraform-Code/

terraform init
terraform plan
terraform apply
```

> After `apply`, note the EC2 public IP — this is your Jenkins server address.

---

### Step 2 — Jenkins Server Setup (on EC2)

SSH into the EC2 instance and install Jenkins, Docker, kubectl, and AWS CLI:

```bash
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>

# Install Jenkins, Docker, kubectl, AWS CLI
# Configure AWS credentials
aws configure

# Update kubeconfig for EKS access
aws eks update-kubeconfig --region <your-region> --name <cluster-name>
```

Add the following credentials in Jenkins (`Manage Jenkins → Credentials`):

| ID | Type | Purpose |
|---|---|---|
| `Git-Cred` | Username/Password | GitHub access |
| `Docker-Cred` | Username/Password | DockerHub push |

---

### Step 3 — Dockerize the Application

The `Dockerfile` uses Nginx to serve the pre-built React `dist/` files:

```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

Build and verify locally:

```bash
docker build -t mydockerimage31/trend-app-image:latest .
docker run -p 80:80 mydockerimage31/trend-app-image:latest
```

---

### Step 4 — Amazon EKS Cluster Setup

Create the EKS cluster using `eksctl`:

```bash
eksctl create cluster \
  --name trend-cluster \
  --region ap-south-1 \
  --nodegroup-name trend-nodes \
  --node-type t3.small \
  --nodes 2

# Verify cluster and nodes
kubectl get nodes
```

---

### Step 5 — Kubernetes Manifests

**`YAML/deployment.yml`** — Manages pods and rolling updates:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trend-app-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: trend-app
  template:
    metadata:
      labels:
        app: trend-app
    spec:
      containers:
        - name: trend-app
          image: mydockerimage31/trend-app-image:latest
          ports:
            - containerPort: 80
```

**`YAML/service.yml`** — Exposes the app via AWS LoadBalancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: trend-app-service
spec:
  type: LoadBalancer
  selector:
    app: trend-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

---

### Step 6 — Jenkins CI/CD Pipeline

The `Jenkinsfile` defines a 5-stage automated pipeline triggered on every GitHub push via webhook:

```groovy
pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "mydockerimage31/trend-app-image"
    DOCKER_TAG   = "${BUILD_NUMBER}"
  }

  stages {
    stage('Clone Code') {
      steps {
        git branch: 'main',
            url: 'https://github.com/mygitcode31/Trend.git',
            credentialsId: 'Git-Cred'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .'
      }
    }

    stage('Login to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'Docker-Cred',
                         usernameVariable: 'USER', passwordVariable: 'PASS')]) {
          sh 'echo $PASS | docker login -u $USER --password-stdin'
        }
      }
    }

    stage('Push to DockerHub') {
      steps {
        sh 'docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}'
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh 'kubectl apply -f YAML/service.yml'
        sh 'kubectl apply -f YAML/deployment.yml'
      }
    }
  }

  post {
    always { cleanWs() }
  }
}
```

**Pipeline Flow:**

```
Push to GitHub → Webhook → Jenkins triggered
  → Stage 1: Clone repository
  → Stage 2: Build Docker image (tagged with build number)
  → Stage 3: Login to DockerHub
  → Stage 4: Push image to DockerHub
  → Stage 5: Deploy to EKS via kubectl
```

---

### Step 7 — Monitoring with Prometheus & Grafana

**Install Prometheus using Helm:**

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack
```

**Expose Grafana via LoadBalancer:**

```bash
kubectl patch svc prometheus-grafana \
  -p '{"spec": {"type": "LoadBalancer"}}'

# Get the external IP
kubectl get svc prometheus-grafana
```

**Access Grafana:**

```
http://<Grafana-EXTERNAL-IP>
Default credentials: admin / prom-operator
```

Grafana dashboards display:
- CPU and memory usage per pod
- Node health and resource utilization
- Pod restart counts and health status
- Cluster-wide performance metrics

---

### Step 8 — Verify Deployment

```bash
# Check all pods are running
kubectl get pods

# Get the LoadBalancer external URL
kubectl get svc trend-app-service

# View pod logs for debugging
kubectl logs <pod-name>

# Describe a pod for detailed events
kubectl describe pod <pod-name>
```

---

## 🌐 Application Access

Once deployed, the application is accessible at the LoadBalancer external IP:

```
http://<LoadBalancer-EXTERNAL-IP>
```

> **LoadBalancer ARN:** `<LOADBALANCER-ARN>`  
> *(Replace with your actual ARN from `kubectl get svc`)*

---

## 🐛 Challenges & Solutions

| Challenge | Root Cause | Solution |
|---|---|---|
| Jenkins couldn't access Kubernetes | Missing kubeconfig and AWS credentials on Jenkins server | Configured `aws configure` and `aws eks update-kubeconfig` on EC2 |
| Container name mismatch | Selector in `service.yml` didn't match pod label | Fixed `app` label to be consistent across deployment and service YAMLs |
| Grafana not accessible externally | Service type was `ClusterIP` by default | Patched Grafana service to `LoadBalancer` type |
| No data in Grafana dashboards | Prometheus targets not correctly scraped | Verified Prometheus targets at `/targets` endpoint and fixed scrape configs |

---

## 💡 Key Learnings

- Declarative CI/CD pipeline using Jenkins and `Jenkinsfile`
- Docker image versioning with build numbers for traceability
- Kubernetes rolling deployments and LoadBalancer services on AWS EKS
- Infrastructure provisioning with Terraform (VPC, EC2, IAM)
- Setting up Prometheus scraping and Grafana dashboards for a live cluster
- Debugging pod scheduling, service selectors, and kubeconfig issues

---

## ✅ Submission Checklist

- [x] GitHub repository with full source code: https://github.com/mydevopsworld31/Trend
- [x] `Dockerfile`, `Jenkinsfile`, Kubernetes YAML files included
- [x] Terraform code for infrastructure provisioning
- [x] Application deployed and accessible via Kubernetes LoadBalancer
- [x] Prometheus + Grafana monitoring configured
- [ ] Screenshots in `Snapshot/` folder (attach to submission document)
- [ ] LoadBalancer ARN (fill in after deployment)

---

## 👨‍💻 Author

**Naresh Prasad Yadav**  
DevOps Enthusiast | Mechanical Engineer  
GitHub: [@mydevopsworld31](https://github.com/mydevopsworld31)
