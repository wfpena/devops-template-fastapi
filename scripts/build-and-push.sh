#!/bin/bash

# Script to build and push Docker image to ECR
set -e

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPOSITORY=${ECR_REPOSITORY:-eloquent-ai-app}
IMAGE_TAG=${1:-latest}

echo "🐳 Docker Build and Push to ECR"
echo "================================"
echo ""

# Check for required tools
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi

echo "✅ AWS CLI found: $(aws --version)"
echo "✅ Docker found: $(docker --version)"
echo ""

# Get ECR repository URL
echo "🔍 Getting ECR repository URL..."
ECR_URL=$(aws ecr describe-repositories \
    --repository-names $ECR_REPOSITORY \
    --region $AWS_REGION \
    --query 'repositories[0].repositoryUri' \
    --output text 2>/dev/null)

if [ -z "$ECR_URL" ]; then
    echo "❌ ECR repository '$ECR_REPOSITORY' not found in region $AWS_REGION"
    echo "   Please deploy infrastructure first using: ./scripts/deploy-infrastructure.sh apply"
    exit 1
fi

echo "✅ ECR Repository: $ECR_URL"
echo ""

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_URL

# Build Docker image
echo ""
echo "🏗️  Building Docker image..."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Tag image
echo ""
echo "🏷️  Tagging image..."
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_URL:$IMAGE_TAG
if [ "$IMAGE_TAG" != "latest" ]; then
    docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_URL:latest
fi

# Push to ECR
echo ""
echo "📤 Pushing to ECR..."
docker push $ECR_URL:$IMAGE_TAG
if [ "$IMAGE_TAG" != "latest" ]; then
    docker push $ECR_URL:latest
fi

echo ""
echo "✅ Image pushed successfully!"
echo ""
echo "Image: $ECR_URL:$IMAGE_TAG"
if [ "$IMAGE_TAG" != "latest" ]; then
    echo "Also tagged as: $ECR_URL:latest"
fi
echo ""
echo "🚀 To deploy this image, trigger the GitHub Actions workflow or run:"
echo "   aws ecs update-service --cluster eloquent-ai-app-cluster \\"
echo "       --service eloquent-ai-app-service --force-new-deployment \\"
echo "       --region $AWS_REGION"

