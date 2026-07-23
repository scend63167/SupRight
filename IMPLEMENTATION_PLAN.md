# SupRight 当前实施记录

> 状态：MVP 已完成；公开测试版发布准备中
> 更新：2026-07-23

## 当前范围

- 使用 Swift、SwiftUI、AppKit 与 Finder Sync 原生实现。
- 由主 App 与 Finder Sync 扩展组成；只在用户授权的一个目录及其子目录中工作。
- 公开测试版提供未签名 `.app` ZIP，不提供 DMG、安装器、Developer ID 签名或公证。

## 已完成

- 目录授权通过隐式安全作用域书签在 App Group 中共享；主 App 退出、Finder 与扩展重启后仍可恢复。
- Finder 菜单支持新建 TXT、Markdown、JSON、RTF、Word、Excel、PowerPoint。
- DOCX/XLSX/PPTX 使用内置有效模板；模板缺失时不创建 0 字节文件。
- 支持复制文件名、复制完整路径和在 Terminal.app 中打开当前目录。
- 已在当前 macOS 26.5、Xcode 26.6 环境手工验证七种文件创建、Office ZIP/XML 结构、复制操作、Terminal 启动和 Finder 重启恢复。

## 本次实施：配置页与菜单功能开关

- 主 App 提供十项独立开关：七种新建类型与三种辅助操作。
- 开关写入 App Group；Finder 在下一次打开右键菜单时读取，无须重启 Finder。
- 关闭所有新建类型时隐藏“新建文件”；关闭当前上下文所有可用功能时隐藏 `SupRight` 菜单。
- 主 App 已改为可扩展的侧边栏布局：概览、菜单功能、权限与访问、诊断。
- 已加入菜单栏状态项，显示已启用功能数量，并提供打开设置与权限设置入口。
- Finder 扩展以 `/` 为根注册目录，因此菜单默认在所有 Finder 目录显示；产品确定采用站外分发，关闭 App Sandbox，并要求用户在系统设置中手动确认完全磁盘访问。

## 待回归

- macOS 14/15 的构建与 Finder 基础回归。
- 目录失效、只读目录与多选上下文的回归测试。
- 已完成菜单功能开关的 Finder 集成测试：关闭 JSON 后，桌面 Finder 菜单立即隐藏 JSON 项；恢复后重新出现。
- 已完成：主 App 关闭 App Sandbox、Finder Sync 扩展保留沙盒、以 App Group 请求队列和 Darwin 通知转交操作；桌面创建 TXT 回归通过。
- Developer ID 签名、公证与独立安装包验证。

## 明确不在当前范围

- 剪切、粘贴、复制/移动到、常用目录、外部 App、模板导入、菜单排序。
- 后台任务队列、联网、遥测、账号体系、预编译安装包。
