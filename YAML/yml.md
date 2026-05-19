# 📄 YAML Configuration — Kubernetes Deployment & Service

## What is YAML?

YAML stands for **"YAML Ain't Markup Language"**.
It is a human-readable configuration format used by DevOps engineers
daily — for Kubernetes, Docker Compose, CI/CD pipelines, and more.

YAML uses **indentation** (spaces, never tabs) to define structure.
Clean, simple, and version-controllable — that's why DevOps runs on YAML.

---

## Why YAML Matters in DevOps

| Reason | Explanation |
|--------|-------------|
| **Human readable** | Easy to write without special tools |
| **Used everywhere** | Kubernetes, Docker Compose, GitHub Actions, Jenkins |
| **Infrastructure as Code** | Define infrastructure in plain text files |
| **Version controlled** | Every change tracked in GitHub — rollback anytime |
| **Reusable** | Write once, deploy anywhere |

---

## Files in This Project

### 📦 deployment.yml — How the App Runs

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trend-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: trend
  template:
    metadata:
      labels:
        app: trend
    spec:
      containers:
      - name: trend-app
        image: mydockerimage31/trend-app-image:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 80
```

**Line by line breakdown:**

| Field | Value | What it means |
|-------|-------|---------------|
| `kind` | Deployment | Tells Kubernetes this is a deployment config |
| `name` | trend-deployment | Name of this deployment inside the cluster |
| `replicas` | 1 | Run 1 pod (1 instance of the app) |
| `image` | mydockerimage31/trend-app-image:latest | Docker image pulled from Docker Hub |
| `imagePullPolicy` | Always | Always pull the latest image on every deploy |
| `containerPort` | 80 | App runs on port 80 inside the container |

---

### 🌐 service.yml — How the App is Accessed

```yaml
apiVersion: v1
kind: Service
metadata:
  name: trend-service
spec:
  type: LoadBalancer
  selector:
    app: trend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

**Line by line breakdown:**

| Field | Value | What it means |
|-------|-------|---------------|
| `kind` | Service | Exposes the app to outside traffic |
| `name` | trend-service | Name of this service inside the cluster |
| `type` | LoadBalancer | Creates a public IP on AWS EKS |
| `selector` | app: trend | Routes traffic to pods labeled `app: trend` |
| `port` | 80 | Port exposed to the outside world |
| `targetPort` | 80 | Port the container is actually listening on |

---

## How These Two Files Work Together

```
deployment.yml   →   "Run trend-app in 1 pod using mydockerimage31/trend-app-image"
service.yml      →   "Expose that pod publicly on port 80 via LoadBalancer"

Without deployment.yml  →  No app running in the cluster
Without service.yml     →  App runs but no one can reach it from outside
Both applied together   →  App running AND publicly accessible ✅
```

---

## How to Apply

```bash
# Apply deployment first
kubectl apply -f deployment.yml

# Then apply service
kubectl apply -f service.yml

# Verify pod is running
kubectl get pods

# Get public IP from LoadBalancer
kubectl get service trend-service
```

Once `kubectl get service` shows an EXTERNAL-IP — that's your live app URL.

---

## Key YAML Rules

```
✅ Always use spaces — never tabs
✅ Indentation must be consistent throughout
✅ Format is key: value
✅ Lists use a dash (-)
✅ YAML is case sensitive — 'Kind' ≠ 'kind'
```

---

## What I Learned From These Files

- `imagePullPolicy: Always` ensures Kubernetes never runs a cached
  old image — critical when pushing updates via CI/CD pipeline
- `LoadBalancer` service type automatically provisions an AWS ELB
  (Elastic Load Balancer) when deployed on EKS
- The `selector` in service.yml must exactly match the `labels`
  in deployment.yml — otherwise traffic never reaches the pod
- One wrong indentation in YAML breaks the entire deployment

---

*Part of the Kubernetes Deployment on AWS EKS project*
*by Naresh Prasad Yadav — [GitHub](https://github.com/mydevopsworld31)*
