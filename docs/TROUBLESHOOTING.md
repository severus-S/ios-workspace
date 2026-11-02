# 故障排查与证据边界

每个新增条目记录：现象 → 证据 → 原因 → 修复 → 复测命令/结果。以下除“已实测”外是排查路径，不是已解决事件。

| 现象 | 检查与处理 |
|---|---|
| Windows 找不到 Xcode | 正常；使用 Actions。ci_build.py 明确拒绝 Windows 构建 |
| 找不到 gh | 系统安装，或用 `.tools/gh/bin/gh.exe`；脚本自动寻找两处 |
| GitHub 未登录 | 本机运行 gh auth login --web；不粘贴 token 到聊天/仓库 |
| 无 origin / 无仓库 | 按 IOS_WORKFLOW.md 选择授权仓库，设置 origin；不猜仓库名 |
| push 未触发 | 检查 main、路径过滤、Actions 是否禁用；文档变更不会自动触发 |
| 手动 dispatch 404/403 | 默认分支中需有 workflow_dispatch；检查 repo 和 Actions 写权限 |
| dispatch 无 run ID | API 版本/服务器可能不兼容；查 gh run list，不假设最近的一次就是本次 |
| xcodebuild 失败 | gh run view RUN_ID --log-failed；查 SDK/源码错误，Artifact build.log 保留完整诊断 |
| 签名/profile 报错 | 核对 CODE_SIGNING_ALLOWED=NO/REQUIRED=NO；不添加 Apple Secrets 解决未签名编译 |
| 工程不含新 Swift 文件 | 重跑 python scripts/project.py AppName；CI 也会生成 |
| 未配置图片/资源 | 当前生成器只配置 Swift；扩展资源构建阶段并云端验证，不能只把图片放目录 |
| 无 Artifact/已过期 | 3 天保留；重新构建，或指定保留期内成功 RunId |
| 只有 build.log 没 IPA | 失败构建不是可用产物；先修构建 |
| 下载旧版本 | 脚本选择成功构建；核对 commit 与目标。最新失败/进行中时可能下载上一次成功结果 |
| 哈希/Bundle/Manifest 不符 | 停止安装，检查来源和运行，不跳过校验 |
| IPA 无 Payload/可执行文件 | 不要改 ZIP 后缀；必须先真实 Xcode 构建，再正确打包 |
| iPhone 未识别 | 数据线/解锁/USB 信任 → iTunes 识别 → Apple 服务/官方驱动 → Sideloadly 日志 |
| 开发者模式未显示 | 先排查开发签名安装/配对，重连/重启后核对官方步骤；不承诺某入口必定即时出现 |
| Wi-Fi 不显示手机 | 先 USB 成功；iTunes Wi-Fi 同步应用、亮屏、Bonjour、同 LAN/SSID/VLAN、AP/访客隔离 |
| Apple 登录/Anisette 错误 | 查官方 FAQ 当前版本指引和日志；核对网页版 Apple 组件/2FA，不把认证内容发出 |
| 3 App/App ID 限制 | 删除不再需要的侧载 App 前先备份；等待配额恢复，以服务报错为准，不反复随机换 ID |
| 7 天后打不开 | 电脑/Daemon/设备可见性/认证/日志；USB 同身份覆盖重签，不先卸载 |
| 续签后仍是旧版本 | 正常缓存续签行为；下载新版手动覆盖并启用自动刷新 |
| 覆盖安装变成另一个 App | 对比源码 ID、Sideloadly 有效 ID、自定义 ID 和 Apple 身份；停止删除旧 App，先备份 |
| 覆盖后数据消失 | 查看是否卸载过、ID/身份是否变化、AppStorage key 是否变更、是否有迁移缺陷 |

## 本次已实测的工具问题

2026-11-02：PowerShell Invoke-WebRequest 的 `.Content` 可能是字节数组，直接用字符串正则比较下载校验和会误报。
改为先把官方 checksums.txt 下载到文件，再 Get-Content 比较对应平台条目与 Get-FileHash。
本次 gh ZIP 的 SHA256 与官方对应条目一致；这只是下载完整性验证，不代表 GitHub 已登录或云构建通过。

## 首次云端实测：lipo 参数顺序

Run `41439468904`：Xcode 16.4 / iPhoneOS SDK 18.5 输出 BUILD SUCCEEDED，随后架构校验失败。
`lipo -verify_arch arm64 <file>` 把文件路径当作架构参数；已改成 `xcrun lipo <file> -verify_arch arm64`。
此次失败不是 Swift 编译错误；最终复测结果记录在 VALIDATION.md。
