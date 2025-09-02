# AWS Cross-Account VPC Peering Setup

This Terraform configuration sets up the necessary IAM roles and policies across two AWS accounts to enable an existing user in the primary account to assume a role in the secondary account with permissions to create VPC peering connections.

**Important**: This configuration assumes you have an existing IAM user in the primary account with the necessary VPC peering permissions. The configuration will only add the cross-account role assumption policy to this existing user.

## Account Structure

* **globomantics-tacowagon**: Primary account for deploying resources
* **globomantics-security**: Secondary account where cross-account role will be assumed

## Prerequisites

1. **AWS CLI configured** with profiles for both accounts
2. **Terraform** installed (version >= 1.0)
3. **Administrative access** to both AWS accounts
4. **Existing IAM user** in the primary account with necessary VPC peering permissions

## AWS Profile Setup

Create AWS profiles for both accounts using the AWS CLI:

```bash
aws configure --profile "globomantics-tacowagon"
aws configure --profile "globomantics-security"
```

## Configuration Files

This Terraform configuration includes:

- `versions.tf`: Provider version constraints
- `variables.tf`: Variable definitions with validation
- `main.tf`: Provider configuration and account validation
- `primary-account.tf`: Resources for the primary account
- `secondary-account.tf`: Resources for the secondary account
- `outputs.tf`: Important output values
- `terraform.tfvars.example`: Example variables file

## Deployment Instructions

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with the existing user and desired role name:
   ```hcl
   cross_account_role_name = "VPCPeeringCrossAccountRole"
primary_user_name       = "existing-user" # Name of existing IAM user in primary account
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the planned changes:**
   ```bash
   terraform plan -out="vpc.tfplan"
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply vpc.tfplan
   ```

## Resources Created

### Primary Account (globomantics-tacowagon)

- **IAM Policy**: `AssumeVPCPeeringCrossAccountRole` - Allows the existing user to assume the cross-account role
- **Policy Attachment**: Attaches the assume role policy to the existing IAM user

**Note**: This configuration assumes an existing IAM user with the necessary VPC peering permissions in the primary account.

### Secondary Account (globomantics-security)

- **IAM Role**: `VPCPeeringCrossAccountRole` - Cross-account role with VPC peering permissions
- **IAM Policy**: `VPCPeeringCrossAccountPermissions` - Comprehensive VPC peering permissions
- **IAM Policy**: `VPCPeeringCloudWatchLogs` - CloudWatch Logs permissions for monitoring

## Outputs

The configuration provides several important outputs:

- Existing IAM user and role ARNs

## Cleanup

To remove all created resources:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Profile not found**: Ensure AWS profiles are configured correctly
2. **Access denied**: Verify account permissions
