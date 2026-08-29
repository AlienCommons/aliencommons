# 部署待办

## 确认 AWS Account 边界

AlienCommons 使用一个只负责治理的 AWS Organizations Management Account，以及两个承载工作负载的 Member Account：

- 预发布 Member Account 位于 `Workloads/Stg`；
- 生产 Member Account 位于 `Workloads/Pro`。

创建资源或部署前，确认当前 AWS 身份属于目标 Member Account。不得在 Management Account 中创建应用资源、S3 bucket、ECR repository、部署 Role 或运行时秘密。不要将 Account ID、Root 邮箱、Role ARN 或真实 bucket 名称提交到仓库。

预发布和生产部署分别运行在各自 Member Account 的独立主机上，不共享 Docker network、Traefik 实例或持久化 volume。

## 配置应用环境

根据仓库中的对应示例创建环境专用的本地文件：

```bash
cp env/.env.stg.example env/.env.stg  # 仅在预发布主机执行
cp env/.env.pro.example env/.env.pro  # 仅在生产主机执行
```

启动服务前替换所有占位值。AWS 媒体 bucket 和自定义域名必须属于部署所在的同一个 Member Account。托管容器通过 IAM workload role 获取 AWS 凭据；不要把 Access Key 写入这些文件。预发布环境通过 `BACKEND_IMAGE`、`FRONTEND_IMAGE` 和 `ALIENMARK_IMAGE` 使用不可变的 ECR 镜像引用；部署工作流必须在启动 Compose 前填入固定到 digest 的引用。

预发布公网域名为：

- `stg.aliencommons.com`：Nuxt 与同源 `/api` 路由；
- `api.stg.aliencommons.com`：直接 API 与静态文件访问；
- `grafana.stg.aliencommons.com`：Grafana；
- `media.stg.aliencommons.com`：用户媒体；
- `docs.stg.aliencommons.com`：已部署文档。

在新的预发布 S3 目标和 GitHub OIDC Role 就绪前，AlienMark 文档部署默认停用。启用时，在 GitHub 的 `stg` Environment 中配置 `AWS_STG_ACCOUNT_ID`、`AWS_STG_REGION`、`AWS_STG_ROLE_TO_ASSUME` 和 `AWS_STG_S3_BUCKET`，然后将 repository variable `AWS_DOCS_DEPLOY_ENABLED` 设置为 `true`。该 Role 的 OIDC trust 必须限定到仓库的 `stg` GitHub Environment，并且只能访问预发布文档目标。

## 配置 Traefik

Cloudflare 终止访客 TLS，并把应用流量代理到 Traefik。将 Zone 设置为 `Full (strict)`，保持应用 DNS 记录为 Proxied，并安装覆盖环境域名的 Cloudflare Origin CA Certificate。Traefik 只加载这张静态证书，不运行 ACME，也不再向 Let's Encrypt 申请证书。

将 Origin CA Certificate 和私钥分别保存为目标 Workload Account 中的 SSM `SecureString`。不得提交证书值或私钥、写入普通环境文件，或通过 OpenTofu传递。启动 Traefik 前在主机上安装这一对材料：

```bash
sudo infra/deploy/stg/prepare-origin-certificates.sh \
  <certificate-parameter-name> \
  <private-key-parameter-name>
```

脚本会先验证证书、私钥及配对关系，再以原子方式写入 `/srv/aliencommons/origin-certs`；Traefik 只读挂载该目录。EC2 Security Group 的 TCP 443 入站规则只能允许 Cloudflare 官方 IP ranges。不要开放 22 或 80；主机管理使用 AWS Systems Manager Session Manager。

启动预发布或生产环境前，先校验并启动代理：

```bash
make proxy-check
make proxy-up
```

普通浏览器不信任 Cloudflare Origin CA Certificate，这是预期行为：源站直连已被阻止，公网请求必须经过 Cloudflare。轮换 Origin CA Certificate 后，重新运行安装脚本并重启 Traefik。
