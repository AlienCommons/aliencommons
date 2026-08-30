# 预发布基础设施

AlienCommons 通过 `infra/opentofu/environments/stg` 创建预发布基础设施。该配置只能作用于
`Workloads/Stg` 下的 Workload Member Account；AWS Organizations Management Account 只负责治理。

## 管理边界

OpenTofu 管理预发布 VPC 与主机、源站防火墙、ECR repositories、私有 S3 buckets、CloudFront
distributions、AWS 管理的 ACM certificate、应用 DNS records 和 GitHub OIDC roles。它不会管理
state bucket、Organizations 结构、Budget、Cloudflare Zone 级 SSL 设置、Advanced Edge
Certificate，也不会管理 Origin CA certificate 的内容。

Origin CA certificate、private key 和应用运行时 Secrets 都保存在预先创建的 SSM
`SecureString` 中。OpenTofu 只接收 parameter name，secret value 不会进入 state；EC2
runtime role 也只能读取清单中明确列出的预发布参数。

## 在可信电脑上执行一次 Bootstrap

首次 apply 不能从 GitHub Actions 运行，因为它本身会创建 CI 需要 assume 的 GitHub OIDC
provider 和 roles。使用预发布 Account 的 AWS Identity Center profile，并按照
`infra/opentofu/README.md` 操作。真实 Account ID、state bucket name、Cloudflare Zone ID 和
token 只能存在于被忽略的本地配置或当前 shell 中，不得进入 Git。

apply 前检查完整 plan，并确认：

- 当前 AWS caller 属于预发布 Member Account；
- 入站只允许 Cloudflare IP ranges 访问 TCP 443；
- 不存在 22 和 80 端口；
- 应用 DNS records 为 Proxied，ACM validation records 为 DNS only；
- 所有 S3 buckets 保持私有；
- plan 中没有 certificate 或 private-key value。

如果受管 hostname 已有 Cloudflare DNS record，应先将目标 record import 进 state；只有确认它已
废弃后才可删除。首次 apply 不得直接覆盖来源不明的 record。

## 将控制权交给 GitHub Actions

本地 apply 成功后，把两个 role ARN outputs 直接写入 GitHub `stg` Environment 中对应的
infrastructure 和 deployment workflow variables。Account、region、state bucket 和 Cloudflare
Zone ID 保持为 Environment variables；Cloudflare token 保持为 Environment secret。同时把 GitHub
Organization 和 Repository 的数字 ID 保存为 Environment variables；IAM 使用它们绑定 GitHub 的
不可变 OIDC subject。

`Stg Infrastructure` workflow 只能手动触发。先运行 `plan` 并完成检查；只有针对同一份已检查
revision 才运行 `apply`，并输入要求的确认文字。Workflow 会串行执行预发布基础设施操作，也不会
把保存的 plan 上传为 artifact。

## 创建资源之后

使用 Systems Manager Session Manager 管理主机，不使用 SSH。手动触发的 `Stg Application:
Deploy` workflow 只能从 `dev` 运行，并要求输入 `deploy-stg` 确认文本。它向 ECR 发布固定到
digest 的应用镜像，把带 checksum 的部署 bundle 上传到私有 deployment bucket，再通过 SSM Run
Command 调用主机。

主机上的部署脚本会直接从 SSM 读取六项应用 Secrets，生成仅 root 可读的 `0600` 运行时环境文件，
安装并校验 Origin CA 材料，拉取不可变镜像，执行 migrations 与 static collection，并等待服务通过
健康检查。Secret value 不会进入 bundle，也不会返回 GitHub Actions。最后 workflow 会验证
Cloudflare `Full (strict)`、确认源站无法直连，并执行公网 smoke checks。只有主机侧检查全部通过后
才会切换 `current` release 链接；更新失败时会尽力恢复上一组容器。数据库 migration 不会自动
回滚，因此预发布 migration 必须与上一版应用镜像保持向后兼容。
