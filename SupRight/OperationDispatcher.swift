import AppKit
import Foundation

/// Executes Finder-originated actions in the unsandboxed containing app.
/// Finder Sync stays sandboxed by macOS, so it only queues explicit user actions.
@MainActor
final class SupRightOperationDispatcher: NSObject {
    private static let appGroup = "4VZQ365DP6.com.iiimac.SupRight"
    private static let pendingOperationsKey = "pending-finder-operations"
    private static let notificationName = CFNotificationName(
        "4VZQ365DP6.com.iiimac.SupRight.operation-request" as CFString
    )

    private enum Kind: String, Codable {
        case text, markdown, json, rtf, word, excel, powerPoint, custom
        case copyNames, copyPaths, openTerminal
    }

    private struct Operation: Codable {
        let id: UUID
        let kind: Kind
        let destinationPath: String?
        let selectionPaths: [String]
        let customFileName: String?
    }

    static let shared = SupRightOperationDispatcher()

    private let fileManager = FileManager.default
    private let defaults = UserDefaults(suiteName: appGroup) ?? .standard

    func start() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            Self.receiveOperationNotification,
            Self.notificationName.rawValue,
            nil,
            .deliverImmediately
        )
        processPendingOperations()
    }

    private static let receiveOperationNotification: CFNotificationCallback = { _, observer, _, _, _ in
        guard let observer else { return }
        let dispatcher = Unmanaged<SupRightOperationDispatcher>
            .fromOpaque(observer)
            .takeUnretainedValue()
        DispatchQueue.main.async {
            dispatcher.processPendingOperations()
        }
    }

    private func processPendingOperations() {
        let operations = pendingOperations()
        guard !operations.isEmpty else { return }

        defaults.removeObject(forKey: Self.pendingOperationsKey)
        defaults.synchronize()

        for operation in operations {
            do {
                try execute(operation)
            } catch {
                showError(for: operation, error: error)
            }
        }
    }

    private func pendingOperations() -> [Operation] {
        guard let data = defaults.data(forKey: Self.pendingOperationsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([Operation].self, from: data)) ?? []
    }

    private func execute(_ operation: Operation) throws {
        switch operation.kind {
        case .copyNames:
            try copy(operation.selectionPaths.map { URL(fileURLWithPath: $0).lastPathComponent })
        case .copyPaths:
            try copy(operation.selectionPaths)
        case .openTerminal:
            guard let destinationPath = operation.destinationPath,
                  let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
            else {
                throw CocoaError(.fileNoSuchFile)
            }
            NSWorkspace.shared.open(
                [URL(fileURLWithPath: destinationPath)],
                withApplicationAt: terminalURL,
                configuration: NSWorkspace.OpenConfiguration()
            )
        case .text, .markdown, .json, .rtf, .word, .excel, .powerPoint:
            guard let destinationPath = operation.destinationPath else {
                throw CocoaError(.fileNoSuchFile)
            }
            let fileURL = try createFile(of: operation.kind, in: URL(fileURLWithPath: destinationPath))
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        case .custom:
            guard let destinationPath = operation.destinationPath,
                  let fileName = requestCustomFileName()
            else {
                return
            }
            let fileURL = try createCustomFile(named: fileName, in: URL(fileURLWithPath: destinationPath))
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }

    private func copy(_ values: [String]) throws {
        guard !values.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setString(values.joined(separator: "\n"), forType: .string) else {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    private func createFile(of kind: Kind, in directory: URL) throws -> URL {
        for suffix in 1...100 {
            let fileURL = fileURL(for: kind, suffix: suffix, in: directory)
            guard !fileManager.fileExists(atPath: fileURL.path) else { continue }

            if let templateURL = templateURL(for: kind) {
                try fileManager.copyItem(at: templateURL, to: fileURL)
                return fileURL
            }

            guard !requiresTemplate(kind),
                  fileManager.createFile(atPath: fileURL.path, contents: contents(for: kind))
            else {
                continue
            }
            return fileURL
        }
        throw CocoaError(.fileWriteFileExists)
    }

    private func requestCustomFileName() -> String? {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = supRightText("新建自定义文件", "Create Custom File")
        alert.informativeText = supRightText(
            "请输入完整文件名，例如 Untitled.py 或 config.yaml。",
            "Enter a complete file name, for example Untitled.py or config.yaml."
        )
        alert.addButton(withTitle: supRightText("创建", "Create"))
        alert.addButton(withTitle: supRightText("取消", "Cancel"))

        let field = NSTextField(string: "")
        field.placeholderString = supRightText("例如 Untitled.py", "For example: Untitled.py")
        field.frame = NSRect(x: 0, y: 0, width: 320, height: 24)
        alert.accessoryView = field

        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue
    }

    private func createCustomFile(named rawName: String, in directory: URL) throws -> URL {
        let fileName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidCustomFileName(fileName) else {
            throw CustomFileError.invalidName
        }

        let sourceURL = URL(fileURLWithPath: fileName)
        let stem = sourceURL.deletingPathExtension().lastPathComponent
        let fileExtension = sourceURL.pathExtension

        for suffix in 1...100 {
            let name: String
            if suffix == 1 {
                name = fileName
            } else if fileExtension.isEmpty {
                name = "\(stem) \(suffix)"
            } else {
                name = "\(stem) \(suffix).\(fileExtension)"
            }

            let fileURL = directory.appendingPathComponent(name)
            guard !fileManager.fileExists(atPath: fileURL.path) else { continue }
            guard fileManager.createFile(atPath: fileURL.path, contents: Data()) else { continue }
            return fileURL
        }

        throw CocoaError(.fileWriteFileExists)
    }

    private func isValidCustomFileName(_ name: String) -> Bool {
        guard !name.isEmpty, name != ".", name != ".." else { return false }
        return !name.contains("/") && !name.contains("\\") && !name.contains("\0")
    }

    private func fileURL(for kind: Kind, suffix: Int, in directory: URL) -> URL {
        let name = suffix == 1 ? "Untitled" : "Untitled \(suffix)"
        return directory
            .appendingPathComponent(name)
            .appendingPathExtension(fileExtension(for: kind))
    }

    private func fileExtension(for kind: Kind) -> String {
        switch kind {
        case .text: "txt"
        case .markdown: "md"
        case .json: "json"
        case .rtf: "rtf"
        case .word: "docx"
        case .excel: "xlsx"
        case .powerPoint: "pptx"
        case .copyNames, .copyPaths, .openTerminal, .custom: ""
        }
    }

    private func contents(for kind: Kind) -> Data {
        kind == .rtf ? Data("{\\rtf1\\ansi\\deff0\\pard\\par}\\n".utf8) : Data()
    }

    private func requiresTemplate(_ kind: Kind) -> Bool {
        switch kind {
        case .word, .excel, .powerPoint: true
        default: false
        }
    }

    private func templateURL(for kind: Kind) -> URL? {
        let extensionResources = Bundle.main.builtInPlugInsURL?
            .appendingPathComponent("SupRightFinderExtension.appex")
            .appendingPathComponent("Contents/Resources")
        let fileName: String
        switch kind {
        case .word: fileName = "Blank.docx"
        case .excel: fileName = "Blank.xlsx"
        case .powerPoint: fileName = "Blank.pptx"
        default: return nil
        }
        let url = extensionResources?.appendingPathComponent(fileName)
        return url.flatMap { fileManager.fileExists(atPath: $0.path) ? $0 : nil }
    }

    private func showError(for operation: Operation, error: Error) {
        let message: String
        switch operation.kind {
        case .copyNames, .copyPaths:
            message = supRightText("无法复制所选项目。", "Unable to copy the selected items.")
        case .openTerminal:
            message = supRightText("无法打开终端。", "Unable to open Terminal.")
        case .custom where error is CustomFileError:
            message = supRightText("请输入有效的文件名，例如 Untitled.py。", "Enter a valid file name, for example Untitled.py.")
        default:
            let name = operation.destinationPath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "目标目录"
            message = supRightText("无法在“\(name)”中创建文件。请确认完全磁盘访问和目录写入权限。", "Unable to create a file in “\(name)”. Confirm Full Disk Access and directory write permission.")
        }
        let alert = NSAlert()
        alert.messageText = "SupRight"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private enum CustomFileError: Error {
        case invalidName
    }
}
