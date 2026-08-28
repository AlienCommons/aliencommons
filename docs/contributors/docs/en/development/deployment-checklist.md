# Deployment Checklist

## Confirm the AWS account boundary

AlienCommons uses one governance-only AWS Organizations management account and
two workload member accounts:

- the staging member account is under `Workloads/Stg`;
- the production member account is under `Workloads/Pro`.

Before provisioning or deploying, confirm the active AWS identity belongs to
the target member account. Never create application resources, S3 buckets, ECR
repositories, deployment roles, or runtime secrets in the management account.
Do not commit account IDs, root email addresses, role ARNs, or concrete bucket
names.

Staging and production deployments run on separate hosts in their respective
member accounts. They do not share Docker networks, Traefik instances, or
persistent volumes.

## Configure the application environment

Create the environment-specific local file from the matching tracked example:

```bash
cp env/.env.stg.example env/.env.stg  # staging host only
cp env/.env.pro.example env/.env.pro  # production host only
```

Replace every placeholder before starting the stack. The AWS media bucket and
custom domain must belong to the same member account as the deployment. Hosted
containers obtain AWS credentials from an IAM workload role; do not add access
keys to these files.

The AlienMark documentation deployment is disabled until the new staging S3
destination and GitHub OIDC role exist. To enable it, configure the `stg` GitHub
Environment with `AWS_STG_ACCOUNT_ID`, `AWS_STG_REGION`,
`AWS_STG_ROLE_TO_ASSUME`, and `AWS_STG_S3_BUCKET`, then set the repository
variable `AWS_DOCS_DEPLOY_ENABLED` to `true`. Scope the role's OIDC trust to the
repository's `stg` GitHub Environment and grant it access only to the staging
documentation destination.

## Configure Traefik

Before starting Traefik on a staging or production host, create its local
environment file from the tracked example:

```bash
cp env/.env.proxy.example env/.env.proxy
```

Open `env/.env.proxy` and replace `TRAEFIK_ACME_EMAIL` with a real operations
email address. The file is intentionally ignored by Git and must be configured
separately on the staging and production proxy hosts.

Confirm that the public DNS records point to the proxy host and that inbound TCP
ports 80 and 443 are reachable. Port 80 is required by the Let's Encrypt HTTP-01
challenge.

Validate and start the proxy before bringing up staging or production:

```bash
make proxy-check
make proxy-up
```

Traefik stores issued certificates in a host-local
`aliencommons-proxy_letsencrypt` Docker volume. Include the relevant volume in
each host's persistent-data backup plan, and do not copy it between accounts.
