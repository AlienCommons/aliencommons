# OpenTofu infrastructure

OpenTofu manages AlienCommons workload infrastructure. The first root module is
staging-only and targets the dedicated AWS member account under `Workloads/Stg`.
Never run it with management-account or production credentials.

## Management boundary

OpenTofu manages:

- the staging VPC, subnet, origin security group, Elastic IP, and EC2 host;
- application ECR repositories and runtime IAM;
- private media, documentation, and deployment-artifact buckets;
- CloudFront OAC distributions and their AWS-managed ACM certificate;
- proxied Cloudflare DNS records and ACM validation records;
- separate GitHub infrastructure and deployment OIDC roles.

OpenTofu does not manage:

- the manually bootstrapped state bucket;
- Cloudflare Advanced Edge Certificates, Origin CA certificates, Total TLS, or
  zone-wide SSL settings;
- the values stored in SSM `SecureString` parameters;
- AWS Organizations, OUs, member accounts, Identity Center, or budgets.

## Required local configuration

Install OpenTofu 1.12.1 and AWS CLI v2. Configure an AWS Identity Center profile
for the staging member account. Keep the Cloudflare token in a password manager
and export it only for the current shell.

Create ignored local configuration from the example:

```bash
cd infra/opentofu/environments/stg
cp terraform.tfvars.example terraform.tfvars
```

Replace every placeholder in `terraform.tfvars`. If the two existing Origin CA
`SecureString` paths differ from the defaults, override their names only. Never
put either secret value in a `.tfvars` file.

Create the ignored `backend.stg.hcl`:

```hcl
bucket = "replace-with-the-existing-staging-state-bucket"
```

Authenticate and initialize:

```bash
aws sso login --profile <staging-profile>
export AWS_PROFILE=<staging-profile>
export AWS_REGION=ap-southeast-2
export CLOUDFLARE_API_TOKEN=<token-from-password-manager>

tofu init -backend-config=backend.stg.hcl
tofu fmt -check -recursive ../..
tofu validate
tofu plan -out=stg.tfplan
```

Review the complete plan before applying. In particular, verify that:

- the caller account is the staging member account;
- only the ACM certificate uses `us-east-1`;
- ingress contains Cloudflare IPv4 ranges on TCP 443 and no ports 22 or 80;
- application DNS records are proxied, while ACM validation records are not;
- all S3 buckets block public access;
- no Origin CA certificate or private-key value appears in the plan.

Do not apply a saved plan after its credentials, code, or reviewed inputs have
changed. Plan files may contain sensitive data and must not be committed or
uploaded as CI artifacts.

## First apply and GitHub OIDC bootstrap

The first apply must run locally with the staging Identity Center profile. It
creates the GitHub OIDC provider and roles required by the CI workflow. After a
successful apply, retrieve individual sensitive outputs explicitly and add them
to the GitHub `stg` Environment without copying them into source files.

At minimum, configure:

- `AWS_STG_TOFU_ROLE_TO_ASSUME` from `infrastructure_role_arn`;
- `AWS_STG_ROLE_TO_ASSUME` from `deploy_role_arn`;
- `AWS_STG_ACCOUNT_ID` and `AWS_STG_OPENTOFU_STATE_BUCKET` from the existing
  bootstrap configuration.

The workflow in `.github/workflows/stg-infrastructure.yml` is manual-only. Its
apply path requires the exact confirmation text `apply-stg`; there is no push or
pull-request-triggered apply.

## Existing Cloudflare records

If any target hostname or ACM validation record already exists, the Cloudflare
API returns a conflict instead of adopting it automatically. Inspect the record,
then either remove a genuinely obsolete record or import the intended record
into OpenTofu state. Never delete an active production or email-related record.

An AWS account can have only one GitHub Actions OIDC provider for the standard
token URL. If staging already has one, import it into the module address before
the first apply instead of trying to create a duplicate.
