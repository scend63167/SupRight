import AppKit
import SwiftUI

private enum SupRightPalette {
    static let pink = Color(red: 1.0, green: 0.675, blue: 0.855)
    static let blue = Color(red: 0.055, green: 0.757, blue: 1.0)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let softPink = pink.opacity(0.13)
    static let softBlue = blue.opacity(0.12)

    static let gradient = LinearGradient(
        colors: [pink, blue],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let softGradient = LinearGradient(
        colors: [softPink, softBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ContentView: View {
    @State private var selection: SettingsSection = .overview
    @AppStorage(SupRightConfiguration.languageKey, store: SupRightConfiguration.defaults) private var languageRawValue = SupRightLanguage.system.rawValue

    var body: some View {
        let _ = languageRawValue
        HStack(spacing: 0) {
            SettingsSidebar(selection: $selection)
                .frame(width: 258)

            Divider()

            ScrollView {
                Group {
                    switch selection {
                    case .overview:
                        OverviewPage()
                    case .menuFeatures:
                        MenuFeaturesPage()
                    case .diagnostics:
                        DiagnosticsPage()
                    case .language:
                        LanguagePage()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(48)
            }
            .background(
                LinearGradient(
                    colors: [Color.white, SupRightPalette.softBlue.opacity(0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .frame(minWidth: 920, idealWidth: 980, minHeight: 620, idealHeight: 680)
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case overview
    case menuFeatures
    case diagnostics
    case language

    var id: String { rawValue }

    var title: String {
        switch self {
        case .menuFeatures: supRightText("菜单功能", "Menu Features")
        case .overview: supRightText("概览", "Overview")
        case .diagnostics: supRightText("诊断", "Diagnostics")
        case .language: supRightText("语言", "Language")
        }
    }

    var icon: String {
        switch self {
        case .menuFeatures: "slider.horizontal.3"
        case .overview: "circle.grid.2x2"
        case .diagnostics: "stethoscope"
        case .language: "globe"
        }
    }
}

private struct SettingsSidebar: View {
    @Binding var selection: SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: SupRightPalette.pink.opacity(0.22), radius: 10, y: 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text("SupRight")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SupRightPalette.ink)
                    Text(supRightText("Finder 右键增强", "Finder right-click utility"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 30)
            .padding(.bottom, 34)

            ForEach(SettingsSection.allCases) { section in
                SidebarNavigationRow(
                    section: section,
                    isSelected: selection == section
                ) {
                    selection = section
                }
            }

            Spacer()

            Divider()
                .padding(.horizontal, 22)

            HStack(spacing: 8) {
                Circle()
                    .fill(SupRightConfiguration.finderExtensionEnabled ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(finderExtensionStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(22)
        }
        .background(
            LinearGradient(
                colors: [SupRightPalette.softPink.opacity(0.72), SupRightPalette.softBlue.opacity(0.76)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var finderExtensionStatusText: String {
        if SupRightConfiguration.isRunningFromAppTranslocation {
            return supRightText("请移至“应用程序”", "Move to Applications")
        }
        return SupRightConfiguration.finderExtensionEnabled
            ? supRightText("Finder 扩展已启用", "Finder extension enabled")
            : supRightText("Finder 扩展待确认", "Finder extension needs attention")
    }
}

private struct SidebarNavigationRow: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(section.title, systemImage: section.icon)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? SupRightPalette.ink : Color.primary)
        .background(
            isSelected ? SupRightPalette.softGradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
        .padding(.horizontal, 10)
    }
}

private struct LanguagePage: View {
    @AppStorage(SupRightConfiguration.languageKey, store: SupRightConfiguration.defaults) private var languageRawValue = SupRightLanguage.system.rawValue

    private var selectedLanguage: Binding<SupRightLanguage> {
        Binding(
            get: { SupRightLanguage(rawValue: languageRawValue) ?? .system },
            set: { languageRawValue = $0.rawValue }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(
                title: supRightText("语言", "Language"),
                subtitle: supRightText("选择 SupRight 在设置页面、菜单栏与 Finder 菜单中使用的语言。", "Choose the language used by SupRight in settings, the menu bar, and Finder menus.")
            )

            SettingsCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text(supRightText("显示语言", "Display language"))
                        .font(.title3.weight(.semibold))
                    Picker(supRightText("语言", "Language"), selection: selectedLanguage) {
                        ForEach(SupRightLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    Text(supRightText("修改后会立即应用；Finder 菜单在下一次右键时更新。", "Changes apply immediately; Finder menus update the next time you right-click."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct MenuFeaturesPage: View {
    @State private var enabledCount = SupRightConfiguration.enabledFeatureCount

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(
                title: supRightText("菜单功能", "Menu Features"),
                subtitle: supRightText("控制显示在 Finder 右键菜单中的操作。修改会在下一次右键时生效。", "Control the actions shown in Finder context menus. Changes apply on your next right-click."),
                status: supRightText("已启用 \(enabledCount) / \(SupRightFeature.allCases.count)", "\(enabledCount) / \(SupRightFeature.allCases.count) enabled")
            )

            SettingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label(supRightText("新建文件", "New Files"), systemImage: "doc.badge.plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SupRightPalette.ink)
                    Text(supRightText("选择允许在右键菜单中创建的文件类型。", "Choose the file types available from the context menu."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 28), GridItem(.flexible(), spacing: 28)],
                        alignment: .leading,
                        spacing: 18
                    ) {
                        ForEach(SupRightFeature.newFileFeatures) { feature in
                            FeatureToggleRow(feature: feature, didChange: refreshCount)
                        }
                    }
                    .padding(.top, 18)
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: 18) {
                    Label(supRightText("辅助操作", "Utilities"), systemImage: "wand.and.stars")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SupRightPalette.ink)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        alignment: .leading,
                        spacing: 18
                    ) {
                        ForEach(SupRightFeature.utilityFeatures) { feature in
                            FeatureToggleRow(feature: feature, didChange: refreshCount)
                        }
                    }
                }
            }

            PermissionNotice()
        }
    }

    private func refreshCount() {
        enabledCount = SupRightConfiguration.enabledFeatureCount
    }
}

private struct OverviewPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(
                title: supRightText("概览", "Overview"),
                subtitle: supRightText("SupRight 默认在 Finder 的所有目录中提供菜单。", "SupRight provides menus in all Finder directories by default."),
                status: supRightText("已启用 \(SupRightConfiguration.enabledFeatureCount) 项", "\(SupRightConfiguration.enabledFeatureCount) enabled")
            )

            if SupRightConfiguration.isRunningFromAppTranslocation {
                InstallationNotice()
            }

            HStack(spacing: 16) {
                SummaryCard(title: supRightText("菜单功能", "Menu Features"), value: "\(SupRightConfiguration.enabledFeatureCount) / \(SupRightFeature.allCases.count)", detail: supRightText("项已启用", "enabled"), color: .accentColor)
                SummaryCard(title: supRightText("Finder 扩展", "Finder Extension"), value: finderExtensionStatusText, detail: finderExtensionDetail, color: SupRightConfiguration.finderExtensionEnabled ? .green : .orange)
                SummaryCard(title: supRightText("目录范围", "Directory Scope"), value: supRightText("所有目录", "All directories"), detail: supRightText("由主程序执行操作", "Operations run in the app"), color: .purple)
            }

            BackgroundLaunchCard()

            PermissionNotice()
        }
    }

    private var finderExtensionStatusText: String {
        if SupRightConfiguration.isRunningFromAppTranslocation {
            return supRightText("需要安装", "Install required")
        }
        return SupRightConfiguration.finderExtensionEnabled
            ? supRightText("已启用", "Enabled")
            : supRightText("待确认", "Needs attention")
    }

    private var finderExtensionDetail: String {
        SupRightConfiguration.isRunningFromAppTranslocation
            ? supRightText("请移至“应用程序”", "Move to Applications")
            : supRightText("系统扩展状态", "Extension status")
    }
}

private struct BackgroundLaunchCard: View {
    @State private var launchesAtLogin = false
    @State private var needsApproval = false
    @State private var errorMessage: String?

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                Label(supRightText("后台启动", "Background Launch"), systemImage: "power.circle")
                    .font(.title3.weight(.semibold))

                Text(supRightText("登录 Mac 后自动启动 SupRight 并驻留在菜单栏。关闭设置窗口不会退出；你仍可从菜单栏选择“退出 SupRight”。", "Start SupRight at login and keep it in the menu bar. Closing the settings window does not quit the app; you can still quit it from the menu bar."))
                    .foregroundStyle(.secondary)

                Toggle(supRightText("登录时后台启动", "Launch in background at login"), isOn: Binding(
                    get: { launchesAtLogin },
                    set: { updateLaunchAtLogin($0) }
                ))
                .toggleStyle(SupRightToggleStyle())

                if needsApproval {
                    Label(supRightText("需要在系统设置中确认登录项权限。", "Approval is required in Login Items settings."), systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                Button(supRightText("打开登录项设置", "Open Login Items Settings")) {
                    SupRightConfiguration.openLoginItemsSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear(perform: refresh)
        .alert(supRightText("无法更新后台启动设置", "Unable to update background launch"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented { errorMessage = nil }
            }
        )) {
            Button(supRightText("好", "OK"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            try SupRightConfiguration.setLaunchAtLogin(enabled)
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    private func refresh() {
        launchesAtLogin = SupRightConfiguration.launchesAtLogin || SupRightConfiguration.launchAtLoginNeedsApproval
        needsApproval = SupRightConfiguration.launchAtLoginNeedsApproval
    }
}

private struct DiagnosticsPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(
                title: supRightText("诊断", "Diagnostics"),
                subtitle: supRightText("检查 SupRight 的基础运行状态，并在菜单未出现时快速定位问题。", "Check SupRight's basic runtime state and troubleshoot a missing menu.")
            )

            if SupRightConfiguration.isRunningFromAppTranslocation {
                InstallationNotice()
            }

            SettingsCard {
                VStack(spacing: 0) {
                    DiagnosticRow(
                        title: supRightText("Finder 扩展", "Finder Extension"),
                        value: finderExtensionStatusText,
                        color: SupRightConfiguration.finderExtensionEnabled ? .green : .orange
                    )
                    Divider()
                    DiagnosticRow(title: supRightText("菜单功能", "Menu Features"), value: supRightText("已启用 \(SupRightConfiguration.enabledFeatureCount) / \(SupRightFeature.allCases.count) 项", "\(SupRightConfiguration.enabledFeatureCount) / \(SupRightFeature.allCases.count) enabled"), color: .green)
                    Divider()
                    DiagnosticRow(title: supRightText("目录范围", "Directory Scope"), value: supRightText("所有 Finder 目录", "All Finder directories"), color: .green)
                    Divider()
                    DiagnosticRow(title: supRightText("执行方式", "Execution"), value: supRightText("主程序代为执行", "Run by the main app"), color: .green)
                }
            }

            HStack(spacing: 12) {
                Button(supRightText("查看系统扩展设置", "View Extension Settings")) {
                    SupRightConfiguration.openExtensionManagement()
                }
                .buttonStyle(.bordered)

                Button(supRightText("前往系统设置", "Open System Settings")) {
                    SupRightConfiguration.openFullDiskAccessSettings()
                }
                .buttonStyle(.bordered)
            }

            Text(supRightText("“文件提供程序”与 Finder Sync 是不同类别，SupRight 不会显示在那个列表中。完成安装后若菜单仍未出现，请重新打开 Finder 窗口。", "File Providers and Finder Sync are different extension categories, so SupRight will not appear in that list. After installation, reopen a Finder window if the menu is still missing."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var finderExtensionStatusText: String {
        if SupRightConfiguration.isRunningFromAppTranslocation {
            return supRightText("需移至“应用程序”", "Move to Applications")
        }
        return SupRightConfiguration.finderExtensionEnabled
            ? supRightText("已启用", "Enabled")
            : supRightText("待确认", "Needs attention")
    }
}

private struct InstallationNotice: View {
    var body: some View {
        SettingsCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 8) {
                    Text(supRightText("请先安装到“应用程序”", "Install SupRight in Applications first"))
                        .font(.headline)
                    Text(supRightText("SupRight 当前直接从“下载”打开，macOS 正在隔离运行它，Finder 右键菜单可能不会加载。请退出 SupRight，把 SupRight.app 拖到“应用程序”文件夹，再从那里重新打开。", "SupRight is running from Downloads in macOS app isolation, so Finder may not load its context menu. Quit SupRight, drag SupRight.app to Applications, then open it from there."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button(supRightText("打开“应用程序”文件夹", "Open Applications Folder")) {
                        SupRightConfiguration.openApplicationsFolder()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

private struct PageHeader: View {
    let title: String
    let subtitle: String
    var status: String?

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(SupRightPalette.ink)
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let status {
                Label(status, systemImage: "circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SupRightPalette.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(SupRightPalette.softGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SupRightPalette.gradient, lineWidth: 1)
            }
            .shadow(color: SupRightPalette.blue.opacity(0.06), radius: 16, y: 6)
    }
}

private struct FeatureToggleRow: View {
    let feature: SupRightFeature
    let didChange: () -> Void
    @AppStorage private var isEnabled: Bool

    init(feature: SupRightFeature, didChange: @escaping () -> Void) {
        self.feature = feature
        self.didChange = didChange
        _isEnabled = AppStorage(wrappedValue: true, feature.preferenceKey, store: SupRightConfiguration.defaults)
    }

    var body: some View {
        Toggle(feature.title, isOn: $isEnabled)
            .toggleStyle(SupRightToggleStyle())
            .onChange(of: isEnabled) { _, _ in
                didChange()
            }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let detail: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
            Label(detail, systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(color)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SupRightPalette.gradient.opacity(0.65), lineWidth: 1)
        }
    }
}

private struct DiagnosticRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Label(value, systemImage: "circle.fill")
                .font(.subheadline)
                .foregroundStyle(color)
        }
        .padding(.vertical, 15)
    }
}

private struct PermissionNotice: View {
    @State private var hasFullDiskAccess = SupRightConfiguration.hasFullDiskAccess

    var body: some View {
        Group {
            if !hasFullDiskAccess {
                HStack(spacing: 14) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(supRightText("请在系统设置中确认完全磁盘访问", "Confirm Full Disk Access in System Settings"))
                            .font(.subheadline.weight(.semibold))
                        Text(supRightText("写入由主程序执行；只读或系统保护位置仍可能无法创建文件。", "Writing is handled by the main app; read-only or system-protected locations can still reject file creation."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(supRightText("前往系统设置", "Open System Settings")) {
                        SupRightConfiguration.openFullDiskAccessSettings()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(18)
                .background(SupRightPalette.softGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(SupRightPalette.gradient, lineWidth: 1)
                }
            }
        }
        .onAppear {
            hasFullDiskAccess = SupRightConfiguration.hasFullDiskAccess
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasFullDiskAccess = SupRightConfiguration.hasFullDiskAccess
        }
    }
}

private struct SupRightToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 14) {
            configuration.label
                .foregroundStyle(SupRightPalette.ink)

            Spacer(minLength: 12)

            Button {
                configuration.isOn.toggle()
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(configuration.isOn ? AnyShapeStyle(SupRightPalette.gradient) : AnyShapeStyle(Color.black.opacity(0.12)))
                        .frame(width: 48, height: 28)

                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.13), radius: 3, y: 1)
                        .padding(3)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(configuration.isOn ? supRightText("关闭", "Turn off") : supRightText("开启", "Turn on"))
        }
    }
}

#Preview {
    ContentView()
}
