import Cocoa
import Carbon

class PowerClipWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class ClipboardHistory {
    static let shared = ClipboardHistory()
    private let maxItems = 100
    private var lastChange = NSPasteboard.general.changeCount
    private(set) var items: [String] = []
    private let defaultsKey = "SwiftPowerClipHistory"
    private init() {
        if let saved = UserDefaults.standard.array(forKey: defaultsKey) as? [String] {
            items = saved.filter { text in
                !text.contains("git apply --3way") && !text.contains("diff --git")
            }
        }
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            self.checkClipboard()
        }
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        if pb.changeCount == lastChange { return }
        lastChange = pb.changeCount
        guard let text = pb.string(forType: .string), !text.isEmpty,
              !text.contains("git apply --3way") && !text.contains("diff --git") else { return }
        items.removeAll { $0 == text }
        items.insert(text, at: 0)
        if items.count > maxItems { items.removeLast(items.count - maxItems) }
        save()
    }

    private func save() {
        UserDefaults.standard.set(items, forKey: defaultsKey)
    }

    func paste(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

class ClipViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    let searchField = NSTextField()
    let tableView = NSTableView()
    var scrollView: NSScrollView!
    var filtered: [String] = []
    var selected = 0
    var foregroundApp: NSRunningApplication?

    override func loadView() { view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400)) }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadData()
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.7).cgColor

        searchField.frame = NSRect(x: 0, y: view.frame.height - 30, width: view.frame.width, height: 24)
        searchField.backgroundColor = .clear
        searchField.textColor = .white
        searchField.isBordered = false
        searchField.focusRingType = .none
        searchField.delegate = self
        searchField.autoresizingMask = [.width, .minYMargin]
        view.addSubview(searchField)

        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 30))
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false
        scrollView.autoresizingMask = [.width, .height]
        view.addSubview(scrollView)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("text"))
        column.width = scrollView.frame.width
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.intercellSpacing = NSSize(width: 0, height: 1)
        tableView.gridStyleMask = .solidHorizontalGridLineMask
        tableView.gridColor = .white
        tableView.backgroundColor = .clear
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.dataSource = self
        tableView.delegate = self

        scrollView.documentView = tableView
    }

    func show() {
        foregroundApp = NSWorkspace.shared.frontmostApplication
        searchField.stringValue = ""
        reloadData()
        selected = 0
        view.window?.makeKeyAndOrderFront(nil)
        searchField.becomeFirstResponder()
    }

    func hide() {
        if let app = foregroundApp { app.activate(options: []) }
        view.window?.orderOut(nil)
    }

    func numberOfRows(in tableView: NSTableView) -> Int { filtered.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = filtered[row]
        let label = NSTextField(labelWithString: text)
        label.backgroundColor = .clear
        label.textColor = .white
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0

        let query = searchField.stringValue.lowercased()
        if !query.isEmpty, let r = text.lowercased().range(of: query) {
            let ns = NSRange(r, in: text)
            let attr = NSMutableAttributedString(string: text)
            attr.addAttribute(.foregroundColor, value: NSColor(calibratedRed: 1, green: 0.4, blue: 0.4, alpha: 1), range: ns)
            attr.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize), range: ns)
            label.attributedStringValue = attr
        }

        return label
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let text = filtered[row] as NSString
        let width = tableView.bounds.width - 4
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
        let rect = text.boundingRect(with: NSSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     attributes: attrs)
        return ceil(rect.height) + 4
    }

    func controlTextDidChange(_ obj: Notification) { reloadData() }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveDown(_:)) { move(1); return true }
        if commandSelector == #selector(NSResponder.moveUp(_:)) { move(-1); return true }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) { choose(); return true }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) { hide(); return true }
        return false
    }

    private func reloadData() {
        let text = searchField.stringValue.lowercased()
        if text.isEmpty {
            filtered = ClipboardHistory.shared.items
        } else {
            filtered = ClipboardHistory.shared.items.filter { $0.lowercased().contains(text) }
        }
        filtered = Array(filtered.prefix(30))
        tableView.reloadData()
        selected = 0
        if !filtered.isEmpty { tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false) }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // esc
            hide()
        case 125: // down
            move(1)
        case 126: // up
            move(-1)
        case 36: // enter
            choose()
        case 44: // '/'
            if searchField.currentEditor() == nil { searchField.becomeFirstResponder() }
        default:
            super.keyDown(with: event)
        }
    }

    private func move(_ d: Int) {
        guard !filtered.isEmpty else { return }
        selected += d
        if selected < 0 { selected = filtered.count - 1 }
        else if selected >= filtered.count { selected = 0 }
        tableView.selectRowIndexes(IndexSet(integer: selected), byExtendingSelection: false)
        tableView.scrollRowToVisible(selected)
    }

    func choose() {
        guard selected >= 0 && selected < filtered.count else { return }
        let text = filtered[selected]
        hide()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let app = self.foregroundApp { app.activate(options: []) }
            ClipboardHistory.shared.paste(text)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var controller: ClipViewController!
    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ClipboardHistory.shared
        setupWindow()
        setupHotkey()
        NSApp.setActivationPolicy(.accessory)
    }

    private func setupWindow() {
        let rect = NSRect(x: 0, y: 0, width: 600, height: 400)
        window = PowerClipWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        controller = ClipViewController()
        window.contentViewController = controller
    }

    private func setupHotkey() {
        var hotKeyID = EventHotKeyID(signature: OSType(0x5350434C), id: 1)
        let ctrlMask = UInt32(controlKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_V), ctrlMask, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            delegate.handleHotKey(id: hk.id)
            return noErr
        }, 1, &eventSpec, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), nil)
    }

    private func handleHotKey(id: UInt32) {
        guard id == 1 else { return }
        if NSApp.isActive && window.isVisible {
            controller.choose()
        } else {
            show()
        }
    }

    private func show() {
        if let screen = NSScreen.main?.visibleFrame {
            let margin: CGFloat = 200
            let frame = NSRect(x: screen.minX + margin, y: screen.minY + margin,
                               width: screen.width - 2 * margin, height: screen.height - 2 * margin)
            window.setFrame(frame, display: true)
        }
        controller.show()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
