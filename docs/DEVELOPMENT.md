# SwiftUI 开发规范

先读 IOS_WORKFLOW.md。每个 App 独立放在 apps/<Name>，入口 App.swift、界面 ContentView.swift。
app.json 是工程配置唯一来源；源码文件由 project.py 递归发现。当前生成器支持 Swift 源码和系统框架自动链接，不支持资源/扩展/包依赖的自动配置。

```powershell
pwsh -File scripts/new-app.ps1 -Name SecondApp -BundleId com.sjx13.ios.secondapp
python scripts/project.py SecondApp
python scripts/selftest.py
```

复用测试在临时隔离目录实际创建 SecondApp，测试结束自动清理，不在正式 apps 中留第二个演示 App。
实际新建后提交 apps/SecondApp 即可，push main 自动发现，无需改 workflow。

Bundle ID 首次安装前可按自己的反向域名规范确定；首次安装后稳定保存。
修改 `app.json.version` 表达用户可见版本；CI build number 使用 run number。同一 run 的重试可能相同，不视作独立版本。
重新生成工程后一起提交，避免本地工程和配置不一致。未来增加图标/Assets/其他资源需扩展生成器和测试再使用。
SwiftUI 使用系统控件以适应字号、深浅色和 VoiceOver；真机检查动态字体、竖屏、按钮和输入法。
AppStorage 适合示例计数与便签；未来复杂业务持久化要设计迁移和备份。

真机验收：启动 → 版本正确 → 点击 3 次 → 输入便签 → 结束进程重开 → 数据保留。
覆盖升级验收：先记旧值 → 构建新版本 → 不卸载覆盖安装 → 新版号和旧数据同时存在。
本地 selftest 只测试基础设施，不执行 Swift 编译或 iOS UI 测试。
