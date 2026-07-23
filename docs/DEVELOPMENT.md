# 本地开发与签名

SupRight 的公开测试包可以直接安装；只有要从源码运行或修改代码时，才需要本节。

## 打开项目

1. 使用 Xcode 17 或更新版本打开 `SupRight.xcodeproj`。
2. 对 `SupRight` 和 `SupRightFinderExtension` 两个 Target，选择自己的 Development Team。
3. 若 Xcode 提示 Bundle Identifier 或 App Group 已被占用，请把它们改成自己唯一的反向域名标识，并保持主应用与 Finder 扩展的 App Group 完全一致。
4. 同步替换代码中的 App Group 字符串，然后运行 `SupRight` Scheme。

当前维护者的配置使用 `4VZQ365DP6.com.iiimac.SupRight`。它只用于本项目的测试包，不应被其他开发者直接复用。

代码中涉及该 App Group 的位置：

- `SupRight/SupRight.entitlements`
- `SupRightFinderExtension/SupRightFinderExtension.entitlements`
- `SupRight/AppConfiguration.swift`
- `SupRight/OperationDispatcher.swift`
- `SupRightFinderExtension/FinderSync.swift`

## 验证

运行后，请在 Finder 的空白目录右键确认 `SupRight` 子菜单出现。若要写入桌面、文稿或下载目录，还要在“系统设置 → 隐私与安全性 → 完全磁盘访问”中打开 SupRight。
