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
- VPC with public/private subnets across 2 AZs (us-east-1a, us-east-1b)
- Application Load Balancer (cross-AZ)
- ECS Fargate cluster with 2 task instances
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

## Design Decisions & Trade-offs

### Key Decisions

**Fargate over EC2**: Chose serverless containers for zero server management and automatic scaling. Trade-off: ~20% more expensive than EC2 but significantly less operational overhead.

**Multi-AZ Deployment**: Deployed across 2 availability zones for high availability. Trade-off: Doubles NAT Gateway costs ($65/month) but provides resilience against AZ failures.

**Private Subnets for ECS**: Tasks run in private subnets with no direct internet access. Trade-off: Requires NAT Gateways ($$$) but significantly improves security posture.

**Application Load Balancer**: Chose ALB for HTTP/HTTPS routing and health checks. Trade-off: More expensive than NLB but provides better application-layer features.

**Local Terraform State**: Used local state files for simplicity. Trade-off: Not suitable for team collaboration (would use S3 + DynamoDB locking in production).

**GitHub Actions over Jenkins**: Native GitHub integration, no infrastructure to manage. Trade-off: Less flexible than self-hosted Jenkins but much simpler for solo/small teams.

**Direct AWS Credentials**: Used IAM user access keys for GitHub Actions. Trade-off: Requires manual rotation vs OIDC (OpenID Connect) which is more secure but complex to set up.

### What I'd Do Differently With More Time

**Security Enhancements**:
- Implement HTTPS with ACM certificate and Route 53 custom domain
- Add AWS WAF for DDoS protection and request filtering
- Migrate to GitHub Actions OIDC for keyless authentication
- Use AWS Secrets Manager for sensitive environment variables
- Enable GuardDuty and Security Hub for threat detection

**Production Readiness**:
- Move Terraform state to S3 with DynamoDB locking for team collaboration
- Implement blue/green deployments with CodeDeploy
- Add comprehensive integration and load testing (Locust/k6)
- Set up proper alerting with PagerDuty/SNS
- Implement proper backup and disaster recovery procedures

**Observability**:
- Add distributed tracing with X-Ray or OpenTelemetry
- Implement structured logging with custom metrics
- Create Grafana dashboards for real-time monitoring
- Add application performance monitoring (APM)

**Cost Optimization**:
- Use VPC endpoints to eliminate NAT Gateway data transfer costs
- Implement Fargate Spot for non-critical workloads (70% savings)
- Add auto-scaling policies based on actual traffic patterns
- Evaluate single-AZ for dev/staging environments

**Development Experience**:
- Add pre-commit hooks for linting and testing
- Implement branch protection rules and required PR reviews
- Add automatic dependency updates with Dependabot
- Create ephemeral preview environments for PRs

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
