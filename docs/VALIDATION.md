# 验证记录与首次验收清单

日期：2026-11-02（Asia/Singapore）。本页必须随实际验证更新。

## 已执行并通过

| 项目 | 命令/证据 | 范围 |
|---|---|---|
| 工具检查 | `pwsh -File scripts/check-environment.ps1` | Git 2.48.1、Python 3.14、PowerShell 7 可用；本地 gh 可启动 |
| CLI 下载完整性 | gh 2.103.3 官方 checksums.txt 对比 Get-FileHash | ZIP SHA256 `98d0cfa794721665d7973dd728c78aff7bd836d58f10f6d7a03568eccb0a22e0` |
| 模板复用与输入保护 | `python scripts/selftest.py` | 隔离临时目录创建 SecondApp、生成工程、拒绝重复覆盖/Bundle ID/路径越界 |
| IPA 校验器正负例 | 同上，共 4 个 unittest 测试方法通过 | 人造测试夹具；正确头可读，错误架构/平台/缺失程序/普通 ZIP/危险路径被拒绝；没有生成真实 App IPA |
| Windows 构建边界 | 同上 | ci_build.py 在 Windows 上明确拒绝 Xcode 构建 |
| PowerShell | `pwsh -File scripts/test-powershell.ps1` | 8 个 ps1 解析通过；计费确认缺失、外部非零退出、非 IPA 部署均正确失败 |
| Python 语法 | `python -m compileall -q scripts` | 脚本可解析；不是 Swift 编译 |
| 工作流静态检查 | `.tools/actionlint/actionlint.exe .github/workflows/build-ios.yml` | actionlint 1.7.12 无错误；工具 ZIP 也核对官方 SHA256 |
| 原生工程格式 | openstep-parser 2.0.3 解析 project.pbxproj | 15 个对象、根类型 PBXProject；不是 Xcode 构建验证 |
| Action 固定版本 | git ls-remote 对比两份官方 release tag | checkout v7.0.1 与 upload-artifact v7.0.2 SHA 对应 |
| Git 文件边界 | git diff --cached --check、git check-ignore | 33 个项目文件；工具、产物、凭据扩展和缓存被忽略，暂存差异无空白错误 |

## 当前阻塞和未验证

- GitHub CLI 未登录（auth status 实测），没有 origin；需要本人浏览器授权并指定 OWNER/REPO。
- 未读取本人 GitHub 额度/账单；需要本人确认剩余额度和超额阻断预算，再执行首次 push/dispatch。
- macOS Xcode 真实编译、SDK 兼容、codesign 未签名检查、ditto 实包及 Artifact 上传/下载端到端未执行。
- 当前没有真实 IPA，不把测试夹具当成可安装成果。
- 本机未检测到 Bonjour/Apple Mobile Device 服务；Sideloadly 安装状态尚未由 GUI 确认。
- 已下载官网 Sideloadly x64 安装器至 `.tools/installers`，MZ 文件头存在；Authenticode 为 NotSigned，因此没有验证发布者身份，也没有执行安装器。
- 未安装 Apple 组件、未 USB 配对、未签名安装，未验证 iPhone 18 Pro/iOS 27.2 兼容性。
- Swift 源码尚未经过 Swift 编译器；界面、持久化、覆盖升级保留数据和 Wi-Fi 侧载尚未真机验证。
- 未检查/修改 OpenWrt；同 LAN、隔离设置和 mDNS 需实网检查。
- Daemon 自动续签尚未验证；需要跨初始到期周期的真实日志和运行证据。

## 后续验收填写（无证据保持待验证）

| 环节 | 需要的证据 | 结果 |
|---|---|---|
| 第一次云端编译 | 仓库、run URL、commit、Xcode/SDK、成功状态 | 待验证 |
| IPA 下载 | RunId、manifest、SHA256、内部结构检查 | 待验证 |
| 首次 USB 安装 | Sideloadly 脱敏日志、设备打开正确版本 | 待验证 |
| 持久化 | 点击/便签值，结束进程后仍保留 | 待验证 |
| 覆盖更新 | 新版本号 + 原有数据，未卸载 | 待验证 |
| 无线安装/刷新 | 拔掉 USB 后发现设备且日志成功 | 待验证 |
| 自然后台续签 | 自动执行时间、新到期时间、跨原到期日可运行 | 待验证 |

日志保存前删除邮箱、设备唯一标识、认证数据和其他个人信息。签名密码不记录。
