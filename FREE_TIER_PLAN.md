# AWS Free Tier Deployment Plan - Notes CRUD App

## Architecture Overview (Free Tier Optimized)

```
Internet → ALB (Public) → EC2 (Public Subnet) → RDS (Private Subnet)
```

### ✅ What We'll Use (100% Free for 1st Year):

1. **VPC** - Always free
2. **2 Public Subnets** (Multi-AZ for ALB requirement)
3. **2 Private Subnets** (for RDS)
4. **Internet Gateway** - Always free
5. **Security Groups** - Always free
6. **ALB** - 750 hours/month free (covers 1 instance)
7. **EC2 t3.micro** (1 instance) - 750 hours/month free
8. **RDS db.t3.micro** - 750 hours/month free, 20GB storage
9. **Auto Scaling Group** - min=1, max=1 (no extra instances)

### ❌ What We'll REMOVE (to stay free):

1. ❌ **NAT Gateway** - Costs ~$32/month
2. ❌ **Elastic IP for NAT** - Not needed
3. ❌ **Route 53 + Domain** - Costs ~$12+/year
4. ❌ **ACM Certificate** - Requires domain

### 🔧 How We'll Access:

Instead of custom domain:
- Access via: **ALB DNS Name** (e.g., `notes-app-alb-123456.us-east-1.elb.amazonaws.com`)
- Protocol: **HTTP** (port 80) - No SSL needed
- Direct access to ALB which routes to EC2

---

## 🔐 Required Information

### Please provide these:

#### 1. AWS Credentials
```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1  # or your preferred region
```

#### 2. EC2 SSH Key Pair Name
- Do you already have an EC2 key pair in AWS?
- If yes, provide name: `your-keypair-name`
- If no, I'll create one for you

#### 3. Database Password
```bash
DB_PASSWORD=YourSecurePassword123!
```

#### 4. GitHub Repository (for deployment)
```bash
GITHUB_USERNAME=your-username
GITHUB_REPO=your-repo-name
```

---

## 📝 Deployment Steps

### Phase 1: Cleanup & Preparation
- [x] Remove unnecessary files
- [ ] Update Terraform for free tier
- [ ] Remove NAT Gateway dependency
- [ ] Remove ACM/Route53 modules
- [ ] Configure for HTTP only (no HTTPS)

### Phase 2: Packer AMI Build
- [ ] Build custom AMI with Node.js & app
- [ ] Install dependencies
- [ ] Configure PM2

### Phase 3: Terraform Deployment
- [ ] Deploy VPC & Networking
- [ ] Deploy Security Groups
- [ ] Deploy RDS Database
- [ ] Deploy ALB
- [ ] Deploy EC2 via Auto Scaling Group

### Phase 4: Application Configuration
- [ ] Initialize database schema
- [ ] Configure environment variables
- [ ] Test application

---

## 💰 Cost Breakdown (1st Year Free Tier)

| Resource | Free Tier Limit | After Free Tier |
|----------|----------------|-----------------|
| EC2 t3.micro | 750 hrs/month | ~$8-10/month |
| RDS db.t3.micro | 750 hrs/month | ~$15-20/month |
| ALB | 750 hrs/month | ~$16-20/month |
| Data Transfer | 15GB/month | $0.09/GB |
| **Total** | **$0/month** | **~$40-50/month** |

**Note:** Stay within 750 hours/month = 31.25 days (one instance only)

---

## 🚀 Next Steps

Reply with your:
1. AWS Access Key ID and Secret Access Key
2. Preferred AWS Region (e.g., us-east-1, eu-west-1)
3. EC2 Key Pair name (or say "create new")
4. Database password
5. GitHub username

Then I'll start the deployment!
