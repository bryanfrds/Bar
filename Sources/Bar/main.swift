import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var cloak: MenuBarCloak?
    private var autoHideTimer: Timer?
    private var hoverTimer: Timer?
    private var activity: NSObjectProtocol?
    private var loginMenuItem: NSMenuItem?
    private var autoHideMenuItem: NSMenuItem?
    private var hoverMenuItem: NSMenuItem?

    private var autoHideEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cafe.bar.autoHide") }
        set { UserDefaults.standard.set(newValue, forKey: "cafe.bar.autoHide") }
    }

    private var showOnHover: Bool {
        get { UserDefaults.standard.bool(forKey: "cafe.bar.showOnHover") }
        set { UserDefaults.standard.set(newValue, forKey: "cafe.bar.showOnHover") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let cloak = MenuBarCloak()
        self.cloak = cloak

        if let button = cloak.toggleItem.button {
            button.target = self
            button.action = #selector(toggleClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        if let button = cloak.separatorItem.button {
            button.target = self
            button.action = #selector(toggleClicked)
            button.sendAction(on: [.leftMouseUp])
        }

        // Restore the last state.
        cloak.setCollapsed(UserDefaults.standard.bool(forKey: "cafe.bar.collapsed"))
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep],
            reason: "Menu bar hover tracking")
        updateHoverMonitor()
    }

    // MARK: clicks

    @objc private func toggleClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
            return
        }
        cloak?.toggle()
        scheduleAutoHide()
    }

    private func showMenu() {
        guard let cloak else { return }
        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(withTitle: cloak.isCollapsed ? "Show Menu Bar Items" : "Hide Menu Bar Items",
                     action: #selector(toggleFromMenu), keyEquivalent: "").target = self
        menu.addItem(.separator())

        let auto = menu.addItem(withTitle: "Auto-hide After 10s",
                                action: #selector(toggleAutoHide), keyEquivalent: "")
        auto.target = self
        auto.state = autoHideEnabled ? .on : .off
        autoHideMenuItem = auto

        let hover = menu.addItem(withTitle: "Show on Hover",
                                 action: #selector(toggleShowOnHover), keyEquivalent: "")
        hover.target = self
        hover.state = showOnHover ? .on : .off
        hoverMenuItem = hover

        let login = menu.addItem(withTitle: "Open at Login",
                                 action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = LoginItem.isEnabled ? .on : .off
        loginMenuItem = login

        menu.addItem(.separator())
        menu.addItem(withTitle: "Cmd-drag the ☰ icon to choose what hides",
                     action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Bar",
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        cloak.toggleItem.menu = menu
        cloak.toggleItem.button?.performClick(nil)
        cloak.toggleItem.menu = nil
    }

    @objc private func toggleFromMenu() { cloak?.toggle(); scheduleAutoHide() }

    @objc private func toggleAutoHide() {
        autoHideEnabled.toggle()
        scheduleAutoHide()
    }

    @objc private func toggleShowOnHover() {
        showOnHover.toggle()
        updateHoverMonitor()
    }

    @objc private func toggleLoginItem() {
        let target = !LoginItem.isEnabled
        if let reason = LoginItem.setEnabled(target) {
            let alert = NSAlert()
            alert.messageText = "Couldn't \(target ? "enable" : "disable") Open at Login"
            alert.informativeText = reason
            alert.alertStyle = .warning
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    nonisolated func menuDidClose(_ menu: NSMenu) {
        MainActor.assumeIsolated { cloak?.toggleItem.menu = nil }
    }

    // MARK: auto-hide + hover

    private func scheduleAutoHide() {
        autoHideTimer?.invalidate()
        guard autoHideEnabled, cloak?.isCollapsed == false else { return }
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.cloak?.setCollapsed(true) }
        }
    }

    /// Expand when the pointer reaches the menu bar strip, collapse when it leaves.
    ///
    /// Polls rather than using a global mouse-moved monitor: those events stop
    /// arriving while the menu bar runs its own tracking loop, which is exactly
    /// when we need them.
    private func updateHoverMonitor() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        guard showOnHover else { return }
        let timer = Timer(timeInterval: 0.12, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkPointer() }
        }
        // .common keeps it ticking while menus and drags are open.
        RunLoop.main.add(timer, forMode: .common)
        hoverTimer = timer
    }

    private func checkPointer() {
        guard let cloak else { return }
        let location = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(location) })
        else { return }
        let menuBarHeight = max(screen.frame.maxY - screen.visibleFrame.maxY, 24)
        let inMenuBar = location.y >= screen.frame.maxY - menuBarHeight

        if inMenuBar, cloak.isCollapsed {
            cloak.setCollapsed(false)
        } else if !inMenuBar, !cloak.isCollapsed, autoHideEnabled {
            cloak.setCollapsed(true)
        }
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    objc_setAssociatedObject(app, "cafe.bar.delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
    app.run()
}
