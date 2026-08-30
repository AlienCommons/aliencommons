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

For local or production operation, create the environment-specific file from
the matching tracked example:

```bash
cp env/.env.pro.example env/.env.pro  # production host only
```

Staging does not use a manually maintained environment file. Store its Django,
PostgreSQL, Redis, Grafana, and SES credentials as separate SSM `SecureString`
parameters under `/aliencommons/stg/app/`. The staging deployment script reads
those parameters on the EC2 host and atomically creates a root-owned `0600`
`env/.env.stg` file. Never put staging secret values in GitHub variables,
deployment bundles, or OpenTofu inputs.

For manually managed environments, replace every placeholder before starting
the stack. The AWS media bucket and
custom domain must belong to the same member account as the deployment. Hosted
containers obtain AWS credentials from an IAM workload role; do not add access
keys to these files. Staging uses immutable ECR image references for
`BACKEND_IMAGE`, `FRONTEND_IMAGE`, and `ALIENMARK_IMAGE`; the deployment workflow
must populate digest-pinned references before Compose is started.

The staging public hostnames are:

- `stg.aliencommons.com` for Nuxt and the same-origin `/api` route;
- `api.stg.aliencommons.com` for direct API and static-file access;
- `grafana.stg.aliencommons.com` for Grafana;
- `media.stg.aliencommons.com` for user media;
- `docs.stg.aliencommons.com` for the deployed documentation.

The AlienMark documentation deployment is disabled until the new staging S3
destination and GitHub OIDC role exist. To enable it, configure the `stg` GitHub
Environment with `AWS_STG_ACCOUNT_ID`, `AWS_STG_REGION`,
`AWS_STG_ROLE_TO_ASSUME`, and `AWS_STG_S3_BUCKET`, then set the repository
variable `AWS_DOCS_DEPLOY_ENABLED` to `true`. Scope the role's OIDC trust to the
repository's `stg` GitHub Environment and grant it access only to the staging
documentation destination.

The application deployment uses the `AWS_STG_ROLE_TO_ASSUME` Environment
variable and requires no long-lived AWS credentials. Trigger `Stg Application:
Deploy` from `dev`, enter `deploy-stg`, and review the SSM deployment output and
the final smoke checks before treating the release as successful.

## Configure Traefik

Cloudflare terminates visitor TLS and proxies application traffic to Traefik.
Set the zone to `Full (strict)`, keep application records proxied, and install a
Cloudflare Origin CA certificate covering the environment's hostnames. Traefik
loads that static certificate and does not run ACME or request a Let's Encrypt
certificate.

Store the Origin CA certificate and private key as separate SSM `SecureString`
parameters in the target workload account. Do not commit their values, put them
in a normal environment file, or pass them through OpenTofu. Install the pair on
the host before starting Traefik:

```bash
sudo infra/deploy/stg/prepare-origin-certificates.sh \
  <certificate-parameter-name> \
  <private-key-parameter-name>
```

The script validates the certificate and key before atomically installing them
under `/srv/aliencommons/origin-certs`. Traefik mounts that directory read-only.
The EC2 security group must allow inbound TCP 443 only from Cloudflare's
published IP ranges. Do not expose ports 22 or 80; use AWS Systems Manager
Session Manager for host access.

Validate and start the proxy before bringing up staging or production:

```bash
make proxy-check
make proxy-up
```

Cloudflare Origin CA certificates are not trusted by ordinary browsers. This is
expected: direct origin access is blocked, and public requests must pass through
Cloudflare. Re-run the installation script and restart Traefik when the Origin
CA certificate is rotated.
