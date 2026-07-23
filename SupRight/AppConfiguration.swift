import AppKit
import FinderSync
import ServiceManagement
import SwiftUI

enum SupRightFeature: String, CaseIterable, Identifiable {
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

    static let newFileFeatures: [SupRightFeature] = [
        .createText, .createMarkdown, .createJSON, .createRTF,
        .createWord, .createExcel, .createPowerPoint, .createCustom
    ]

    static let utilityFeatures: [SupRightFeature] = [.copyNames, .copyPaths, .openTerminal]

    var id: String { rawValue }
    var preferenceKey: String { "menu-feature.\(rawValue)" }

    var title: String {
        switch self {
        case .createText: supRightText("文本文档（.txt）", "Text document (.txt)")
        case .createMarkdown: supRightText("Markdown 文档（.md）", "Markdown document (.md)")
        case .createJSON: supRightText("JSON 文件（.json）", "JSON file (.json)")
        case .createRTF: supRightText("RTF 文档（.rtf）", "RTF document (.rtf)")
        case .createWord: supRightText("Word 文档（.docx）", "Word document (.docx)")
        case .createExcel: supRightText("Excel 工作簿（.xlsx）", "Excel workbook (.xlsx)")
        case .createPowerPoint: supRightText("PowerPoint 演示文稿（.pptx）", "PowerPoint presentation (.pptx)")
        case .createCustom: supRightText("自定义文件（输入文件名）", "Custom file (enter name)")
        case .copyNames: supRightText("复制文件名", "Copy file name")
        case .copyPaths: supRightText("复制完整路径", "Copy full path")
        case .openTerminal: supRightText("在终端中打开", "Open in Terminal")
        }
    }
}

enum SupRightLanguage: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese
    case english

    var id: String { rawValue }

    var effective: SupRightLanguage {
        guard self == .system else { return self }
        return Locale.current.language.languageCode?.identifier == "zh" ? .simplifiedChinese : .english
    }

    var displayName: String {
        switch self {
        case .system: "跟随系统 / System"
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        }
    }

    func text(_ chinese: String, _ english: String) -> String {
        effective == .english ? english : chinese
    }
}

func supRightText(_ chinese: String, _ english: String) -> String {
    let defaults = UserDefaults(suiteName: "4VZQ365DP6.com.iiimac.SupRight") ?? .standard
    let language = SupRightLanguage(rawValue: defaults.string(forKey: "app-language") ?? "") ?? .system
    return language.text(chinese, english)
}

@MainActor
enum SupRightConfiguration {
    static let appGroup = "4VZQ365DP6.com.iiimac.SupRight"
    static let defaults = UserDefaults(suiteName: appGroup) ?? .standard
    static let menuBarVisibleKey = "menu-bar-visible"
    static let languageKey = "app-language"
    static let finderExtensionLastActiveKey = "finder-extension-last-active"

    static var launchesAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var launchAtLoginNeedsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static func setLaunchAtLogin(_ enabled: Bool) throws {
        let service = SMAppService.mainApp

        if enabled {
            guard service.status == .notRegistered else { return }
            try service.register()
        } else {
            guard service.status != .notRegistered else { return }
            try service.unregister()
        }
    }

    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    static var enabledFeatureCount: Int {
        var count = 0
        for feature in SupRightFeature.allCases where isEnabled(feature) {
            count += 1
        }
        return count
    }

    static func isEnabled(_ feature: SupRightFeature) -> Bool {
        guard defaults.object(forKey: feature.preferenceKey) != nil else {
            return true
        }
        return defaults.bool(forKey: feature.preferenceKey)
    }

    static var finderExtensionEnabled: Bool {
        if FIFinderSyncController.isExtensionEnabled {
            return true
        }

        // In Xcode-run builds, macOS can report `false` even while the Finder
        // Sync extension is serving contextual menus. A recent activity ping is
        // therefore the more useful signal for the app's diagnostic UI.
        let lastActive = defaults.double(forKey: finderExtensionLastActiveKey)
        return lastActive > Date().timeIntervalSince1970 - 24 * 60 * 60
    }

    /// macOS does not expose a public API for reading the Full Disk Access
    /// switch. Verify it by reading a protected user directory instead.
    /// An inconclusive result deliberately keeps the reminder visible.
    static var hasFullDiskAccess: Bool {
        let fileManager = FileManager.default
        let libraryDirectory = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
        let candidates = ["Safari", "Mail", "Messages", "Calendars"]

        for name in candidates {
            let directory = libraryDirectory.appendingPathComponent(name, isDirectory: true)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }

            do {
                _ = try fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                return true
            } catch {
                return false
            }
        }

        return false
    }

    static func openFullDiskAccessSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
        ]

        for value in urls {
            if let url = URL(string: value), NSWorkspace.shared.open(url) {
                return
            }
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    static func openAppWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.unhide(nil)
        NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
    }

    static func openExtensionManagement() {
        FIFinderSyncController.showExtensionManagementInterface()
    }
}
