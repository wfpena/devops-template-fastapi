.PHONY: help install test lint format run docker-build docker-run clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	pip install -r requirements.txt

test: ## Run tests
	pytest tests/ -v --cov=. --cov-report=html --cov-report=term

lint: ## Run linting
	flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

format: ## Format code with black
	black .

format-check: ## Check code formatting
	black --check .

run: ## Run the application locally
	python app.py

docker-build: ## Build Docker image
	docker build -t eloquent-ai-app:latest .

docker-run: ## Run Docker container
	docker run -p 8080:8080 -e APP_VERSION=1.0.0 -e ENVIRONMENT=local eloquent-ai-app:latest

terraform-init: ## Initialize Terraform
	cd terraform && terraform init

terraform-plan: ## Run Terraform plan
	cd terraform && terraform plan

terraform-apply: ## Apply Terraform configuration
	cd terraform && terraform apply

terraform-destroy: ## Destroy Terraform infrastructure
	cd terraform && terraform destroy

clean: ## Clean up build artifacts
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	rm -rf htmlcov/
	rm -rf .coverage
	rm -rf build/
	rm -rf dist/

setup-githooks: ## Setup git hooks
	@echo "#!/bin/sh" > .git/hooks/pre-commit
	@echo "make format-check" >> .git/hooks/pre-commit
	@echo "make lint" >> .git/hooks/pre-commit
	@echo "make test" >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Git hooks installed"

