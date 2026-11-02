# 可复用 iOS 开发工作区

工作区根目录就是 `D:\CodexWorking\iOS`，不再嵌套一层目录。
新 Codex 会话先读 [AGENTS.md](AGENTS.md)，再读 [完整操作手册](docs/IOS_WORKFLOW.md)。

流水线：SwiftUI → GitHub main → macOS/Xcode → 未签名 IPA → Windows → Sideloadly 签名安装 → iPhone。
Daemon 续签缓存的 App；代码更新需要下载并重新安装新版。

```powershell
pwsh -File scripts/check-environment.ps1
python scripts/selftest.py
# 首次：登录 GitHub，并核对 Actions 额度/超额预算，再配置 origin 和推送
.\.tools\gh\bin\gh.exe auth login --web --git-protocol https
# 日常：先编辑代码，再提交选定路径
pwsh -File scripts/publish-ios.ps1 -Paths apps/MyFirstApp -Message 'Update app' -BillingChecked
pwsh -File scripts/download-ipa.ps1 -App MyFirstApp
pwsh -File scripts/deploy-ios.ps1 -Ipa artifacts/latest/MyFirstApp/MyFirstApp-unsigned.ipa -Open
# 新 App
pwsh -File scripts/new-app.ps1 -Name SecondApp -BundleId com.sjx13.ios.secondapp
```

本地准备与静态检查不等于云端编译成功。当前实测状态见 [验证记录](docs/VALIDATION.md)。

- [开发规范](docs/DEVELOPMENT.md)
- [构建和下载](docs/BUILD_AND_DEPLOY.md)
- [首次安装和续签](docs/SIDELOAD_AND_RENEW.md)
- [排错](docs/TROUBLESHOOTING.md)
- [历史](docs/PROJECT_HISTORY.md)

Git、Python 3.10+、PowerShell 7 是本地依赖。GitHub CLI 支持系统安装或 `.tools/gh/bin/gh.exe`。
`.tools`、产物、缓存及认证资料不提交。备份/迁移时保留源码仓库即可，重新安装 CLI 并登录。
