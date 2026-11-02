# 编译、下载和安装入口

完整首次配置和仓库命令见 IOS_WORKFLOW.md。必需：Git、Python 3.10+、PowerShell 7、已登录 gh、授权仓库和确认后的 Actions 预算。

| 脚本 | 参数/行为 |
|---|---|
| check-environment.ps1 | 只读检查工具、登录和 Apple 服务 |
| new-app.ps1 | 必填 -Name、-BundleId，拒绝覆盖 |
| publish-ios.ps1 | 必填 -Paths、-Message、-BillingChecked；提交选定路径并 push main |
| build-ios.ps1 | -Repo 可选；-App ALL/MyFirstApp；-Ref main；必需 -BillingChecked；-Wait 等待退出状态 |
| download-ipa.ps1 | -Repo 可选；-App MyFirstApp；-RunId 指定运行，默认最近成功 main 中有目标 App 的结果 |
| deploy-ios.ps1 | 必填 -Ipa；-Open 打开目录；可选 -SideloadlyPath 启动 GUI；不自动安装 |

手动查询：

```powershell
$gh = '.\.tools\gh\bin\gh.exe'
& $gh run list --workflow build-ios.yml --branch main
& $gh run view RUN_ID --log-failed
& $gh run watch RUN_ID --exit-status
pwsh -File scripts/download-ipa.ps1 -Repo OWNER/REPO -App MyFirstApp -RunId RUN_ID
```

所有脚本报错停止；不要把失败运行的 Artifact 日志当成可用 IPA。
多个提交路径在 PowerShell 7 会话中用数组：`& ./scripts/publish-ios.ps1 -Paths @('apps/MyFirstApp','docs') -Message 'Update app and docs' -BillingChecked`。
不要通过 `pwsh -File ... -Paths path1,path2` 传数组：原生命令边界会把它当作一个含逗号的路径。
build-ios.ps1 使用 GitHub 2026-03-10 REST API 返回的 run ID；服务版本不兼容时明确报错，不猜测其他运行。
Workflow push 自动发现所有 apps；dispatch 可指定一个。仅路径过滤内的 main 变更自动构建。
macos-15 预装 Xcode，打印版本和 SDK 进入日志；没有 brew 安装、第三方编译器或 Apple Secrets。
如 runner 默认 Xcode 变化导致回归，先查 runner-images 清单，在确认可用版本后固定 DEVELOPER_DIR 并记录实测。
Actions 的 checkout/upload-artifact 使用查证过的 v7 发布，固定完整 commit SHA。

构建流水线：项目生成 → Xcode Release iphoneos arm64 无签名 → plutil/lipo/otool → ditto Payload → Python ZIP/Plist/Mach-O → Artifact。
IPA 的内容来自 Xcode 产出的真实 `.app`。没有在 Windows 造一个 ZIP 当编译产物。
Windows 再验证 manifest 的 commit/run ID、SHA256 和内部可执行头；没有证书或有效 provisioning profile，须经 Sideloadly 签名。
下载通过后整理到 `artifacts/latest/MyFirstApp/MyFirstApp-unsigned.ipa`，原始按 RunId 的下载也保留供追溯。
单独 CRC/哈希不能证明来源安全；只下载自己审查过的仓库/提交。

费用控制：标准 runner、最多 20 分钟、并发取消旧运行、3 天保留。多个 App 同次顺序编译，规模增大后重新评估时间和额度。
这些控制不是零费用保证。公开/私有仓库、当前计划、存储费用与剩余额度按 GitHub Billing 页面核对，超额预算应设置为阻断。
没有执行付费开通或变更预算。首次未登录/未指定仓库时不执行云端构建。
