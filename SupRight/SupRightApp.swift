//
//  SupRightApp.swift
//  SupRight
//
//  Created by iiimac on 2026/7/23.
//

import AppKit
import SwiftUI

@main
struct SupRightApp: App {
    @NSApplicationDelegateAdaptor(SupRightAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class SupRightAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let featureSummaryItem = NSMenuItem()
    private let extensionStateItem = NSMenuItem()
    private let diskAccessItem = NSMenuItem()
    private let openSettingsItem = NSMenuItem()
    private let openSystemSettingsItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private var suppressesInitialWindow = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        suppressesInitialWindow = SupRightConfiguration.consumeFinderOperationLaunch()
        SupRightOperationDispatcher.shared.start()
        installStatusItem()

        if SupRightConfiguration.launchesAtLogin || suppressesInitialWindow {
            DispatchQueue.main.async {
                NSApp.hide(nil)
                self.suppressesInitialWindow = false
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, !suppressesInitialWindow {
            SupRightConfiguration.openAppWindow()
        }
        return true
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        guard let button = item.button else { return }
        button.image = SupRightMenuBarImage.makeImage()
        button.imagePosition = .imageOnly
        button.toolTip = "SupRight"
        button.setAccessibilityLabel("SupRight")

        let menu = NSMenu()
        menu.delegate = self

        featureSummaryItem.isEnabled = false
        extensionStateItem.isEnabled = false
        diskAccessItem.isEnabled = false

        openSettingsItem.target = self
        openSettingsItem.action = #selector(openSettings)
        openSystemSettingsItem.target = self
        openSystemSettingsItem.action = #selector(openSystemSettings)
        quitItem.target = self
        quitItem.action = #selector(quit)

        menu.addItem(featureSummaryItem)
        menu.addItem(.separator())
        menu.addItem(extensionStateItem)
        menu.addItem(diskAccessItem)
        menu.addItem(.separator())
        menu.addItem(openSettingsItem)
        menu.addItem(openSystemSettingsItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        refreshStatusMenu()
        item.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshStatusMenu()
    }

    private func refreshStatusMenu() {
        let enabledCount = SupRightConfiguration.enabledFeatureCount
        featureSummaryItem.title = supRightText(
            "已启用 \(enabledCount) / \(SupRightFeature.allCases.count) 项功能",
            "\(enabledCount) / \(SupRightFeature.allCases.count) features enabled"
        )
        if SupRightConfiguration.isRunningFromAppTranslocation {
            extensionStateItem.title = supRightText("请将 SupRight 移至“应用程序”", "Move SupRight to Applications")
        } else {
            extensionStateItem.title = SupRightConfiguration.finderExtensionEnabled
                ? supRightText("Finder 扩展已启用", "Finder extension enabled")
                : supRightText("Finder 扩展待确认", "Finder extension needs attention")
        }
        diskAccessItem.title = SupRightConfiguration.hasFullDiskAccess
            ? supRightText("完全磁盘访问已确认", "Full Disk Access confirmed")
            : supRightText("完全磁盘访问：请在系统设置中确认", "Full Disk Access: confirm in System Settings")
        openSettingsItem.title = supRightText("打开设置…", "Open Settings…")
        openSystemSettingsItem.title = supRightText("前往系统设置", "Open System Settings")
        quitItem.title = supRightText("退出 SupRight", "Quit SupRight")
    }

    @objc private func openSettings() {
        SupRightConfiguration.openAppWindow()
    }

    @objc private func openSystemSettings() {
        SupRightConfiguration.openFullDiskAccessSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private enum SupRightMenuBarImage {
    static func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()

        let primary = NSColor.labelColor
        primary.setStroke()

        let menuCorner = NSBezierPath()
        menuCorner.move(to: NSPoint(x: 5.8, y: 14.8))
        menuCorner.line(to: NSPoint(x: 12.9, y: 14.8))
        menuCorner.curve(
            to: NSPoint(x: 15.3, y: 12.4),
            controlPoint1: NSPoint(x: 14.3, y: 14.8),
            controlPoint2: NSPoint(x: 15.3, y: 13.8)
        )
        menuCorner.line(to: NSPoint(x: 15.3, y: 8.1))
        menuCorner.lineWidth = 2.15
        menuCorner.lineCapStyle = .round
        menuCorner.lineJoinStyle = .round
        menuCorner.stroke()

        let pointer = NSBezierPath()
        pointer.move(to: NSPoint(x: 3.4, y: 10.7))
        pointer.line(to: NSPoint(x: 3.4, y: 3.2))
        pointer.curve(
            to: NSPoint(x: 5.1, y: 1.6),
            controlPoint1: NSPoint(x: 3.4, y: 2.3),
            controlPoint2: NSPoint(x: 4.1, y: 1.6)
        )
        pointer.line(to: NSPoint(x: 8.1, y: 5.2))
        pointer.line(to: NSPoint(x: 11.6, y: 5.2))
        pointer.curve(
            to: NSPoint(x: 12.8, y: 7.3),
            controlPoint1: NSPoint(x: 12.4, y: 5.2),
            controlPoint2: NSPoint(x: 13.0, y: 6.4)
        )
        pointer.line(to: NSPoint(x: 5.7, y: 12.9))
        pointer.curve(
            to: NSPoint(x: 3.4, y: 10.7),
            controlPoint1: NSPoint(x: 4.5, y: 13.9),
            controlPoint2: NSPoint(x: 3.4, y: 12.8)
        )
        pointer.lineWidth = 2.15
        pointer.lineCapStyle = .round
        pointer.lineJoinStyle = .round
        pointer.stroke()

        // Template images inherit the same monochrome treatment as the
        // system's own menu-bar icons: white on dark menu bars, black on light.
        primary.setFill()
        NSBezierPath(ovalIn: NSRect(x: 11.2, y: 10.3, width: 2.6, height: 2.6)).fill()
        NSBezierPath(ovalIn: NSRect(x: 11.2, y: 7.1, width: 2.6, height: 2.6)).fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
