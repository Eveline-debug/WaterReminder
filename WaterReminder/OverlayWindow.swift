import AppKit

final class OverlayWindow {
    private var window: NSWindow?
    private let label = NSTextField(labelWithString: "")
    private let showDuration: TimeInterval = 4.0

    init() {
        let screen = NSScreen.main
        let size = NSSize(width: 300, height: 48)
        let originX = (screen?.frame.maxX ?? 0) - size.width - 20
        let originY = (screen?.frame.maxY ?? 0) - size.height - 40
        let rect = NSRect(x: originX, y: originY, width: size.width, height: size.height)
        let w = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        w.isOpaque = false
        w.backgroundColor = NSColor.clear
        w.level = .statusBar
        w.ignoresMouseEvents = true
        w.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        w.hasShadow = false
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.isReleasedWhenClosed = false
        label.frame = w.contentView!.bounds
        label.alignment = .center
        label.textColor = NSColor.white.withAlphaComponent(0.9)
        label.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        label.backgroundColor = NSColor.black.withAlphaComponent(0.25)
        label.wantsLayer = true
        label.layer?.cornerRadius = 12
        w.contentView?.addSubview(label)
        window = w
    }

    func show(text: String, duration: TimeInterval) {
        guard let w = window else { return }
        label.stringValue = text
        w.alphaValue = 0
        w.orderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            w.animator().alphaValue = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                w.animator().alphaValue = 0.0
            } completionHandler: {
                w.orderOut(nil)
            }
        }
    }
}
