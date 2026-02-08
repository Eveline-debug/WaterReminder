import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var reminderTimer: Timer?
    private var overlay: OverlayWindow?
    private var pausedUntil: Date?
    private let defaults = UserDefaults.standard
    private let enabledKey = "reminderEnabled"
    private let messages = [
        "一小时过去了，喝口水吧。",
        "现在喝点水，会舒服些。",
        "别忘了补点水。"
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        if defaults.object(forKey: enabledKey) == nil {
            defaults.set(true, forKey: enabledKey)
        }
        configureStatusItem()
        registerSleepWakeNotifications()
        if isEnabled {
            scheduleInitialThenHourly(initialDelay: 10)
        }
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "drop", accessibilityDescription: nil)
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        let toggleTitle = isEnabled ? "关闭提醒" : "开启提醒"
        menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleEnabled), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "暂停提醒（2小时）", action: #selector(pauseTwoHours), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "立即提醒一次", action: #selector(triggerOnce), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: ""))
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        defaults.set(!isEnabled, forKey: enabledKey)
        configureStatusItem()
        if isEnabled {
            scheduleNextReminder(interval: 3600)
        } else {
            reminderTimer?.invalidate()
            reminderTimer = nil
        }
    }

    @objc private func pauseTwoHours() {
        pausedUntil = Date().addingTimeInterval(7200)
    }

    @objc private func triggerOnce() {
        triggerReminderIfNeeded()
    }

    private var isEnabled: Bool {
        defaults.bool(forKey: enabledKey)
    }

    private func registerSleepWakeNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleSleep), name: NSWorkspace.willSleepNotification, object: nil)
    }

    @objc private func handleSleep(_ n: Notification) {
        reminderTimer?.invalidate()
        reminderTimer = nil
    }

    @objc private func handleWake(_ n: Notification) {
        if isEnabled {
            scheduleInitialThenHourly(initialDelay: 10)
        }
    }

    private func scheduleNextReminder(interval: TimeInterval) {
        reminderTimer?.invalidate()
        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.triggerReminderIfNeeded()
        }
        RunLoop.main.add(reminderTimer!, forMode: .common)
    }

    private func scheduleInitialThenHourly(initialDelay: TimeInterval) {
        reminderTimer?.invalidate()
        let initial = Timer.scheduledTimer(withTimeInterval: initialDelay, repeats: false) { [weak self] _ in
            self?.triggerReminderIfNeeded()
            self?.scheduleNextReminder(interval: 3600)
        }
        RunLoop.main.add(initial, forMode: .common)
        reminderTimer = initial
    }
    private func triggerReminderIfNeeded() {
        guard isEnabled else { return }
        if let until = pausedUntil, Date() < until { return }
        pausedUntil = nil
        showOverlay()
        transientStatusBlink()
    }

    private func showOverlay() {
        let text = messages.randomElement() ?? messages[0]
        if overlay == nil {
            overlay = OverlayWindow()
        }
        overlay?.show(text: text, duration: 4.0)
    }

    private func transientStatusBlink() {
        guard let button = statusItem.button else { return }
        let originalImage = button.image
        button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: nil)
        button.image?.isTemplate = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            button.image = originalImage
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
