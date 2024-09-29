# GEIA-Infra
Global Environmental Impact Analyzer Infrastructure as Code with Terraform

## Overview
This repository contains Terraform configurations for deploying the Global Environmental Impact Analyzer (GEIA) infrastructure on Microsoft Azure. The infrastructure is designed to be cost-effective, utilizing free tier resources where possible.

## Resources Created
- Azure Functions (Consumption plan)
- Azure Blob Storage
- Azure SQL Database (Basic tier)
- Azure App Service (Free F1 tier)
- Azure Monitor (Application Insights)
- Azure Key Vault

## Cost Management
This infrastructure is designed to stay within Azure's free tier limits. A budget alert is set up to notify you if costs are approaching $1.

## Usage
1. Install Terraform
2. Clone this repository
3. Run `terraform init` to initialize Terraform
4. Set up your Azure credentials
5. Run `terraform plan` to see the changes that will be made
6. Run `terraform apply` to create the infrastructure

## Variables
Make sure to set the following variables:
- `sql_admin_password`: A secure password for the SQL Server admin
- `alert_email`: Your email address for budget alerts

## Note
Remember that free tier resources have limitations and may not be suitable for production workloads. Always monitor your usage and adjust as necessary.