import AppKit

func askForCustomDuration() -> Int? {
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

    let header = NSTextField(labelWithString: "Custom Duration")
    header.font = .boldSystemFont(ofSize: 13)

    let subtitle = NSTextField(labelWithString: "Enter how long to keep your Mac awake.")
    subtitle.font = .systemFont(ofSize: 13)
    subtitle.textColor = .secondaryLabelColor
    subtitle.lineBreakMode = .byWordWrapping
    subtitle.maximumNumberOfLines = 0


    let hoursField = makeNumberField(placeholder: "0")
    let minutesField = makeNumberField(placeholder: "0")
    hoursField.nextKeyView = minutesField

    let hoursColumn = makeColumn(field: hoursField, label: "hours")
    let minutesColumn = makeColumn(field: minutesField, label: "mins")

    let fieldsRow = NSStackView(views: [hoursColumn, minutesColumn])
    fieldsRow.orientation = .horizontal
    fieldsRow.spacing = 12
    fieldsRow.alignment = .top

    let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    cancelButton.bezelStyle = .rounded
    cancelButton.keyEquivalent = "\u{1b}"

    let startButton = NSButton(title: "Start", target: nil, action: nil)
    startButton.bezelStyle = .rounded
    startButton.keyEquivalent = "\r"

    minutesField.nextKeyView = startButton

    cancelButton.target = panel
    cancelButton.action = #selector(NSPanel.performClose(_:))

    let buttonRow = NSStackView(views: [cancelButton, startButton])
    buttonRow.orientation = .horizontal
    buttonRow.spacing = 8
    buttonRow.distribution = .fillEqually

    let stack = NSStackView(views: [header, subtitle, fieldsRow, buttonRow])
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

    NSLayoutConstraint.activate([
        stack.topAnchor.constraint(equalTo: contentView.topAnchor),
        stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        stack.widthAnchor.constraint(equalToConstant: 320),
        buttonRow.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -64),
    ])

    panel.setContentSize(stack.fittingSize)
    panel.center()

    panel.initialFirstResponder = hoursField

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

    let startTarget = ButtonTarget {
        NSApp.stopModal(withCode: NSApplication.ModalResponse.OK)
        panel.close()
    }
    startButton.target = startTarget
    startButton.action = #selector(ButtonTarget.invoke)

    objc_setAssociatedObject(panel, "cancelTarget", cancelTarget, .OBJC_ASSOCIATION_RETAIN)
    objc_setAssociatedObject(panel, "startTarget", startTarget, .OBJC_ASSOCIATION_RETAIN)

    let response = NSApp.runModal(for: panel)

    guard response == .OK else { return nil }

    let hours = Int(hoursField.stringValue) ?? 0
    let minutes = Int(minutesField.stringValue) ?? 0
    let total = (hours * 3600) + (minutes * 60)

    guard total > 0 else { return nil }
    return total
}

private func makeColumn(field: NSTextField, label: String) -> NSStackView {
    let lbl = NSTextField(labelWithString: label)
    lbl.textColor = .secondaryLabelColor
    lbl.font = .systemFont(ofSize: 11)
    lbl.alignment = .left

    let column = NSStackView(views: [field, lbl])
    column.orientation = .vertical
    column.spacing = 4
    column.alignment = .leading
    return column
}

private func makeNumberField(placeholder: String) -> NSTextField {
    let field = NSTextField()
    field.placeholderString = placeholder
    field.alignment = .left
    field.formatter = onlyIntegersFormatter()
    field.bezelStyle = .roundedBezel
    field.focusRingType = .exterior
    field.translatesAutoresizingMaskIntoConstraints = false
    field.widthAnchor.constraint(equalToConstant: 64).isActive = true
    return field
}

private func onlyIntegersFormatter() -> NumberFormatter {
    let f = NumberFormatter()
    f.numberStyle = .none
    f.minimum = 0
    f.maximum = 999
    return f
}
