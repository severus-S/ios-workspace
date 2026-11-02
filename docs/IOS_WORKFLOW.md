# iOS 工作区核心操作手册

本文件独立保存完整流程。先看 `VALIDATION.md` 区分已测与未测，再按以下步骤执行。
工作区根为 `D:\CodexWorking\iOS`。命令在该目录 PowerShell 7 运行；不在 Windows 启动 Xcode。

## 1. 目录和技术路线

- `AGENTS.md`：Codex 会话入口；详细规范保存在本目录。
- `apps/<App>/app.json`：稳定名称、Bundle ID、版本和最低系统版本。
- `apps/<App>/Sources/`：Swift、SwiftUI 原生源码；无需第三方依赖。
- `apps/<App>/<App>.xcodeproj/`：可提交的原生工程，由 `scripts/project.py` 生成。
- `templates/SwiftUI-App/`：新 App 模板，不直接编译占位符。
- `scripts/`：Windows 命令入口和跨平台 Python 构建/校验工具。
- `.github/workflows/build-ios.yml`：已有云端流水线。
- `artifacts/`：下载和构建结果，Git 忽略；`.tools/` 为本地工具。

示例为 iPhone arm64、最低 iOS 17.0；使用 SwiftUI Form、NavigationStack、AppStorage。
支持在更高系统运行是部署目标的设计意图，iPhone 18 Pro/iOS 27.2 的实际兼容性必须真机验证。
不使用推送通知、iCloud、App Groups 等可能要求额外 entitlement/付费资格的能力。
现有模板没有正式品牌图标，正式发布前另加；这是侧载测试工程。

## 2. 首次环境准备

```powershell
pwsh -File scripts/check-environment.ps1
.\.tools\gh\bin\gh.exe auth login --web --git-protocol https
.\.tools\gh\bin\gh.exe auth setup-git
```

若 `.tools` 未随备份恢复，从 https://cli.github.com/ 安装 GitHub CLI，然后用 `gh` 替代上述路径。
登录在 CLI 自己的安全凭据存储中完成；不把 token 输出到文档或放进仓库。
浏览器核对 GitHub Settings → Billing & licensing → 使用量/预算：账号方案、剩余额度、Artifact 存储、超额阻断。
公开仓库标准 runner 的计算通常免费；私有仓库用账号包含额度，macOS 消耗按当前费率折算。
不能由脚本推断账号仍有免费额度。首次推送本身会触发构建，因此推送前就要检查预算。
采用标准 `macos-15`、20 分钟超时、取消同分支旧任务、Artifact 3 天保留；未开通付费服务。

## 3. 绑定 GitHub 仓库与首次推送

本地已初始化 main，但不会猜测你的仓库或公开代码。登录后选择空仓库。
已存在的远程仓库有内容时，先 fetch/检查历史并整合，不用 force push。
以下 OWNER/REPO 必须替换为本人授权的仓库：

```powershell
# 方案 A：使用已有空仓库
git remote add origin https://github.com/OWNER/REPO.git
# 方案 B：由你明确选择创建私有仓库；与方案 A 二选一
# .\.tools\gh\bin\gh.exe repo create OWNER/REPO --private --source . --remote origin
git status --short
# 首次先检查文件内容、忽略规则与 git diff --cached，不能加入凭据
git add AGENTS.md README.md .gitignore .gitattributes docs scripts templates apps .github
git diff --cached --stat
git commit -m 'Initialize reusable iOS workspace'
# 已确认额度和预算后才推送
git push -u origin main
```

如果已做过初始提交，跳过 add/commit。main 代码路径变化会自动编译所有 apps。
仅文档变化不会触发 push 构建。工作流必须先存在于默认分支，手动 dispatch 才可使用。

## 4. 新建 App 与日常开发

```powershell
pwsh -File scripts/new-app.ps1 -Name SecondApp -BundleId com.sjx13.ios.secondapp
python scripts/project.py SecondApp
python scripts/selftest.py
```

名称使用英文字母开头的字母/数字/下划线；Bundle ID 至少三级、每个 App 唯一。
样例固定为 `com.sjx13.ios.myfirstapp`，首次安装后保持不变。不要每次构建随机改 ID。
模板复制器拒绝覆盖 App 或重复 Bundle ID。日常改 `Sources/*.swift`，版本改 `app.json` 的 `version`。
新增/删除 Swift 文件后重新运行 project.py；CI 也会重新生成，因此不要手改 pbxproj 的生成字段。
使用稳定 AppStorage key，数据模型升级要迁移；保留旧数据的覆盖安装必须真机回归。
当需要资源、扩展、第三方依赖时，先扩展现有生成器并验证，不另建未经验证的流水线。

```powershell
pwsh -File scripts/publish-ios.ps1 -Paths apps/MyFirstApp -Message 'Improve welcome screen' -BillingChecked
```

脚本拒绝已有暂存内容和非 main 分支，仅暂存显式给出的路径；调用即授权提交这些路径。
若变更包含 scripts/模板/工作流，明确把相关路径一起传入并审查。

## 5. 云端构建原理、命令与失败检查

Runner 使用预装 Xcode 和 iPhoneOS SDK，不向云端提供 Apple ID、证书或 provisioning profile。
Python 标准库生成原生工程，再调用：

```text
xcodebuild -project apps/MyFirstApp/MyFirstApp.xcodeproj -target MyFirstApp
  -configuration Release -sdk iphoneos -arch arm64
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= build
```

