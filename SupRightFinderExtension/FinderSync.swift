import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {
    private enum Configuration {
        static let appGroup = "4VZQ365DP6.com.iiimac.SupRight"
        static let finderOperationLaunchKey = "finder-operation-launch"
        static let containingAppBundleIdentifier = "com.iiimac.SupRight"
    }

    private enum MenuFeature: String {
        case createText = "create-text"
        case createMarkdown = "create-markdown"
        case createJSON = "create-json"
        case createRTF = "create-rtf"
        case createWord = "create-word"
        case createExcel = "create-excel"
        case createPowerPoint = "create-powerpoint"
        case createCustom = "create-custom"
        case copyNames = "copy-names"
        case copyPaths = "copy-paths"
        case openTerminal = "open-terminal"

        var preferenceKey: String { "menu-feature.\(rawValue)" }
    }

    private var menuDestination: URL?
    private var menuSelection: [URL] = []

    private enum NewFileType: String, CaseIterable {
        case text
        case markdown
        case json
        case rtf
        case word
        case excel
        case powerPoint
        case custom

        var menuFeature: MenuFeature {
            switch self {
            case .text: .createText
            case .markdown: .createMarkdown
            case .json: .createJSON
            case .rtf: .createRTF
            case .word: .createWord
            case .excel: .createExcel
            case .powerPoint: .createPowerPoint
            case .custom: .createCustom
            }
        }

        var menuTitle: String {
            switch self {
            case .text: FinderSync.localized("文本文档（.txt）", "Text document (.txt)")
            case .markdown: FinderSync.localized("Markdown 文档（.md）", "Markdown document (.md)")
            case .json: FinderSync.localized("JSON 文件（.json）", "JSON file (.json)")
            case .rtf: FinderSync.localized("RTF 文档（.rtf）", "RTF document (.rtf)")
            case .word: FinderSync.localized("Word 文档（.docx）", "Word document (.docx)")
            case .excel: FinderSync.localized("Excel 工作簿（.xlsx）", "Excel workbook (.xlsx)")
            case .powerPoint: FinderSync.localized("PowerPoint 演示文稿（.pptx）", "PowerPoint presentation (.pptx)")
            case .custom: FinderSync.localized("自定义文件…", "Custom File…")
            }
        }

    }

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu()
        guard let destination = destinationDirectory() else {
            return menu
        }
        menuDestination = destination
        menuSelection = FIFinderSyncController.default().selectedItemURLs() ?? []

        let supRightItem = NSMenuItem(title: "SupRight", action: nil, keyEquivalent: "")
        let supRightMenu = NSMenu(title: "SupRight")
        let newFileItem = NSMenuItem(title: Self.localized("新建文件", "New File"), action: nil, keyEquivalent: "")
        let newFileMenu = NSMenu(title: Self.localized("新建文件", "New File"))

        for fileType in NewFileType.allCases where isFeatureEnabled(fileType.menuFeature) {
            let item = NSMenuItem(
                title: fileType.menuTitle,
                action: action(for: fileType),
                keyEquivalent: ""
            )
            item.target = self
            newFileMenu.addItem(item)
        }

        if !newFileMenu.items.isEmpty {
            newFileItem.submenu = newFileMenu
            supRightMenu.addItem(newFileItem)
        }

        if !menuSelection.isEmpty, isFeatureEnabled(.copyNames) {
            supRightMenu.addItem(menuItem(title: Self.localized("复制文件名", "Copy file name"), action: #selector(copyNames(_:))))
        }

        if !menuSelection.isEmpty, isFeatureEnabled(.copyPaths) {
            supRightMenu.addItem(menuItem(title: Self.localized("复制完整路径", "Copy full path"), action: #selector(copyPaths(_:))))
        }

        if menuSelection.count <= 1, isFeatureEnabled(.openTerminal) {
            supRightMenu.addItem(menuItem(title: Self.localized("在终端中打开", "Open in Terminal"), action: #selector(openInTerminal(_:))))
        }

        guard !supRightMenu.items.isEmpty else {
            return menu
        }

        supRightItem.submenu = supRightMenu
        menu.addItem(supRightItem)
        return menu
    }

    @objc private func createTextFile(_ sender: NSMenuItem) { createFile(of: .text) }
    @objc private func createMarkdownFile(_ sender: NSMenuItem) { createFile(of: .markdown) }
    @objc private func createJSONFile(_ sender: NSMenuItem) { createFile(of: .json) }
    @objc private func createRTFFile(_ sender: NSMenuItem) { createFile(of: .rtf) }
    @objc private func createWordFile(_ sender: NSMenuItem) { createFile(of: .word) }
    @objc private func createExcelFile(_ sender: NSMenuItem) { createFile(of: .excel) }
    @objc private func createPowerPointFile(_ sender: NSMenuItem) { createFile(of: .powerPoint) }
    @objc private func createCustomFile(_ sender: NSMenuItem) { createFile(of: .custom) }

    private func action(for fileType: NewFileType) -> Selector {
        switch fileType {
        case .text: #selector(createTextFile(_:))
        case .markdown: #selector(createMarkdownFile(_:))
        case .json: #selector(createJSONFile(_:))
        case .rtf: #selector(createRTFFile(_:))
        case .word: #selector(createWordFile(_:))
        case .excel: #selector(createExcelFile(_:))
        case .powerPoint: #selector(createPowerPointFile(_:))
        case .custom: #selector(createCustomFile(_:))
        }
    }

    private func menuItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func isFeatureEnabled(_ feature: MenuFeature) -> Bool {
        let defaults = UserDefaults(suiteName: Configuration.appGroup)
        guard defaults?.object(forKey: feature.preferenceKey) != nil else {
            return true
        }
        return defaults?.bool(forKey: feature.preferenceKey) ?? true
    }

    private func createFile(of fileType: NewFileType) {
        guard let destination = menuDestination ?? destinationDirectory() else {
            showError(message: Self.localized("无法确定新文件的位置。", "Unable to determine where to create the file."))
            return
        }
        submit(.init(
            id: UUID(),
            kind: fileType.rawValue,
            destinationPath: destination.path,
            selectionPaths: [],
            customFileName: nil
        ))
    }

    @objc private func copyNames(_ sender: NSMenuItem) {
        submit(.init(
            id: UUID(),
            kind: "copyNames",
            destinationPath: nil,
            selectionPaths: menuSelection.map(\.path),
            customFileName: nil
        ))
    }

    @objc private func copyPaths(_ sender: NSMenuItem) {
        submit(.init(
            id: UUID(),
            kind: "copyPaths",
            destinationPath: nil,
            selectionPaths: menuSelection.map(\.path),
            customFileName: nil
        ))
    }

    @objc private func openInTerminal(_ sender: NSMenuItem) {
        guard let directory = menuDestination else {
            showError(message: Self.localized("无法打开终端。", "Unable to open Terminal."))
            return
        }
        submit(.init(
            id: UUID(),
            kind: "openTerminal",
            destinationPath: directory.path,
            selectionPaths: [],
            customFileName: nil
        ))
    }

    private func destinationDirectory() -> URL? {
        let controller = FIFinderSyncController.default()
        let candidate = controller.targetedURL() ?? controller.selectedItemURLs()?.first

        guard let candidate else {
            return nil
        }

        let values = try? candidate.resourceValues(forKeys: [.isDirectoryKey])
        return values?.isDirectory == true ? candidate : candidate.deletingLastPathComponent()
    }

    private struct Operation: Codable {
        let id: UUID
        let kind: String
        let destinationPath: String?
        let selectionPaths: [String]
        let customFileName: String?
    }

    private func submit(_ operation: Operation) {
        guard let defaults = UserDefaults(suiteName: Configuration.appGroup) else {
            showError(message: Self.localized("无法连接 SupRight 主程序。", "Unable to reach the SupRight app."))
            return
        }

        let key = "pending-finder-operations"
        let existing: [Operation]
        if let data = defaults.data(forKey: key) {
            existing = (try? JSONDecoder().decode([Operation].self, from: data)) ?? []
        } else {
            existing = []
        }
        guard let data = try? JSONEncoder().encode(existing + [operation]) else {
            showError(message: Self.localized("无法提交 SupRight 操作。", "Unable to submit the SupRight action."))
            return
        }

        defaults.set(data, forKey: key)
        if !isContainingAppRunning() {
            defaults.set(true, forKey: Configuration.finderOperationLaunchKey)
            defaults.synchronize()
            launchContainingApp()
        } else {
            defaults.synchronize()
        }
        let name = CFNotificationName("4VZQ365DP6.com.iiimac.SupRight.operation-request" as CFString)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            name,
            nil,
            nil,
            true
        )
    }

    private func launchContainingApp() {
        let appURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        guard appURL.pathExtension == "app" else { return }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
    }

    private func isContainingAppRunning() -> Bool {
        !NSRunningApplication.runningApplications(
            withBundleIdentifier: Configuration.containingAppBundleIdentifier
        ).isEmpty
    }

    private func showError(message: String) {
        let alert = NSAlert()
        alert.messageText = "SupRight"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private static func localized(_ chinese: String, _ english: String) -> String {
        let defaults = UserDefaults(suiteName: Configuration.appGroup)
        let preference = SupRightLanguagePreference(rawValue: defaults?.string(forKey: "app-language") ?? "") ?? .system
        let usesEnglish = preference == .english || (preference == .system && Locale.current.language.languageCode?.identifier != "zh")
        return usesEnglish ? english : chinese
    }

}

private enum SupRightLanguagePreference: String {
    case system
    case simplifiedChinese
    case english
}
