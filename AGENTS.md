# iOS 工作区永久指导

1. 每次开始 iOS 任务，先读 `docs/IOS_WORKFLOW.md`。
2. 编译优先使用现有 GitHub Actions 工作流，不重新设计已有流水线。
3. 新 App 优先复用 `templates/SwiftUI-App`，运行 `scripts/new-app.ps1`。
4. 修改工作流前检查现有脚本、配置和 `docs/BUILD_AND_DEPLOY.md`。
5. 构建失败先查 `docs/TROUBLESHOOTING.md`。
6. 不在 Windows 上直接运行 Xcode。
7. 始终区分编译、签名、安装、续签和版本更新。
8. 未经授权不得使用付费服务；云端运行前核对额度和预算。
9. 不提交签名私钥、Apple ID 密码、令牌或本地登录资料。
10. 完成任务后更新相关文档、验证记录和 `docs/PROJECT_HISTORY.md`。
11. 更稳定的方案先验证再更新配置；临时实验不得记为稳定结论。
12. 手机物理操作由用户完成；无真机证据不得声称安装或续签成功。
