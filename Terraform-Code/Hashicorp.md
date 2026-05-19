# Hashicorp Language
## for provisioning infrastructure in 5 minutes....

# 🏗️ Terraform Infrastructure as Code — AWS EC2 + Jenkins Setup

> Complete guide to understanding and running this Terraform project —
> from "what is Terraform" to a live Jenkins server on AWS.

---

## 🤔 What is Terraform?

Terraform is an open-source **Infrastructure as Code (IaC)** tool
created by HashiCorp. Instead of clicking through the AWS console
to create servers, networks, and security rules manually —
you write code that does it automatically.

**One command. Entire infrastructure. Every time. Consistently.**

```
Without Terraform          With Terraform
──────────────────         ──────────────────
Click AWS Console    →     Write main.tf
Create VPC manually  →     terraform apply
Create Subnet        →     Done in 2 minutes
Create EC2           →     Same result every time
~30 minutes          →     ~5 minutes
Human error risk     →     Zero — it's code
```

---

## 🌍 Why Terraform in DevOps?

| Reason | Explanation |
|--------|-------------|
| **Reproducible** | Same code = same infrastructure every time |
| **Version controlled** | Store in GitHub — track every change |
| **Cloud agnostic** | Works with AWS, Azure, GCP — same syntax |
| **Team friendly** | Everyone works from the same infra code |
| **Rollback ready** | Destroy and recreate anytime |
| **Industry standard** | Used in every serious DevOps team |

---

## 📁 Project Structure

```
terraform-project/
│
├── main.tf          # All infrastructure defined here
├── .terraform/      # Auto-created after terraform init
├── terraform.tfstate        # Tracks what's deployed (don't edit)
└── terraform.tfstate.backup # Backup of last known state
```

---

## 🏛️ What This Project Builds on AWS

```
AWS Cloud (ap-south-1 — Mumbai)
│
└── VPC (10.0.0.0/16) — "devops-vpc"
    │
    ├── Public Subnet (10.0.1.0/24)
    │   └── EC2 Instance (t3.small) — "Jenkins-Server"
    │       ├── AMI: Amazon Linux 2023
    │       ├── Key: myjenkins
    │       └── IAM Role: ec2-jenkins-role
    │
    ├── Internet Gateway — "devops-igw"
    ├── Route Table — routes 0.0.0.0/0 → IGW
    └── Security Group — "jenkins_sg"
        ├── Port 22   (SSH)
        ├── Port 8080 (Jenkins)
        └── Port 3000 (Grafana)
```

---

## 📄 main.tf — Full Breakdown

### 1️⃣ Provider Block — Connect to AWS

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

Tells Terraform: *"Talk to AWS and use the Mumbai region."*
Every resource created will live in `ap-south-1`.

---

