import AppKit

func askForScheduleTimes(
    currentStart: (Int, Int),
    currentEnd: (Int, Int)
) -> (start: (Int, Int), end: (Int, Int))? {
    let panel = NSPanel(
        contentRect: .zero,
        styleMask: [.titled, .fullSizeContentView],
        backing: .buffered,
        defer: true
    )
    panel.titlebarAppearsTransparent = true
    panel.titleVisibility = .hidden
    panel.isMovableByWindowBackground = true
    panel.becomesKeyOnlyIfNeeded = false
    panel.level = .floating

    let header = NSTextField(labelWithString: "Schedule")
    header.font = .boldSystemFont(ofSize: 13)

    let subtitle = NSTextField(labelWithString: "Set when to automatically keep your Mac awake.")
    subtitle.font = .systemFont(ofSize: 13)
    subtitle.textColor = .secondaryLabelColor
    subtitle.lineBreakMode = .byWordWrapping
    subtitle.maximumNumberOfLines = 0
    subtitle.translatesAutoresizingMaskIntoConstraints = false

    let calendar = Calendar.current
    let now = Date()

    func makeDate(hour: Int, minute: Int) -> Date {
        var c = calendar.dateComponents([.year, .month, .day], from: now)
        c.hour = hour
        c.minute = minute
        return calendar.date(from: c) ?? now
    }

    let startPicker = NSDatePicker()
    startPicker.datePickerStyle = .textFieldAndStepper
    startPicker.datePickerElements = .hourMinute
    startPicker.dateValue = makeDate(hour: currentStart.0, minute: currentStart.1)

    let endPicker = NSDatePicker()
    endPicker.datePickerStyle = .textFieldAndStepper
    endPicker.datePickerElements = .hourMinute
    endPicker.dateValue = makeDate(hour: currentEnd.0, minute: currentEnd.1)

    let startColumn = makeScheduleColumn(picker: startPicker, label: "Start")
    let endColumn = makeScheduleColumn(picker: endPicker, label: "End")

    let pickersRow = NSStackView(views: [startColumn, endColumn])
    pickersRow.orientation = .horizontal
    pickersRow.spacing = 12
    pickersRow.alignment = .top

    let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    cancelButton.bezelStyle = .rounded
    cancelButton.keyEquivalent = "\u{1b}"

    let saveButton = NSButton(title: "Save", target: nil, action: nil)
    saveButton.bezelStyle = .rounded
    saveButton.keyEquivalent = "\r"

    let buttonRow = NSStackView(views: [cancelButton, saveButton])
    buttonRow.orientation = .horizontal
    buttonRow.spacing = 8
    buttonRow.distribution = .fillEqually

    let stack = NSStackView(views: [header, subtitle, pickersRow, buttonRow])
    stack.orientation = .vertical
    stack.spacing = 16
    stack.alignment = .leading
    stack.setCustomSpacing(4, after: header)
    stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    stack.translatesAutoresizingMaskIntoConstraints = false

    buttonRow.translatesAutoresizingMaskIntoConstraints = false

    let contentView = NSView()
    contentView.addSubview(stack)
    panel.contentView = contentView

    let inset = stack.edgeInsets.left + stack.edgeInsets.right
    NSLayoutConstraint.activate([
        stack.topAnchor.constraint(equalTo: contentView.topAnchor),
        stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        stack.widthAnchor.constraint(equalToConstant: 280),
        subtitle.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -inset),
        buttonRow.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -inset),
    ])

    panel.setContentSize(stack.fittingSize)
    panel.center()

    class ButtonTarget: NSObject {
        let handler: () -> Void
        init(_ handler: @escaping () -> Void) { self.handler = handler }
        @objc func invoke() { handler() }
    }

    let cancelTarget = ButtonTarget {
        NSApp.stopModal(withCode: NSApplication.ModalResponse.cancel)
        panel.close()
    }
    cancelButton.target = cancelTarget
    cancelButton.action = #selector(ButtonTarget.invoke)

    let saveTarget = ButtonTarget {
        NSApp.stopModal(withCode: NSApplication.ModalResponse.OK)
        panel.close()
    }
    saveButton.target = saveTarget
    saveButton.action = #selector(ButtonTarget.invoke)

    objc_setAssociatedObject(panel, "cancelTarget", cancelTarget, .OBJC_ASSOCIATION_RETAIN)
    objc_setAssociatedObject(panel, "saveTarget", saveTarget, .OBJC_ASSOCIATION_RETAIN)

    let response = NSApp.runModal(for: panel)
    guard response == .OK else { return nil }

    let s = calendar.dateComponents([.hour, .minute], from: startPicker.dateValue)
    let e = calendar.dateComponents([.hour, .minute], from: endPicker.dateValue)

    return (
        start: (s.hour ?? 9, s.minute ?? 0),
        end: (e.hour ?? 17, e.minute ?? 0)
    )
}

private func makeScheduleColumn(picker: NSDatePicker, label: String) -> NSStackView {
    let lbl = NSTextField(labelWithString: label)
    lbl.font = .systemFont(ofSize: 11)
    lbl.textColor = .secondaryLabelColor
    let col = NSStackView(views: [picker, lbl])
    col.orientation = .vertical
    col.spacing = 4
    col.alignment = .leading
    return col
}
