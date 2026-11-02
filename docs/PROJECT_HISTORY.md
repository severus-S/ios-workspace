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
- 初始化本地 Git main，并保存 `Initialize reusable iOS workspace` 初始提交。未登录 GitHub、未配置远程、未推送、未运行云端构建。
- 未修改 OpenWrt、Windows 网络/防火墙/电源设置，未购买服务，未采集 Apple 凭据。
- iPhone 配对、签名、安装、覆盖保留数据和至少一轮自然后台续签尚待本人操作与实测。

后续每次变更附上触发原因、修改文件、验证命令、结果和未验证范围；不要把计划当作事实。
