# 项目变更记录

## 2026-11-02 — 创建长期复用基础设施

- 在当前目录直接建立工作区和永久 AGENTS.md，避免再嵌套目录。
- 创建完整工作流、开发、构建、签名续签、排错与来源文档。
- 创建 MyFirstApp（Bundle ID `com.sjx13.ios.myfirstapp`），SwiftUI 欢迎页、版本、计数和 AppStorage 便签。
- 提供模板复制器、原生 Xcode 工程生成器；无需 XcodeGen/Homebrew 或第三方 iOS 库。
- 创建 main push / workflow_dispatch → macos-15 → Xcode arm64 → unsigned Payload IPA → 结构校验 → Artifact 流程。
- 固定已查证的 Action 发布 SHA，最小 contents:read 权限，20 分钟超时与 3 天保留。
- 创建 PowerShell 检查、提交推送、dispatch/等待、下载校验和人工部署入口。
- 下载并校验工作区便携 GitHub CLI 2.103.3 和 actionlint 1.7.12；未改 PATH。
- 下载官网 Sideloadly x64 安装器，记录 SHA256 和 NotSigned 结果，未执行安装；Apple 组件仍待安装。
- 本地离线模板/IPA 负例、PowerShell 解析/失败路径、工作流静态和 PBX OpenStep 解析通过，具体见 VALIDATION.md。
- 初始化本地 Git main，并保存 `Initialize reusable iOS workspace` 初始提交 `936447d`。
- 随后本人完成 GitHub severus-S 登录，授权创建私有仓库 severus-S/ios-workspace 并运行构建；本人确认免费额度和超额阻断预算。最终云端结果见 VALIDATION.md。
- 未修改 OpenWrt、Windows 网络/防火墙/电源设置，未购买服务，未采集 Apple 凭据。
- iPhone 配对、签名、安装、覆盖保留数据和至少一轮自然后台续签尚待本人操作与实测。

后续每次变更附上触发原因、修改文件、验证命令、结果和未验证范围；不要把计划当作事实。

## 2026-11-02 — 首次云端编译修正

私有仓库已创建并推送。手动 dispatch Run 41439468904 证实 SwiftUI 在 Xcode 16.4/iPhoneOS 18.5 SDK 编译成功。
后续 lipo 参数顺序错误导致作业失败；已修正 ci_build.py 并通过 main push 复测。

Run 41439595434（push，提交 8657f9d）最终 success，完整未签名构建/打包/上传通过。
Windows 使用指定 RunId 和默认最新成功两条路径下载，来源、SHA256、Bundle ID 和 arm64 均校验通过。
生成 MyFirstApp 1.0.0 (2)。下载器增加 `artifacts/latest/<App>` 稳定路径与 manifest/SHA256 整理。
deploy-ios.ps1 已用真实 IPA 执行校验并输出指引；手机签名/安装和续签仍未执行。

最终使用 publish-ios.ps1 提交推送 e5ac14a，自动触发 Run 41439857459 再次成功（job 18 秒，不含排队）。
默认下载命令自动解析 origin 并下载最新版，稳定路径更新为 MyFirstApp 1.0.0 (3)。全部验证详情及哈希已保存。
