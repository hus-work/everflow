Terraform Environment Variables
Ensure the following environment variables are configured in the pipeline settings or Azure Key Vault:

ARM_CLIENT_ID
ARM_CLIENT_SECRET
ARM_SUBSCRIPTION_ID
ARM_TENANT_ID
GITHUB_TOKEN
This setup enables the pipeline to decide the deployment environment based on the environment parameter, run the Terraform plan, wait for manual validation, and then apply the plan.