
# Deployment Documentation

This document provides instructions on deploying the application using Terraform and Docker. It covers the setup and execution of the CI/CD pipelines in GitHub Actions.


## CI/CD Pipelines Overview

This project includes two main CI/CD pipelines:

- Terraform CI/CD Pipeline - Manages infrastructure deployment and validation using Terraform.
- Docker Build and Push Pipeline - Builds Docker images and pushes them to Amazon Elastic Container Registry (ECR).

#### Both pipelines are triggered automatically based on specific events in the GitHub repository.

### 1. Terraform CI/CD Pipeline

This pipeline validates and deploys infrastructure using Terraform. It triggers on push and pull_request events in the repository, specifically for changes within the terraform/ directory.

Pipeline Events:

1. Push to main, develop, or pp branches: Runs Terraform init, validate, and apply.
2. Pull Requests: Runs Terraform plan to show proposed changes.

#### How to Trigger the Pipeline

The pipeline will automatically run when:

- A change is pushed to the main, develop, or pp branches.
- A pull request is opened or updated that affects the terraform/ directory.
- A change is made in the terraform/ directory.

### 2. Docker Build and Push Pipeline

This pipeline builds Docker images from the prefect/ directory and pushes them to Amazon ECR. It triggers on push events to main, develop, or pp branches for changes in the prefect/ directory.

Pipeline Events:

1. Push to main, develop, or pp branches: Builds and pushes the Docker image with the commit hash tag or the branch name tag.

#### How to Trigger the Pipeline:

The pipeline will automatically run when:

- A change is pushed to the main, develop, or pp branches.
- A change is made in the prefect/ directory, which contains the Dockerfile.

### Conclusion

This document provides a comprehensive guide on deploying infrastructure and Docker images using Terraform and GitHub Actions. The pipelines automates the deployment process, ensuring that code changes are consistently and efficiently applied to your environment.