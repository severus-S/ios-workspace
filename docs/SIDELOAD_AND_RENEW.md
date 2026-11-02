# Windows 11 首次侧载、覆盖更新与自动续签

适用于本工作区的未签名 arm64 IPA。Sideloadly 官方称支持 iOS 27+，但本工作区没有完成 iPhone 18 Pro/iOS 27.2 实测。
来源、查证日期见 SOURCES.md；界面名称随版本变化时以当前安装版为准。

## 1. 安装官方软件和 Apple 组件（需要本人介入）

从 https://sideloadly.io/ 下载 Windows 64 位版本；当前查询为 v0.71.0。
使用该站提供的 Apple 网页版 iTunes 64 位、iCloud 链接和要求，不混用 Microsoft Store 版。
先在 Windows 已安装应用中检查现状；有 Store 版时按官方要求处理并备份相关数据，不让脚本擅自卸载。
运行 Apple/Sideloadly 安装向导，确认发布者和来源；遇到管理员确认由本人操作。
这些驱动、Apple Mobile Device Service、Bonjour 是否兼容当前手机，须连接后实测，不能仅凭安装完成推断。
如 Apple 安装包系统兼容性发生变化，查官方最新说明，不从第三方下载站补“修复版”。

```powershell
pwsh -File scripts/check-environment.ps1
Get-Service 'Apple Mobile Device Service','Bonjour Service' -ErrorAction SilentlyContinue
```

本次已从官网准备 `.tools/installers/SideloadlySetup64.exe`，没有运行安装向导。
该文件的 Windows Authenticode 检查结果为 NotSigned，没有可验证的发布者签名；不能声称已验证发布者身份。
本地 SHA256 为 `2e7d9a80bcd7912a9a2dae1969645f8af386af46802a79303e727773b506362e`，仅用于辨认本次下载文件，不是官方提供的校验值。
使用前由本人复核官网来源及当前下载。没有在本次工作中安装 Apple 组件或更改系统服务。

## 2. USB 配对和 Wi-Fi 同步

1. 用支持数据的 USB 线连接台式机与 iPhone，解锁手机。
2. 手机点“信任此电脑”并输入设备密码；电脑 iTunes/Apple 组件也完成信任提示。
3. iTunes 能显示设备后：设备 → 摘要 → 选项 → 通过 Wi-Fi 与此 iPhone 同步，应用/同步并完成。
4. 先通过 USB 完成第一次 Sideloadly 安装。再拔线测试 Wi-Fi，必要时保持 iTunes 打开、手机屏幕点亮。
5. Sideloadly 能列出无线设备后才算发现通过；看见同一个 Wi-Fi 名称不等于网络已互通。

## 3. 签名和首次安装

1. 下载脚本输出的 `*-unsigned.ipa`（不是 Artifact 外层 ZIP）。
2. Sideloadly 选中自己的 iPhone，拖入 IPA，输入免费 Apple ID。
3. 保持 App 的 Bundle ID 设置稳定；记录实际签名后的有效 ID，不把 Apple ID 邮箱写到仓库。
4. 不注入 tweak、不删除必要组件、不随意改系统最低版本；模板不依赖这些功能。
5. 启用自动刷新/Automatic Refresh 选项，点击 Start，按提示完成 Apple 认证/2FA。
6. Apple ID 密码、验证码仅在可信的本机应用里输入，不能发给 Codex 或上传到 Actions Secrets。
7. iPhone 若提示不信任开发者：设置 → 通用 → VPN 与设备管理，选择自己的开发者并信任。
8. 设置 → 隐私与安全性 → 开发者模式，开启、重启并在启动后确认；若入口尚未出现，先检查开发签名安装是否完成。
9. 打开 App，检查版本号、点击计数、便签保存和重启后数据。日志成功 + 真机启动才是安装通过。

本地记录只保存非敏感配置：App 名、源码 Bundle ID、有效 ID（如含个人信息则仅本地存）、版本、安装时间和到期时间。
可放 `.local/device-checklist.md`，Git 忽略；脱敏后再将结果写入 VALIDATION.md。

