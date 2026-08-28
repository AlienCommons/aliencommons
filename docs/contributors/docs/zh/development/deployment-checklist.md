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

启动服务前替换所有占位值。AWS 媒体 bucket 和自定义域名必须属于部署所在的同一个 Member Account。托管容器通过 IAM workload role 获取 AWS 凭据；不要把 Access Key 写入这些文件。

在新的预发布 S3 目标和 GitHub OIDC Role 就绪前，AlienMark 文档部署默认停用。启用时，在 GitHub 的 `stg` Environment 中配置 `AWS_STG_ACCOUNT_ID`、`AWS_STG_REGION`、`AWS_STG_ROLE_TO_ASSUME` 和 `AWS_STG_S3_BUCKET`，然后将 repository variable `AWS_DOCS_DEPLOY_ENABLED` 设置为 `true`。该 Role 的 OIDC trust 必须限定到仓库的 `stg` GitHub Environment，并且只能访问预发布文档目标。

## 配置 Traefik

在预发布或生产主机上启动 Traefik 前，根据仓库中的示例创建本地环境文件：

```bash
cp env/.env.proxy.example env/.env.proxy
```

打开 `env/.env.proxy`，将 `TRAEFIK_ACME_EMAIL` 替换为真实且有人维护的运维邮箱。该文件已被 Git 忽略，因此预发布与生产代理主机都需要分别配置。

确认公开 DNS 记录已经指向代理主机，并且 TCP 端口 80 和 443 可以从公网访问。Let's Encrypt 的 HTTP-01 验证需要使用端口 80。

启动预发布或生产环境前，先校验并启动代理：

```bash
make proxy-check
make proxy-up
```

Traefik 签发的证书保存在主机本地的 `aliencommons-proxy_letsencrypt` Docker volume 中。每台主机的持久化数据备份方案都需要包含对应 volume，且不得在两个 Account 之间复制该 volume。
