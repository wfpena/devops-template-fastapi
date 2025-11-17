# DevOps Technical Challenge

FastAPI application on AWS ECS with Terraform and GitHub Actions CI/CD.

## Features

- ✅ Multi-AZ ECS deployment with Fargate
- ✅ Complete Terraform IaC
- ✅ GitHub Actions CI/CD pipeline
- ✅ CloudWatch monitoring and alarms
- ✅ Automated testing and linting
- ✅ Auto-rollback on failure

## Architecture

**Infrastructure**: VPC (multi-AZ) → ALB → ECS Fargate (private subnets) → ECR + CloudWatch + IAM

**Components**:
- VPC with public/private subnets across 2 AZs
- Application Load Balancer
- ECS Fargate cluster (2 tasks)
- ECR for Docker images
- CloudWatch logs and alarms
- IAM roles with least-privilege

## Prerequisites

- AWS Account with admin permissions
- AWS CLI v2.x, Terraform 1.6+, Docker, Git
- Configure AWS: `aws configure`

## Quick Start

**Local testing**:
```bash
pip install -r requirements.txt
python app.py
curl http://localhost:8080/health
```

**Docker testing**:
```bash
docker build -t app .
docker run -p 8080:8080 app
```

## Deployment

```bash
# 1. Deploy infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

# 2. Build and push Docker image
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker build -t app .
docker tag app:latest $ECR_URL:latest
docker push $ECR_URL:latest

# 3. Wait ~3 minutes for ECS tasks to start
terraform output alb_url
curl $(terraform output -raw alb_url)/health

# 4. Destroy when done
terraform destroy
```

**For CI/CD**: Add GitHub secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) from `terraform output`

## CI/CD Pipeline

**GitHub Actions** automatically: lints → tests → builds Docker → pushes to ECR → deploys to ECS → rolls back on failure.

Triggered on push to `main`.

## Security

- Private subnets for ECS (no direct internet)
- Security groups with least-privilege
- IAM roles for tasks and execution
- ECR encryption and image scanning
- Multi-stage Docker builds

**For production**: Add HTTPS/ACM, WAF, Secrets Manager, OIDC for GitHub Actions

## Monitoring

**CloudWatch** logs at `/ecs/eloquent-ai-app`, 3 alarms (CPU, Memory, Health), Container Insights enabled.

View logs: `aws logs tail /ecs/eloquent-ai-app --follow`

## Design Decisions

- **Fargate**: No server management, simpler than EC2
- **Multi-AZ**: HA at ~2x cost (NAT Gateways)
- **Private subnets**: Better security
- **ALB**: HTTP/HTTPS routing vs NLB
- **Local Terraform state**: Simpler for demo (use S3 for production)

## Cost

~$115/month: NAT Gateways ($65), ALB ($20), Fargate ($25), CloudWatch ($5)

Run `terraform destroy` to stop charges.

## Troubleshooting

```bash
# Check ECS service
aws ecs describe-services --cluster eloquent-ai-app-cluster --services eloquent-ai-app-service

# View logs
aws logs tail /ecs/eloquent-ai-app --follow

# Check target health
aws elbv2 describe-target-health --target-group-arn <ARN>
```

# Demo update
