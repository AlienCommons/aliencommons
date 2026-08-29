# Staging Infrastructure

AlienCommons provisions staging from `infra/opentofu/environments/stg`. The
configuration must run only against the workload member account under
`Workloads/Stg`; the AWS Organizations management account is governance-only.

## Ownership boundary

OpenTofu owns the staging VPC and host, origin firewall, ECR repositories,
private S3 buckets, CloudFront distributions, AWS-managed ACM certificate,
application DNS records, and GitHub OIDC roles. It intentionally does not own
the state bucket, Organizations structure, budgets, Cloudflare zone-wide SSL
settings, Advanced Edge Certificate, or Origin CA certificate values.

The Origin CA certificate and private key remain in two pre-created SSM
`SecureString` parameters. OpenTofu receives only their parameter names so the
secret values never enter state.

## Bootstrap once from a trusted workstation

The first apply cannot run in GitHub Actions because it creates the GitHub OIDC
provider and roles that CI will assume. Follow `infra/opentofu/README.md` using
an AWS Identity Center profile for staging. Keep the real account ID, state
bucket name, Cloudflare Zone ID, and token in ignored local configuration or
the current shell, never in Git.

Before applying, review the plan and confirm:

- the AWS caller is the staging member account;
- inbound access is TCP 443 from Cloudflare IP ranges only;
- ports 22 and 80 are absent;
- application records are proxied and ACM validation records are DNS-only;
- all S3 buckets remain private; and
- no certificate or private-key value appears in the plan.

If a managed hostname already has a Cloudflare DNS record, import the intended
record into state or remove it only after proving it is obsolete. Do not let a
first apply overwrite an unknown record.

## Hand control to GitHub Actions

After the local apply succeeds, copy the two role ARN outputs directly into the
GitHub `stg` Environment variables expected by the infrastructure and deployment
workflows. Keep the account, region, state bucket, and Cloudflare Zone ID as
environment variables, and the Cloudflare token as an environment secret. Also
store the GitHub organization and repository numeric IDs as environment
variables; IAM uses them to bind trust to GitHub's immutable OIDC subject.

The `Stg Infrastructure` workflow is manual-only. Run `plan` first and review it.
Use `apply` only for that reviewed revision and enter the required confirmation
text. The workflow serializes staging infrastructure runs and never uploads the
saved plan as an artifact.

## After provisioning

Use Systems Manager Session Manager instead of SSH. Install the two Origin CA
materials from SSM on the host, publish digest-pinned application images to ECR,
and then start Traefik and the staging application stack. Public traffic must
continue through Cloudflare in `Full (strict)` mode.