### 2️⃣ VPC — Virtual Private Cloud

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "devops-vpc"
  }
}
```

| Field | Value | Meaning |
|-------|-------|---------|
| `cidr_block` | 10.0.0.0/16 | Private IP range — up to 65,536 addresses |
| `Name` | devops-vpc | Label visible in AWS Console |

A VPC is your **private network inside AWS** — nothing gets in or out
unless you explicitly allow it.

---

### 3️⃣ Public Subnet

```hcl
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
```

| Field | Value | Meaning |
|-------|-------|---------|
| `cidr_block` | 10.0.1.0/24 | Subset of VPC — up to 256 addresses |
| `map_public_ip_on_launch` | true | EC2 gets a public IP automatically |

The subnet lives **inside the VPC** and holds the EC2 instance.

---

### 4️⃣ Internet Gateway

```hcl
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}
```

The internet gateway is the **door between your VPC and the internet.**
Without it — your EC2 instance exists but is completely unreachable.

---

### 5️⃣ Route Table + Association

```hcl
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
```

**Route table** = traffic rules.
`0.0.0.0/0 → IGW` means: *"Send all internet traffic through the gateway."*
**Association** = attach those rules to the public subnet.

```
Internet → IGW → Route Table → Public Subnet → EC2
```

---

### 6️⃣ Security Group — Firewall Rules

```hcl
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.main.id

  ingress { from_port = 22,   to_port = 22,   protocol = "tcp" }
  ingress { from_port = 8080, to_port = 8080, protocol = "tcp" }
  ingress { from_port = 3000, to_port = 3000, protocol = "tcp" }

  egress { from_port = 0, to_port = 0, protocol = "-1" }
}
```

| Port | Purpose | Direction |
|------|---------|-----------|
| 22 | SSH into server | Inbound |
| 8080 | Jenkins dashboard | Inbound |
| 3000 | Grafana dashboard | Inbound |
| All ports | Server can reach internet | Outbound |

`protocol = "-1"` on egress means **all protocols allowed outbound.**

---

### 7️⃣ IAM Role — EC2 Permissions

```hcl
resource "aws_iam_role" "ec2_role" {
  name = "ec2-jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}
```

**IAM Role** = identity card for the EC2 instance.
Allows the EC2 server to make AWS API calls with EC2FullAccess.
**Instance Profile** = the wrapper that attaches the role to EC2.

```
EC2 Instance
  └── Instance Profile
        └── IAM Role (ec2-jenkins-role)
              └── Policy: AmazonEC2FullAccess
```

---

### 8️⃣ AMI Data Source — Auto-fetch Latest Amazon Linux

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}
```

Instead of hardcoding an AMI ID (which goes stale),
this block **automatically fetches the latest Amazon Linux 2023 image.**
`most_recent = true` ensures you always get the newest version.

---

### 9️⃣ EC2 Instance — The Jenkins Server

```hcl
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  key_name               = "myjenkins"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.profile.name

  tags = {
    Name = "Jenkins-Server"
  }
}
```

| Field | Value | Meaning |
|-------|-------|---------|
| `ami` | auto-fetched | Latest Amazon Linux 2023 |
| `instance_type` | t3.small | 2 vCPU, 2GB RAM |
| `key_name` | myjenkins | SSH key pair for login |
| `subnet_id` | public subnet | Places EC2 in public subnet |
| `vpc_security_group_ids` | jenkins_sg | Applies firewall rules |

---

## 🚀 Running This Project — Step by Step

### Prerequisites
- Terraform installed on your machine
- AWS CLI configured with credentials
- SSH key pair named `myjenkins` created in AWS Mumbai region

---

### Step 1 — terraform init

```bash
terraform init
```

**What it does:**
- Downloads the AWS provider plugin
- Sets up the `.terraform` directory
- Prepares the working directory

```
Initializing provider plugins...
- Finding hashicorp/aws versions...
- Installing hashicorp/aws v5.x.x...
✅ Terraform has been successfully initialized!
```

---

### Step 2 — terraform fmt

```bash
terraform fmt
```

**What it does:**
Formats your `.tf` files with correct indentation and style.
Always run this before committing to GitHub.

---

### Step 3 — terraform validate

```bash
terraform validate
```

**What it does:**
Checks your code for syntax errors before touching any real AWS resources.

```
✅ Success! The configuration is valid.
```

---

### Step 4 — terraform plan

```bash
terraform plan
```

**What it does:**
Shows you exactly what will be created, changed, or destroyed.
**Nothing is deployed yet** — this is just a preview.

```
Plan: 9 to add, 0 to change, 0 to destroy.
```

Read this carefully before applying.

---

### Step 5 — terraform apply

```bash
terraform apply
```

Terraform shows the plan again and asks for confirmation:

```
Do you want to perform these actions? yes
```

Type `yes` and press Enter.

```
aws_vpc.main: Creating...
aws_subnet.public_subnet: Creating...
aws_internet_gateway.igw: Creating...
aws_security_group.jenkins_sg: Creating...
aws_iam_role.ec2_role: Creating...
aws_instance.jenkins: Creating...

✅ Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
```

Your Jenkins server is now live on AWS. 🎉

---

### Step 6 — Get your EC2 Public IP

Go to AWS Console → EC2 → Instances → Jenkins-Server → copy Public IP.

```
Jenkins:  http://<PUBLIC-IP>:8080
Grafana:  http://<PUBLIC-IP>:3000
SSH:      ssh -i myjenkins.pem ec2-user@<PUBLIC-IP>
```

---

### Step 7 — terraform destroy (when done)

```bash
terraform destroy
```

Removes **everything** Terraform created. Stops AWS billing immediately.

```
Destroy complete! Resources: 9 destroyed.
```

---

## 🔁 Full Command Flow

```bash
terraform init      # Download plugins
terraform fmt       # Format code
terraform validate  # Check for errors
terraform plan      # Preview changes
terraform apply     # Deploy to AWS ✅
terraform destroy   # Tear down when done
```

---

## 🧠 Key Learnings From This Project

- Terraform reads all `.tf` files in a folder together —
  order of resources doesn't matter, it figures out dependencies
- `data` blocks fetch existing AWS info (like AMI IDs) —
  `resource` blocks create new things
- `terraform.tfstate` is critical — it tracks what's deployed.
  Never delete it manually
- If `terraform apply` fails halfway, run it again —
  Terraform is idempotent (safe to run multiple times)
- Always run `terraform destroy` after practice to avoid AWS charges

---

## ⚠️ Important Notes

```
🔐 Never commit AWS credentials to GitHub
🔐 Never commit terraform.tfstate to GitHub (add to .gitignore)
💰 t3.small costs money — destroy when not in use
🔑 Keep your myjenkins.pem key file safe — losing it = no SSH access
```

---

*Part of the Infrastructure Automation with Terraform project*
*by Naresh Prasad Yadav — [GitHub](https://github.com/mydevopsworld31)*
