import SwiftUI
import AppKit

struct ThemedNSSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var increment: Double = 1.0
    @ObservedObject private var themeManager = ThemeManager.shared

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider()
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.doubleValue = value
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.valueChanged(_:))
        slider.controlSize = .small
        slider.sliderType = .linear
        slider.isContinuous = true
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false
        slider.setAccessibilityLabel("DPI")
        slider.setAccessibilityValueDescription("\(Int(value)) DPI")
        updateSliderAppearance(slider)
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {
        if abs(nsView.doubleValue - value) > 0.5 {
            nsView.doubleValue = value
        }
        updateSliderAppearance(nsView)
    }

    private func updateSliderAppearance(_ slider: NSSlider) {
        slider.appearance = NSAppearance(named: themeManager.isDarkMode ? .darkAqua : .aqua)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: ThemedNSSlider
        init(_ parent: ThemedNSSlider) { self.parent = parent }

        @objc func valueChanged(_ sender: NSSlider) {
            let stepped = round(sender.doubleValue / parent.increment) * parent.increment
            let clamped = max(parent.range.lowerBound, min(parent.range.upperBound, stepped))
            parent.value = clamped
            sender.setAccessibilityValueDescription("\(Int(clamped)) DPI")
        }
    }
}
