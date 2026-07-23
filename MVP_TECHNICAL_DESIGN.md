# SupRight MVP 技术设计

> 对应：[MVP_PRD](MVP_PRD.md) · [MVP_UI_SPEC](MVP_UI_SPEC.md)
> 状态：已实现，公开测试版 v0.1.0
> 日期：2026-07-23

## 1. 范围与技术结论

MVP 使用原生 macOS 技术实现：Swift、SwiftUI、AppKit 和 Finder Sync。

当前已验证的链路：

```text
Finder 右键触发操作
  → Finder Sync 扩展写入 App Group 操作队列
  → Darwin 通知唤醒 SupRight 主 App
  → 未沙盒化的主 App 执行文件操作
  → Finder 选中新文件
```

Finder Sync 扩展在 macOS 上必须保持沙盒，不能直接承担全目录写入；主 App 使用完全磁盘访问执行实际动作。该设计将这条链路扩展到新建七种文件、复制名称/路径、在 Terminal 中打开目录，同时保持扩展代码短小、权限边界可验证。

## 2. 架构

```text
┌───────────────────┐       App Group        ┌─────────────────────────┐
│ SupRight 主 App   │ ◄──────────────────────► │ Finder Sync Extension   │
│                   │  开关、操作请求队列       │                         │
│ - SwiftUI 配置页  │  + Darwin 通知           │ - 监控根目录            │
│ - 操作执行器      │                          │ - 解析 Finder 上下文    │
│ - 完全磁盘访问    │                          │ - 构建菜单、提交请求     │
└───────────────────┘                          └─────────────────────────┘
```

不引入网络服务、守护进程、数据库、后台请求队列或第三方依赖。所有 MVP 操作都足够轻量，可由 Finder 扩展直接完成。

## 3. 模块划分

当前 MVP 保持两个 target 和少量源文件，不额外创建 Swift Package、Framework 或后台服务。

| 文件/模块 | 当前职责 | 所属 target |
| --- | --- | --- |
| `SupRight/ContentView.swift` | 配置页、展示状态、管理功能开关 | 主 App |
| `SupRightApp.swift` | 主窗口与菜单栏状态项 | 主 App |
| `SupRight/OperationDispatcher.swift` | 读取操作队列并执行新建、复制与 Terminal 操作 | 主 App |
| `SupRightFinderExtension/FinderSync.swift` | 读取共享配置、构建菜单、提交显式用户操作 | Finder 扩展 |
| `SupRightFinderExtension/Resources/Templates/` | DOCX/XLSX/PPTX 空白模板 | Finder 扩展资源 |
| `Scripts/generate-office-templates.sh` | 重建 DOCX/XLSX、校验三个模板 | 开发脚本 |

## 4. 授权与 App Group 设计

### 4.1 标识与存储

- App Bundle ID：`com.iiimac.SupRight`
- Extension Bundle ID：`com.iiimac.SupRight.FinderExtension`
- App Group：`$(TeamIdentifierPrefix)com.iiimac.SupRight`
- 当前本机构建使用的实际组标识：`4VZQ365DP6.com.iiimac.SupRight`

App Group 的 `UserDefaults` 键：

| 键 | 类型 | 说明 |
| --- | --- | --- |
| `schema-version` | `Int` | 当前固定为 `1` |
| `shared-directory-bookmark` | `Data` | 主 App 写入的隐式安全作用域书签 |
| `shared-directory-path` | `String` | 仅用于界面显示和排错，不作为权限依据 |
| `authorization-revision` | `UUID` 字符串 | 每次重新授权时变更，供扩展刷新 |
| `menu-feature.<id>` | `Bool` | 菜单功能开关；键不存在时默认 `true` |
| `menu-bar-visible` | `Bool` | 是否显示 SupRight 菜单栏状态项；默认 `true` |
| `pending-finder-operations` | `Data` | Finder 扩展提交、主 App 消费的一次性操作队列 |

### 4.2 跨进程请求规则

Finder 扩展仅在用户点击菜单时，将动作类型、目标目录和已选项目路径编码后写入 App Group；随后发送 Darwin 通知并按需启动包含它的主 App。主 App 启动时和收到通知时都会消费队列。

队列不用于后台扫描、定时任务或遥测；每一项都必须对应一次 Finder 中的显式用户点击。主 App 消费后立即移除该项，并在失败时显示原因。

### 4.3 沙盒边界验证结果

已于 2026-07-23 在当前 macOS 26.5 机器验证：主 App 的最终签名不含 `com.apple.security.app-sandbox`；Finder Sync 扩展的最终签名仍含该项。直接由扩展创建桌面文件失败；改由主 App 消费请求后，桌面成功创建 `Untitled.txt`。

因此全目录模式不依赖目录书签。未来“仅限指定目录”模式才使用安全作用域书签；它不影响全目录默认模式。

