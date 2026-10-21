import AppKit

/// Hides menu bar items using only public API.
///
/// Status items lay out right-to-left. A status item with an enormous length
/// therefore consumes the whole visible bar to its left, shoving every item
/// left of it past the screen edge. Collapsing is just "make the separator
/// very wide"; expanding is "make it narrow again".
///
/// This is the same approach Dozer and Hidden Bar use. It needs no Screen
/// Recording and no Accessibility permission — unlike Bartender, which
/// screen-captures the bar to redraw icons elsewhere.
@MainActor
final class MenuBarCloak {
    /// Wide enough to push anything off any display.
    private static let collapsedWidth: CGFloat = 10_000
    private static let expandedWidth: CGFloat = 24

    let toggleItem: NSStatusItem
    let separatorItem: NSStatusItem

    private(set) var isCollapsed = false

    /// macOS stores each item's placement under this defaults key (distance
    /// from the right edge). New items default to the far left of the status
    /// area, where nothing is to their left — so collapsing would hide nothing.
    /// Seed a useful position on first run.
    private static func seedPositionsIfNeeded() {
        let defaults = UserDefaults.standard
        let separatorKey = "NSStatusItem Preferred Position cafe.bar.separator"
        let toggleKey = "NSStatusItem Preferred Position cafe.bar.toggle"
        guard defaults.object(forKey: separatorKey) == nil else { return }
        defaults.set(0, forKey: toggleKey)        // chevron pinned rightmost
        defaults.set(36, forKey: separatorKey)    // separator just left of it
    }

    init() {
        Self.seedPositionsIfNeeded()

        // ORDER MATTERS: macOS inserts each new status item to the LEFT of the
        // existing ones. The chevron must end up to the RIGHT of the separator,
        // otherwise collapsing hides the chevron too and the app vanishes.
        // So create the toggle first, the separator second.
        toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        toggleItem.autosaveName = "cafe.bar.toggle"

        // The separator is the thing the user Cmd-drags: everything to its
        // left is what gets hidden.
        separatorItem = NSStatusBar.system.statusItem(withLength: Self.expandedWidth)
        separatorItem.autosaveName = "cafe.bar.separator"
        separatorItem.button?.image = Self.separatorImage()
        separatorItem.button?.image?.isTemplate = true

        updateChevron()
    }

    func setCollapsed(_ collapsed: Bool, animated: Bool = true) {
        guard collapsed != isCollapsed else { return }
        isCollapsed = collapsed
        separatorItem.length = collapsed ? Self.collapsedWidth : Self.expandedWidth
        // The separator's own glyph would land off-screen when it is huge, so
        // drop it while collapsed rather than leave a stray icon.
        separatorItem.button?.image = collapsed ? nil : Self.separatorImage()
        updateChevron()
        UserDefaults.standard.set(collapsed, forKey: "cafe.bar.collapsed")
    }

    func toggle() { setCollapsed(!isCollapsed) }

    private static func separatorImage() -> NSImage? {
        let image = NSImage(systemSymbolName: "line.3.horizontal.decrease",
                            accessibilityDescription: "Bar separator")
        image?.isTemplate = true
        return image
    }

    private func updateChevron() {
        let symbol = isCollapsed ? "chevron.left" : "chevron.right"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Toggle menu bar items")
        image?.isTemplate = true
        toggleItem.button?.image = image
    }
}
