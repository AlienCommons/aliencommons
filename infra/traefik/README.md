# Traefik

Cloudflare is the public reverse proxy and terminates visitor TLS. Traefik
remains the host-local reverse proxy for Docker discovery, host and path routing,
and middleware. Cloudflare connects to Traefik over HTTPS using a Cloudflare
Origin CA certificate; Traefik does not run ACME or request Let's Encrypt
certificates.

Staging and production live in separate AWS member accounts and must not share a
host, proxy container, certificate files, or Docker network. Within each host,
the environment's public services and Traefik join the host-local external
`aliencommons-proxy` Docker network; application-internal traffic remains on the
Compose project's default network.

## Install the Origin CA certificate

Store the Origin CA certificate and private key as separate SSM `SecureString`
parameters in the workload account. Do not commit either value or pass it through
OpenTofu. On the deployment host, use its instance role to retrieve and validate
the pair:

```bash
sudo infra/deploy/stg/prepare-origin-certificates.sh \
  <certificate-parameter-name> \
  <private-key-parameter-name>
```

The script writes `/srv/aliencommons/origin-certs/tls.crt` with mode `0644` and
`tls.key` with mode `0600`. The directory is mounted read-only at
`/etc/traefik/certs`; the file provider loads the pair from
`infra/traefik/dynamic/tls.yml`. Re-run the script and restart Traefik when the
Origin CA certificate is rotated.

## Network and first-time setup

1. Confirm Cloudflare SSL/TLS mode is `Full (strict)` and every application DNS
   record is proxied.
2. Allow inbound TCP 443 only from Cloudflare's published origin-facing IP
   ranges. Do not expose ports 22 or 80; administer the host through AWS Systems
   Manager Session Manager.
3. Install the Origin CA certificate before starting Traefik.
4. Run `make proxy-check`, then `make proxy-up` before starting the staging or
   production Compose project.

A Cloudflare Origin CA certificate is intentionally not trusted by ordinary
browsers. Direct origin access must be blocked at the AWS security group; public
requests must pass through Cloudflare.

The dashboard is disabled. Traefik emits JSON application and access logs to
stdout, and its Docker socket mount is read-only. Shared TLS and response-header
policy lives under `infra/traefik/dynamic/`.