实际完整命令含输出目录和 `CURRENT_PROJECT_VERSION=GITHUB_RUN_NUMBER`，由 `scripts/ci_build.py` 输出。
生成的 `.app` 用 plutil/lipo/otool 检查，复制为 `Payload/MyFirstApp.app`，再用 ditto 打包。
Python 校验 ZIP CRC、Payload 唯一主 App、Info.plist、iPhoneOS 平台、Bundle ID 和 arm64 Mach-O 可执行头。
生成 `manifest.json` 和 SHA256SUMS 供 Windows 核对。结构校验不证明签名有效或已能安装。

手动运行和查询（push 已触发时无需重复 dispatch）：

```powershell
pwsh -File scripts/build-ios.ps1 -App MyFirstApp -BillingChecked -Wait
.\.tools\gh\bin\gh.exe run list --workflow build-ios.yml --branch main
.\.tools\gh\bin\gh.exe run view RUN_ID --log-failed
.\.tools\gh\bin\gh.exe run watch RUN_ID --exit-status
```

`-Repo OWNER/REPO` 可显式指定仓库。`-Ref main` 默认只编译远程已有代码，不上传未提交变更。
手动 `-App ALL` 编译所有 App。脚本按 dispatch 响应的确切 run ID 等待，不猜测最新运行。
首次真实编译前，预装 Xcode/SDK 是否满足当前工程仍是待验证项。不要宣称 Windows 本地已编译通过。
失败先查 TROUBLESHOOTING.md 和日志，再修复。失败日志也上传，失败运行不可作为成功 IPA 下载。

## 6. 下载与准备安装

```powershell
pwsh -File scripts/download-ipa.ps1 -App MyFirstApp
# 精确复现某次成功构建
pwsh -File scripts/download-ipa.ps1 -App MyFirstApp -RunId 123456789
pwsh -File scripts/deploy-ios.ps1 -Ipa 'D:\完整路径\MyFirstApp-unsigned.ipa' -Open
```

下载器查最近 30 个成功 main 构建，寻找含目标 App 的保留 Artifact；不存在就报错，不把其他 App 当成当前结果。
校验 commit/run ID、SHA256、IPA 内部结构，输出绝对路径和来源提交。
通过后同时整理到稳定路径 `artifacts/latest/<App>/<App>-unsigned.ipa`，旁边保留 manifest 和校验和。此处 latest 是最新一次成功下载，不保证远端最新提交已构建完成。
若最新构建正在运行或失败，下载到的成功产物可能较旧：安装前核对输出 commit 与预期提交。
deploy 只校验和打开目录，可 `-SideloadlyPath '实际 exe 路径' -Open` 启动 GUI；没有自动安装 CLI。
Actions Artifact 的外层 ZIP 和其中的 IPA 是不同文件。把 IPA 拖进 Sideloadly，不能拖外层 ZIP。

## 7. 首次签名、安装与续签

详细逐步操作在 SIDELOAD_AND_RENEW.md。
先安装 Sideloadly 官方 Windows x64 版及其官网要求的网页版 iTunes/iCloud 组件，不混用 Store 版。
USB 连接，解锁 iPhone、双向信任，iTunes 中打开“通过 Wi-Fi 与此 iPhone 同步”并应用。
Sideloadly 选择设备、拖入 IPA、填写免费 Apple ID、完成二次认证，启用自动刷新后 Start。
Apple ID 密码只在可信的本机 Sideloadly 界面输入，不交给 Codex/GitHub。
手机按提示信任开发者，设置 → 隐私与安全性 → 开发者模式，重启后确认。
启动 App，记录版本，点击加一、保存便签、杀进程重开检查持久化。

Daemon 后台续签要求电脑开机/可工作、Daemon 正在运行、认证有效、USB 或局域网可发现设备。
桌面 LAN + 手机 Wi-Fi 可以使用同一 LAN，但必须检查 SSID 绑定、访客/AP 隔离、防火墙及 Bonjour/mDNS。
不需要为本工作流开放公网端口，不自动改 OpenWrt、Windows 防火墙或休眠配置。
首次配置到第 5–6 天检查实际续签日志和新的到期时间，不能只看托盘图标。

## 8. 更新 App 与账号限制

代码变更 → 提交 push → 等待成功 → 核对 commit 下载 IPA → Sideloadly 使用同一 Apple ID 和相同有效 Bundle ID 覆盖安装。
更新时继续启用自动刷新，确认 Daemon 缓存已替换为新版。续签旧缓存不会下载 GitHub 的新版。
不要卸载旧 App 以便更新；卸载通常会清除本机数据。重要数据先备份，覆盖也不能保证所有场景无损。
示例的计数/便签是本地 UserDefaults；第一次覆盖升级后实测版本变化、数据保持，再进入续签验收。
免费 Apple ID 的签名通常 7 天，最多 3 个侧载 App；扩展可能占用 App ID 配额。
新建 App ID 还有周期配额，以 Apple/Sideloadly 实际响应为准，不靠换 ID 绕过。
无付费会员不能用本流程上架 App Store/TestFlight；本工作区不购买任何服务。

## 9. 维护和恢复

每次调整编译/签名/部署，更新对应文档、VALIDATION.md 和 PROJECT_HISTORY.md。
已解决的问题记录“现象、原因、修改、复现命令、验证范围”；猜想标记待验证。
新会话按 AGENTS.md 即可恢复，不依赖聊天记录。源码入 Git；本地 CLI、登录、IPA、设备配对不入 Git。
换电脑后重新装 CLI/Apple 组件并重新 USB 配对。IPA 过期可重新构建；不能把 Artifact 当长期备份。
权威来源和查证日期见 SOURCES.md；服务规则变化后先复核再修改稳定流程。
