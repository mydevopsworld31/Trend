----------------------------------------This is my README file-------------------------------------------------

Trend App – End-to-End DevOps CI/CD Pipeline
📌 Project Overview

This project demonstrates a complete end-to-end DevOps implementation for deploying a React application using modern tools and AWS cloud infrastructure.
It covers CI/CD automation, containerization, orchestration, infrastructure provisioning, and monitoring.

🏗️ Architecture
GitHub → Jenkins → Docker → DockerHub → AWS EKS → Kubernetes → LoadBalancer → Grafana Monitoring

⚙️ Tools & Technologies Used
🔹 Cloud & Infrastructure
AWS EC2 (Jenkins Server)
AWS EKS (Kubernetes Cluster)
AWS VPC, Subnets, IAM
🔹 DevOps Tools
Jenkins (CI/CD Pipeline)
Docker (Containerization)
DockerHub (Image Registry)
Kubernetes (Container Orchestration)
Terraform (Infrastructure as Code)
🔹 Monitoring
Prometheus (Metrics collection)
Grafana (Visualization dashboards)

📂 Application Details
Application: React App
Repository: https://github.com/Vennilavanguvi/Trend.git

🔄 CI/CD Workflow
Developer pushes code to GitHub
GitHub Webhook triggers Jenkins pipeline
Jenkins performs:
Clone repository
Build Docker image
Push image to DockerHub
Jenkins deploys application to Kubernetes (EKS)
Kubernetes pulls latest image and updates deployment
LoadBalancer exposes application to the internet
Prometheus collects metrics
Grafana displays monitoring dashboards

🐳 Docker Setup
Dockerfile (Summary)
Base image: nginx
Copies React build files (dist/)
Uses custom nginx configuration
Build Command
docker build -t mydockerimage31/trend-app-image:latest .
Push Command
docker push mydockerimage31/trend-app-image:latest

☸️ Kubernetes Setup
Deployment
Manages application pods
Uses Docker image from DockerHub
Supports scaling and rolling updates
Service
Type: LoadBalancer
Exposes application externally
Commands Used
kubectl apply -f deployment.yml
kubectl apply -f service.yml
kubectl get pods
kubectl get svc

🌐 Application Access
Access URL:
http://<LoadBalancer-EXTERNAL-IP>

📦 LoadBalancer ARN
<LOADBALANCER ARN>

🏗️ Terraform (Infrastructure as Code)
Terraform is used to provision:
VPC
Subnets
EC2 instance (Jenkins server)
IAM roles and permissions
Commands
terraform init
terraform plan
terraform apply

📊 Monitoring Setup
Prometheus
Collects metrics from Kubernetes cluster
Monitors nodes, pods, and services
Grafana
Visualizes metrics using dashboards
Displays:
CPU usage
Memory usage
Pod health
Cluster performance
Access Grafana
http://<Grafana-EXTERNAL-IP>

🧠 Challenges Faced & Solutions
Issue	                                                          Solution
Jenkins unable to access Kubernetes	                            Configured kubeconfig and AWS credentials
Container name mismatch	                                         Fixed deployment YAML
Grafana not accessible	                                         Exposed via LoadBalancer
No monitoring data	                                              Verified Prometheus targets

Conclusion
This project demonstrates a complete DevOps lifecycle, including:

Continuous Integration & Deployment
Containerization using Docker
Kubernetes orchestration on AWS EKS
Infrastructure automation with Terraform
Monitoring using Prometheus and Grafana


👨‍💻 Author
Naresh Prasad Yadav
DevOps Enthusiast | Mechanical Engineer
