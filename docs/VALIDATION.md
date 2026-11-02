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
| 私有 GitHub 仓库 | https://github.com/severus-S/ios-workspace | 已创建 PRIVATE，main 已推送 |
| 手动触发与失败上报 | Run 41439468904 | build-ios.ps1 返回准确 run ID、等待并传播失败；Swift 编译成功，lipo 参数错误已定位修正 |
| push 自动构建 | https://github.com/severus-S/ios-workspace/actions/runs/41439595434 | 事件 push，提交 8657f9de37a20ed7b736cbddf452efb1b5b15640，最终 success |
| 真实 IPA 生成 | 上述成功运行 | Xcode 16.4 / iPhoneOS SDK 18.5，Swift 编译、plutil、lipo、otool、codesign 未签名检查、ditto 打包、IPA 校验、Artifact 上传均通过 |
| Windows 下载/部署准备 | download-ipa.ps1 指定 RunId 及默认最新成功两种方式；deploy-ios.ps1 不带 -Open | Manifest 来源、SHA256、Bundle ID、arm64 校验通过；只输出人工安装指引，未安装到手机 |

最终复测：Run [41439857459](https://github.com/severus-S/ios-workspace/actions/runs/41439857459)，push 事件、提交 e5ac14a1e9aa1adb9770584b4dcb32215a69893a、success，job 用时 18 秒（不含排队）。
publish-ios.ps1 已真实提交/推送；download-ipa.ps1 无 -Repo/RunId 自动解析 origin、选择最新成功并整理到稳定目录，均通过。
当前真实产物：`artifacts/latest/MyFirstApp/MyFirstApp-unsigned.ipa`，版本 1.0.0 (3)，最低 iOS 17.0，Bundle ID com.sjx13.ios.myfirstapp。
SHA256：`b4ad77ff7fdd0171862df5bd0be0053ecc71c71a0b20a665f7f33691a2e3f886`。
后续下载可能更新稳定路径，须以旁边 manifest.json 的 runId/commit/hash 为准。

## 当前阻塞和未验证

- GitHub CLI 已登录 severus-S。本人已授权创建私有仓库 severus-S/ios-workspace 并首次构建；本人确认免费额度和超额阻断预算（代理未读取账单）。
- macOS 编译到 Windows 下载已通过；iPhone 18 Pro/iOS 27.2 的实际运行兼容仍待真机验证。
- 本机未检测到 Bonjour/Apple Mobile Device 服务；Sideloadly 安装状态尚未由 GUI 确认。
- 已下载官网 Sideloadly x64 安装器至 `.tools/installers`，MZ 文件头存在；Authenticode 为 NotSigned，因此没有验证发布者身份，也没有执行安装器。
- 未安装 Apple 组件、未 USB 配对、未签名安装，未验证 iPhone 18 Pro/iOS 27.2 兼容性。
- Swift 源码已真实编译；界面、持久化、覆盖升级保留数据和 Wi-Fi 侧载尚未真机验证。
- 未检查/修改 OpenWrt；同 LAN、隔离设置和 mDNS 需实网检查。
- Daemon 自动续签尚未验证；需要跨初始到期周期的真实日志和运行证据。

## 后续验收填写（无证据保持待验证）

| 环节 | 需要的证据 | 结果 |
|---|---|---|
| 第一次云端编译 | 仓库、run URL、commit、Xcode/SDK、成功状态 | 已通过，见上表 |
| IPA 下载 | RunId、manifest、SHA256、内部结构检查 | 已通过，见上表 |
| 首次 USB 安装 | Sideloadly 脱敏日志、设备打开正确版本 | 待验证 |
| 持久化 | 点击/便签值，结束进程后仍保留 | 待验证 |
| 覆盖更新 | 新版本号 + 原有数据，未卸载 | 待验证 |
| 无线安装/刷新 | 拔掉 USB 后发现设备且日志成功 | 待验证 |
| 自然后台续签 | 自动执行时间、新到期时间、跨原到期日可运行 | 待验证 |

日志保存前删除邮箱、设备唯一标识、认证数据和其他个人信息。签名密码不记录。
