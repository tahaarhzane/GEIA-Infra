# Global Environmental Impact Analyzer (GEIA) Infrastructure

## Table of Contents
1. [Project Overview](#project-overview)
2. [Infrastructure Components](#infrastructure-components)
3. [Prerequisites](#prerequisites)
4. [Setup Instructions](#setup-instructions)
5. [Infrastructure Details](#infrastructure-details)
6. [Security Considerations](#security-considerations)
7. [Cost Management](#cost-management)
8. [Monitoring and Maintenance](#monitoring-and-maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)
11. [Legal](#legal)

## Project Overview
The Global Environmental Impact Analyzer (GEIA) is a cloud-based system designed to process and analyze environmental data. This repository contains the Infrastructure as Code (IaC) implementation using Terraform to deploy the necessary Azure resources for GEIA.

### Key Features
- Serverless computing with Azure Functions
- Scalable data storage using Azure Blob Storage
- Relational database capabilities with Azure SQL Database
- Web application hosting via Azure App Service
- Comprehensive monitoring through Azure Monitor and Application Insights
- Secure secret management with Azure Key Vault

## Infrastructure Components
- **Azure Resource Group**: Logical container for all GEIA resources
- **Azure Functions**: Serverless compute for data processing tasks
- **Azure Blob Storage**: For storing raw and processed environmental data
- **Azure SQL Database**: Relational database for structured data storage
- **Azure App Service**: Hosts the GEIA web application
- **Azure Monitor & Application Insights**: For monitoring and diagnostics
- **Azure Key Vault**: Secure storage of sensitive information

## Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) (version 0.12 or later)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- An active Azure subscription
- [Git](https://git-scm.com/downloads) for version control

## Setup Instructions
1. Clone the repository:
   ```
   git clone https://github.com/your-username/geia-infra.git
   cd geia-infra
   ```

2. Log in to Azure:
   ```
   az login
   ```

3. Initialize Terraform:
   ```
   terraform init
   ```

4. Review and modify the `variables.tf` file to customize your deployment.

5. Plan the Terraform deployment:
   ```
   terraform plan -out=tfplan
   ```

6. Apply the Terraform configuration:
   ```
   terraform apply tfplan
   ```

## Infrastructure Details

### Resource Naming Convention
All resources follow the naming convention: `{prefix}-{resource-type}-{random-string}`

### Azure Functions
- Consumption plan for cost-effectiveness
- Linked to a dedicated storage account

### Azure Blob Storage
- Two containers: "raw-data" and "processed-data"
- Cool access tier for cost optimization

### Azure SQL Database
- Basic tier for development purposes
- Randomly generated admin password stored in Key Vault

### Azure App Service
- Free F1 tier for development
- Configured for Python 3.8 runtime

### Azure Key Vault
- Stores sensitive information like database credentials
- Configured with access policies for secure operations

## Security Considerations
- All storage containers are set to private access
- SQL Server admin password is randomly generated
- Secrets are stored in Azure Key Vault
- Resource access is controlled via Azure Active Directory

## Cost Management
- Budget alert set to $1 to stay within free tier limits
- Cool access tier used for blob storage
- Consumption plan for Azure Functions

## Monitoring and Maintenance
- Azure Monitor is configured for basic monitoring
- Application Insights provides deep insights into application performance
- Regular review of logs and metrics is recommended

## Troubleshooting
- Check Azure Portal for resource status and logs
- Review Terraform logs for deployment issues
- Ensure Azure CLI is authenticated correctly

## Contributing
Contributions to the GEIA infrastructure are welcome. Please follow these steps:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Legal
This project is proprietary and confidential. Unauthorized copying, distribution, or use of this project, via any medium, is strictly prohibited. All rights reserved.

For questions or permissions, please contact the project maintainer.