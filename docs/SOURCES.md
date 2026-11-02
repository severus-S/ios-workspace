# 官方来源与查证记录

查证日期：2026-11-02。动态版本、配额和支持范围会变化，实施前复核。

- Sideloadly 主站：https://sideloadly.io/ — 当前页面 v0.71.0、Windows x64、网页版 Apple 组件要求、iOS 27+ 支持声明；不是本机兼容实测。
- Sideloadly FAQ：https://sideloadly.io/faq — Wi-Fi 同步、Daemon 登记/续签、同身份更新缓存、7 天与 3 App 限制、覆盖更新条件。
- Apple 开发者模式：https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device — 页面动态内容；本次具体开关步骤交叉参考 Sideloadly FAQ。
- Apple 账号：https://developer.apple.com/help/account/basics/about-your-developer-account — 免费/会员能力应按当前账号规则复核。
- GitHub Actions 计费：https://docs.github.com/en/billing/concepts/product-billing/github-actions — 公开标准 runner、私有额度及存储规则；没有读取本人账单。
- Runner 软件：https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md — macos-15、预装 Xcode/SDK；每次 CI 输出实际版本。
- Checkout：https://github.com/actions/checkout/releases/tag/v7.0.1 — SHA `3d3c42e5aac5ba805825da76410c181273ba90b1`，本地 git ls-remote 复核。
- Upload Artifact：https://github.com/actions/upload-artifact/releases/tag/v7.0.2 — SHA `cf430e030ddbb5b0abf93d22962f4752f3646cd9`，本地 git ls-remote 复核。
- Workflow dispatch REST：https://docs.github.com/en/rest/actions/workflows#create-a-workflow-dispatch-event — 2026-03-10 API 返回 workflow_run_id/html_url。
- GitHub CLI：https://github.com/cli/cli/releases/tag/v2.103.3 — 已下载工作区便携版并核对官方 checksums.txt。
- Actionlint：https://github.com/rhysd/actionlint — 本地工作流静态校验工具，不上传源码。
- OpenWrt Wi-Fi：https://openwrt.org/docs/guide-user/network/wifi/basic — 本次网站防护阻止读取；本文网络部分为常规局域网排查建议，未检查用户路由器配置。

不从这些支持声明推断真机已安装、Wi-Fi 已连通或无人值守续签已通过。