## 4. Daemon 自动续签与验证

安装时启用自动刷新会把 App 加入 Sideloadly Daemon 管理；检查托盘菜单的已登记 App 和最近日志。
保持电脑开机、用户会话和 Daemon 正常，允许按当前版本设置登录后启动。
自动刷新时必须能通过 USB 或已配好的 Wi-Fi 发现设备，Apple 认证仍有效，且网络能联系 Apple 服务。
电脑休眠/关机/用户退出、Daemon 未启动、无线设备不可见或认证过期都可能中断续签。
本工作区不自动改休眠、自启动或防火墙；按本人需求在界面设置，验证后记录。

验收必须包括：

1. 初装记录签名到期时间、App 版本、计数和便签。
2. 查看 Daemon 有无手动刷新功能；若有，执行一次并确认日志成功、到期时间前移、App 数据还在。这只能验证刷新路径。
3. 第 5–6 天检查一次自然后台刷新：日志实际执行时间、成功结果和新到期时间；必要时临时 USB 连接恢复可见性。
4. 原到期日之后打开 App，确认仍可运行，并核对期间确实存在成功续签记录。
5. 分别记录 USB 刷新、Wi-Fi 刷新和无人值守刷新，不把其中一个等同于全部通过。

若没有可查询的到期时间，用成功刷新日志和跨原到期日运行作交叉证据，明确证据局限。
不要为测试故意等到过期；临近到期未刷新就立即 USB 手动重签。
签名过期后使用同一 Apple ID/有效 Bundle ID 再安装，先尝试覆盖；不要首先删除 App。
不要清除 `%LOCALAPPDATA%\cache\sideloadly` 的刷新缓存，除非已有明确排错原因且保留当前 IPA。

## 5. OpenWrt 与 LAN/Wi-Fi 检查

本次不连接或修改路由器。只需局域网，不需要互联网端口映射。
桌面网卡通过 LAN、手机通过 Wi-Fi 完全可以工作，前提是两者属于互通的 LAN。

- Windows `Get-NetIPConfiguration`，手机 Wi-Fi 详情查看地址/掩码/网关；核对属于同一子网。
- LuCI 查看该 SSID 是否接入 LAN/br-lan，是否是 guest 网络；检查客户端隔离/AP isolation 和 VLAN 划分。
- 跨 VLAN 默认未必能发现 Bonjour/mDNS（UDP 5353 组播）；优先将开发设备放同一受信任 LAN，而不是先全网放行或启用反射。
- Windows 受信任家庭 LAN 的网络配置文件、Apple/Sideloadly 的防火墙授权按软件提示核对。不要全局关闭防火墙。
- 检查 Bonjour 和 Apple Mobile Device Service；先排除 USB 配对问题，再排无线。
- 手机 ping 不响应不代表侧载不可用；最终以 Sideloadly 无线发现和一次真实 Wi-Fi 安装/刷新为准。

## 6. 覆盖更新与免费账号限制

Daemon 只为已缓存 IPA 重签，不会监听 GitHub，也不会自动安装新的提交。
代码更新后必须下载新 IPA、核对版本/提交，再使用同一 Apple ID 和有效 Bundle ID 侧载。
新安装继续启用自动刷新，使 Daemon 缓存替换成新版；核对后续刷新仍为新版并保持数据。
不卸载旧 App。覆盖安装通常保留容器，但签名身份/ID变化或迁移缺陷仍可能丢数据，重要数据需另做备份。

免费 Apple ID 通常 7 天有效、同机最多 3 个侧载 App；可注册的 App ID 也有限制，扩展会增加占用。
不承诺推送/iCloud 等特权可用，不使用绕过限制工具，不购买开发者会员。
无法确认稳定的官方命令行安装接口，因此本工作区只自动构建/下载/校验/准备，签名安装保留 GUI。
