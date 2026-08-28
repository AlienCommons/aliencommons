# Traefik

Traefik terminates HTTPS on each staging or production deployment host. Staging
and production live in separate AWS member accounts and must not share a host,
proxy container, certificate volume, or Docker network. Within each host, the
environment's public services and Traefik join the host-local external
`aliencommons-proxy` Docker network; application-internal traffic remains on the
Compose project's default network.

## First-time setup

1. Copy `env/.env.proxy.example` to `env/.env.proxy` and set an email address
   monitored by the operators.
2. Point the public DNS records at the proxy host and allow inbound TCP ports
   80 and 443. Port 80 must remain reachable for the Let's Encrypt HTTP-01
   challenge and redirects all other requests to HTTPS.
3. Run `make proxy-check`, then `make proxy-up` on that environment's host
   before starting its staging or production Compose project.

Certificates are stored in a host-local `aliencommons-proxy_letsencrypt` Docker
volume, which survives container recreation and `make proxy-down`. Back up each
environment's volume with the rest of that host's persistent deployment data;
never copy the volume between the staging and production accounts.

The dashboard is disabled. Traefik emits JSON application and access logs to
stdout, and its Docker socket mount is read-only. Shared TLS and response-header
policy lives under `infra/traefik/dynamic/`.