### 4.4 功能开关

功能标识固定为 `create-text`、`create-markdown`、`create-json`、`create-rtf`、`create-word`、`create-excel`、`create-powerpoint`、`copy-names`、`copy-paths`、`open-terminal`。

- 主 App 通过 App Group 的 `UserDefaults` 写入 `menu-feature.<id>`。
- Finder 扩展在 `menu(for:)` 中即时读取该值，未设置时视为启用。
- 新建文件子菜单只加入已启用的预设类型和“自定义文件…”入口；没有条目时不加入父项。
- 顶层 `SupRight` 菜单只在至少有一个当前上下文可执行的条目时加入。

### 4.5 全目录模式、站外分发与完全磁盘访问

- Finder 扩展将 `/` 设置为其唯一的 `directoryURLs` 根目录，以便在该根及其子目录中提供上下文菜单。
- 产品采用站外分发。公开测试版为 ad-hoc 签名 ZIP；主 App 不启用 App Sandbox，Finder Sync 扩展保留 macOS 要求的沙盒，但不直接访问目标文件。正式版将启用 Hardened Runtime、使用 Developer ID 签名并完成 Apple 公证。
- 主 App 不会、也不能以代码自动授予“完全磁盘访问”；“前往完全磁盘访问设置”只尝试打开系统设置对应位置，并在失败时提供手动路径。
- 不使用未公开 API 读取完全磁盘访问开关；主 App 读取现有受保护用户目录作为保守探测。探测成功则隐藏引导；失败或目录不存在而无法确认时显示引导，并且实际操作仍必须处理失败。
- 即使用户已手动授予完全磁盘访问，操作仍必须处理 POSIX 权限、ACL、SIP、只读卷与网络卷失败。
- 不在后台枚举、扫描或给文件打标；只有用户在 Finder 中请求菜单或执行动作时才处理当前 URL。

### 4.6 菜单栏状态项

- 使用原生 `NSStatusItem`，默认常驻于系统菜单栏。
- 图标使用 SupRight 单色模板图标；菜单展示已启用项目数、权限状态和设置入口。
- 弹出菜单包含权限状态、`打开设置…` 与 `前往完全磁盘访问设置`。
- 状态项是信息与入口，不承载 Finder 文件操作。

## 5. Finder 上下文与菜单生成

### 5.1 上下文模型

```swift
enum FinderSelectionKind {
    case containerBackground
    case singleFile
    case singleDirectory
    case multipleItems
}

struct FinderContext {
    let kind: FinderSelectionKind
    let selectedURLs: [URL]
    let actionDirectory: URL?
}
```

解析优先级：

1. `targetedURL()` 是目录时，使用它作为 `actionDirectory`。
2. `targetedURL()` 是文件时，使用其父目录。
3. 单选使用 `selectedItemURLs()` 的唯一项：目录使用自身，文件使用父目录。
4. 多选没有 `actionDirectory`，只允许复制动作。
5. 无法解析或目录不在授权根目录内时，返回不可操作上下文。

所有目标 URL 都必须进行标准化，并验证其路径位于授权目录根内。符号链接、失效 URL 或越界路径均不执行操作。

### 5.2 菜单构建

- 对 Finder 的 contextual menu 类型构建菜单；非右键菜单不作为 MVP 入口。
- 只在 `MenuVisibilityPolicy` 返回至少一个动作时添加 `SupRight` 顶层菜单。
- “新建文件”使用子菜单；复制、终端操作为同级条目。
- 如果 Finder 展示扩展工具栏入口，必须提供名称、图标与可理解的菜单，禁止留下空白工具栏按钮；该入口不是 MVP 验收路径。

## 6. 文件创建设计

### 6.1 通用创建流程

```text
确认 actionDirectory 已授权且可写
  → FileNameAllocator 生成未占用文件名
  → 创建临时文件或复制模板到临时目标
  → 原子移动到最终文件名
  → Finder 选中新文件
```

文件名分配：先尝试 `Untitled.ext`，存在则从 `Untitled 2.ext` 递增。检查和创建发生在同一目标目录；创建遇到竞争条件时重新分配并重试有限次数。

### 6.2 文本与 RTF

| 类型 | 扩展名 | 内容 |
| --- | --- | --- |
| 文本文档 | `.txt` | 空 UTF-8 文件 |
| Markdown | `.md` | 空 UTF-8 文件 |
| JSON | `.json` | 空 UTF-8 文件（MVP 不自动写入 `{}`） |
| RTF | `.rtf` | 最小有效 RTF 文档，例如只包含一个空段落 |

### 6.3 Office 模板

DOCX、XLSX、PPTX 使用项目原创的最小空白 OOXML 模板。

