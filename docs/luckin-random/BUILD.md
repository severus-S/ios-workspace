# 构建、源码交付和安装

状态：2026-11-05，尚未触发本 App 云端编译；没有 LuckinRandom IPA，不能用 MyFirstApp IPA 替代。

## 本地验证

```powershell
cd D:/CodexWorking/iOS
python scripts/project.py LuckinRandom
python scripts/selftest.py
cd services/luckin-random
npm ci --ignore-scripts
npm test
# 可选，独立运行模拟 MCP；仅回环、无真实账号
npm run mock:mcp
```

Node 22.14+；本次 TypeScript 编译及 27 项 Mock 自动测试通过。iOS 还有 6 项 Swift 核心测试，需 macOS Swift 执行，本机未运行。
Swift 文件做过语法树解析，未替代 Xcode 类型检查、SDK 链接或真机布局验证。

## 云端编译

已有私有远程 `severus-S/ios-workspace`，继续使用既有 build-ios.yml，macos-15、20 分钟超时、3 天 Artifact 保留。
本次只增补后端 Mock 测试步骤、services 路径触发、可选 Swift Package 测试和中文显示名。没有重做流水线，没有购买服务。

本次尝试读取 GitHub 账单 API，返回 404 且提示缺少 user scope，无法读取当前剩余额度。未扩大权限、未推送、未 dispatch；需用户核对本次免费额度和超额阻断预算后继续。
2026-11-05 后续：用户已明确确认本次额度，可继续云端构建。Token 在手机 App 内填写，构建无需瑞幸 Token 或 Apple 凭据。
工作区原有无线诊断/文档已有未提交变更，禁止直接 git add . 将它们与新 App 混提。

确认后只提交审查过的本次路径：

本机 main 有 23 条无关诊断提交尚未推送，本次改用从 origin/main 创建的独立 `codex/luckin-random-build` 分支，只同步本 App 相关代码和文档，再用已有 build-ios.ps1 的 -Ref 参数触发。以下 main 发布命令仅适用于日后已整合并审查的 main，当前不执行。

```powershell
# PowerShell 会话内执行；不要直接整库 add
$paths = @('apps/LuckinRandom','services/luckin-random','docs/luckin-random',
  'scripts/project.py','scripts/ci_build.py','scripts/package-luckin.py',
  '.github/workflows/build-ios.yml','.gitignore','README.md')
# 根 docs/VALIDATION.md、PROJECT_HISTORY.md 混有原有修改，须分别审查再决定是否加入
& ./scripts/publish-ios.ps1 -Paths $paths -Message 'Add Luckin Random native app and safe MCP backend' -BillingChecked
# push 已触发时不要重复 dispatch。若有需要：
# pwsh -File scripts/build-ios.ps1 -App LuckinRandom -BillingChecked -Wait
```

若编译失败先读根 TROUBLESHOOTING.md 和准确 run ID 日志。成功后：

```powershell
pwsh -File scripts/download-ipa.ps1 -App LuckinRandom -RunId <成功运行ID>
# 稳定路径 artifacts/latest/LuckinRandom/LuckinRandom-unsigned.ipa
```

核对该运行的 commit、version、Bundle ID、SHA256 和未签名状态。只有真正 xcodebuild 成功并打包的 IPA 才能进入安装环节。

## 签名、安装、续签、版本更新

无需向代理提供 Apple 签名证书或密码。IPA 编译后由用户在 Sideloadly 本机界面输入自己 Apple ID 并完成签名，手机物理操作同样由用户完成。
遵循根 IOS_WORKFLOW.md 与 SIDELOAD_AND_RENEW.md。新 App 源码 Bundle ID 固定 `com.sjx13.ios.luckinrandom`；Sideloadly 有效签名 ID 若有后缀，后续继续同一身份/设置。
先检查免费账号的已安装 App 和 App ID 配额，不卸载已有 App 来“试一下”。安装完成需用户确认版本、界面、深色模式、备份恢复、结束进程重开、快捷指令。
后续版本覆盖安装，不先卸载；数据保持和 iPhone 18 Pro/iOS 27.2 兼容性均需真机证据。
Daemon 续签与发布新版独立：续签不会自动下载代码更新。无线发现可用不代表无线刷新或自然续签已验证。

## 源码包

```powershell
python scripts/package-luckin.py
```

输出 `artifacts/LuckinRandom-source-0.1.0.zip` 与 `.sha256`。这是包含原生工程、后端、迁移、Mock、测试、文档和复用构建脚本的**源码包**，不是 IPA。
排除 node_modules、dist、.env、.local、Token、登录资料和原有无线诊断工具。下载依赖后能运行后端测试；iOS 仍需真实云端编译及本机签名安装。
