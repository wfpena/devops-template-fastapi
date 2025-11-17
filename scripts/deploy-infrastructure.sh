#!/bin/bash

# Script to deploy infrastructure with Terraform
set -e

TERRAFORM_DIR="terraform"
ACTION=${1:-plan}

echo "🏗️  Terraform Infrastructure Deployment"
echo "========================================"
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform 1.6+"
    exit 1
fi

echo "✅ Terraform found: $(terraform version | head -n 1)"

# Navigate to terraform directory
cd $TERRAFORM_DIR

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "⚠️  terraform.tfvars not found. Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "📝 Please edit terraform.tfvars with your configuration"
    echo "   Then run this script again."
    exit 0
fi

# Initialize Terraform
echo ""
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo ""
echo "✅ Validating configuration..."
terraform validate

# Format check
echo ""
echo "📐 Checking format..."
terraform fmt -check || terraform fmt -recursive

# Run terraform command
echo ""
case $ACTION in
    plan)
        echo "📋 Running Terraform plan..."
        terraform plan
        ;;
    apply)
        echo "🚀 Applying Terraform configuration..."
        terraform plan -out=tfplan
        echo ""
        read -p "Do you want to apply these changes? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            terraform apply tfplan
            rm tfplan
            echo ""
            echo "✅ Infrastructure deployed successfully!"
            echo ""
            echo "📤 Saving outputs..."
            terraform output > ../infrastructure-outputs.txt
            echo "Outputs saved to infrastructure-outputs.txt"
            echo ""
            echo "🔑 Important: Save your GitHub Actions credentials:"
            echo "AWS_ACCESS_KEY_ID:"
            terraform output -raw github_actions_access_key_id
            echo ""
            echo "AWS_SECRET_ACCESS_KEY:"
            terraform output -raw github_actions_secret_access_key
            echo ""
        else
            echo "❌ Apply cancelled"
            rm tfplan
        fi
        ;;
    destroy)
        echo "🗑️  Destroying infrastructure..."
        terraform plan -destroy
        echo ""
        read -p "Are you sure you want to destroy all infrastructure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy
            echo "✅ Infrastructure destroyed"
        else
            echo "❌ Destroy cancelled"
        fi
        ;;
    output)
        echo "📤 Terraform outputs:"
        terraform output
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Usage: $0 [plan|apply|destroy|output]"
        exit 1
        ;;
esac

cd ..