- 模板路径：`SupRightFinderExtension/Resources/Templates/Blank.docx`、`Blank.xlsx`、`Blank.pptx`。
- 模板作为 target resource 打包，运行时通过 `Bundle` 查找并复制。
- DOCX/XLSX 的生成与三个模板的 ZIP 校验脚本位于 `Scripts/generate-office-templates.sh`，仅用于开发与再生成，不进入运行时。PPTX 由空白 Keynote 文稿导出后保存为同一资源目录的 `Blank.pptx`。
- 运行时不解析、不修改模板内部 ZIP/XML；只做安全复制、重名分配和原子替换。
- 每个模板的测试至少验证：`unzip -t` 成功、必要的 OOXML 内容类型和主文档 XML 存在、macOS 上有对应应用时可人工打开。

## 7. 复制与终端

### 7.1 剪贴板

- 使用 `NSPasteboard.general`，清空后写入一个 UTF-8 纯文本字符串。
- 单选：名称或 POSIX 完整路径。
- 多选：按照 Finder 提供的 URL 顺序，以换行连接。
- 不向剪贴板写入文件 URL、富文本或私有格式。

### 7.2 Terminal.app

- 目标目录由 `FinderContext.actionDirectory` 提供。
- 使用 `NSWorkspace` 通过 Terminal 的 bundle identifier `com.apple.Terminal` 启动，并把目录 URL 作为打开项目传递。
- 不使用 AppleScript，不模拟键盘输入，不拼接或执行 Shell 命令。
- Terminal 缺失或启动失败时，将底层错误映射为“无法打开终端”。

## 8. 错误模型

| 原因 | 用户文案 | 系统行为 |
| --- | --- | --- |
| 未授权或书签失效 | `需要重新授权工作目录。` | 主 App 显示重新授权状态；扩展隐藏菜单 |
| 目录不可写 | `无法在“目录名”中创建文件。` | 不创建半成品 |
| 模板缺失/损坏 | `无法创建此类型的文件。` | 记录开发日志；不显示原始 ZIP 错误 |
| 剪贴板写入失败 | `无法复制所选项目。` | 不改变文件 |
| Terminal 启动失败 | `无法打开终端。` | 不执行替代 Shell 命令 |
| 路径越过授权根目录 | `此位置未获授权。` | 拒绝操作 |

警告框统一使用 `NSAlert`；成功的新建和复制保持静默。

## 9. 测试策略

### 9.1 单元测试

| 组件 | 覆盖重点 |
| --- | --- |
| `MenuVisibilityPolicy` | 五种 Finder 上下文的可见项 |
| `FinderContextResolver` | 文件、目录、多选、失效 URL、授权根校验 |
| `FileNameAllocator` | 无重名、连续重名、含空格路径、并发冲突重试 |
| `FileCreationService` | TXT/MD/JSON 内容、RTF 基本结构、失败不留半成品 |
| `TemplateCatalog` | 三个模板可找到、存在必要 ZIP/XML 条目 |
| `PasteboardWriter` | 单选、多选、换行和路径编码 |

### 9.2 手工集成测试

- 在授权目录、子目录和未授权目录中检查菜单可见性。
- 覆盖空白处、单文件、单文件夹和多选右键。
- 覆盖七种预设新建文件、“自定义文件…”完整文件名输入、自动重名、文件选中和创建失败。
- 覆盖 Terminal 目标目录、复制名称/路径。
- 覆盖主 App 退出、Finder 重启、扩展进程重启、重新授权与目录失效。
- 在 macOS 14/15 和当前 macOS 上各完成一轮基础回归。

## 10. 实施顺序

1. **权限持久性验证（完成）**：主 App 退出、Finder 与扩展重启后，菜单和 TXT 创建仍可用。
2. **共享纯逻辑**：提取文件名分配、上下文解析、可见性策略，并添加单元测试。
3. **文本创建**：实现 TXT、Markdown、JSON、RTF 与嵌套菜单。
4. **Office 模板**：创建、校验、打包 DOCX/XLSX/PPTX 模板，再接入复制创建流程。
5. **Finder 辅助动作**：实现复制名称、路径和 Terminal 打开。
6. **主 App 状态**：展示授权、失效和重新授权状态。
7. **回归与文档**：完成验收矩阵、README 构建说明和已知限制。

## 11. 完成判定

只有同时满足以下条件，MVP 才算完成：

- [MVP_PRD](MVP_PRD.md) 的验收标准全部通过。
- [MVP_UI_SPEC](MVP_UI_SPEC.md) 的菜单、状态、文案没有未实现项。
- 授权目录在主 App 退出和 Finder/扩展重启后仍可恢复。
- 所有新建操作不覆盖现有文件，也不遗留半成品。
- Debug 构建、相关单元测试及手工 Finder 验收均成功。
