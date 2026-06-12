import SwiftUI
import AppKit

// MARK: - ThemedNumberField (Int)

struct ThemedNumberField: NSViewRepresentable {
    @Binding var value: Int
    let width: CGFloat

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = false
        textField.drawsBackground = true
        textField.backgroundColor = NSColor(ThemeColors.backgroundInput)
        textField.textColor = NSColor(ThemeColors.textPrimary)
        textField.focusRingType = .none
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 6
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        textField.layer?.masksToBounds = true
        textField.stringValue = "\(value)"
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if !context.coordinator.isEditing {
            nsView.stringValue = "\(value)"
        }
        nsView.backgroundColor = NSColor(ThemeColors.backgroundInput)
        nsView.textColor = NSColor(ThemeColors.textPrimary)
        if !context.coordinator.isEditing {
            nsView.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ThemedNumberField
        var isEditing = false
        init(_ parent: ThemedNumberField) { self.parent = parent }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isEditing = true
            applyBorder(obj, valid: true, focused: true)
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            let valid = Int(textField.stringValue) != nil || textField.stringValue.isEmpty
            applyBorder(obj, valid: valid, focused: true)
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            if let textField = obj.object as? NSTextField {
                textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
                textField.layer?.borderWidth = 1
                if let intValue = Int(textField.stringValue) {
                    parent.value = intValue
                } else {
                    textField.stringValue = "\(parent.value)"
                }
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                if let intValue = Int(control.stringValue) { parent.value = intValue }
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }

        private func applyBorder(_ obj: Notification, valid: Bool, focused: Bool) {
            guard let textField = obj.object as? NSTextField else { return }
            textField.layer?.borderColor = valid
                ? NSColor(ThemeColors.accent).cgColor
                : NSColor.systemRed.cgColor
            textField.layer?.borderWidth = 1.5
        }
    }
}

// MARK: - ThemedDoubleField (Double)

struct ThemedDoubleField: NSViewRepresentable {
    @Binding var value: Double
    let width: CGFloat

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.drawsBackground = true
        textField.focusRingType = .none
        textField.backgroundColor = NSColor(ThemeColors.backgroundInput)
        textField.textColor = NSColor(ThemeColors.textPrimary)
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 6
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        textField.stringValue = formatValue(value)
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if !context.coordinator.isEditing {
            nsView.stringValue = formatValue(value)
        }
        nsView.backgroundColor = NSColor(ThemeColors.backgroundInput)
        nsView.textColor = NSColor(ThemeColors.textPrimary)
        if !context.coordinator.isEditing {
            nsView.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func formatValue(_ v: Double) -> String {
        let s = String(format: "%.2f", v)
        return s.replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ThemedDoubleField
        var isEditing = false
        init(_ parent: ThemedDoubleField) { self.parent = parent }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isEditing = true
            applyBorder(obj, valid: true)
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            let valid = Double(textField.stringValue) != nil || textField.stringValue.isEmpty
            applyBorder(obj, valid: valid)
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            if let textField = obj.object as? NSTextField {
                textField.layer?.borderColor = NSColor(ThemeColors.borderNormal).cgColor
                textField.layer?.borderWidth = 1
                if let v = Double(textField.stringValue) {
                    parent.value = v
                } else {
                    textField.stringValue = parent.formatValue(parent.value)
                }
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                if let v = Double(control.stringValue) { parent.value = v }
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }

        private func applyBorder(_ obj: Notification, valid: Bool) {
            guard let textField = obj.object as? NSTextField else { return }
            textField.layer?.borderColor = valid
                ? NSColor(ThemeColors.accent).cgColor
                : NSColor.systemRed.cgColor
            textField.layer?.borderWidth = 1.5
        }
    }
}
