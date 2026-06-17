import MinimalEditorCore
import SwiftUI

struct ControlsPanel: View {
    @ObservedObject var model: EditorModel
    @Binding var showingSavePreset: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                light
                Divider()
                color
                Divider()
                effects
                Divider()
                lut
            }
            .padding(20)
            .disabled(!model.hasImage)
            .opacity(model.hasImage ? 1 : 0.45)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Sections

    private var light: some View {
        ControlSection("Light") {
            SliderRow("Exposure", value: bind(\.exposure), in: -2...2, default: 0)
            SliderRow("Contrast", value: bind(\.contrast), in: 0.5...1.5, default: 1)
            SliderRow("Brightness", value: bind(\.brightness), in: -0.25...0.25, default: 0)
            SliderRow("Highlights", value: bind(\.highlights), in: 0...1, default: 1)
            SliderRow("Shadows", value: bind(\.shadows), in: -1...1, default: 0)
        }
    }

    private var color: some View {
        ControlSection("Color") {
            SliderRow("Temperature", value: bind(\.temperature), in: 3000...9000, default: 6500, format: "%.0f")
            SliderRow("Tint", value: bind(\.tint), in: -100...100, default: 0, format: "%.0f")
            SliderRow("Saturation", value: bind(\.saturation), in: 0...2, default: 1)
            SliderRow("Vibrance", value: bind(\.vibrance), in: -1...1, default: 0)
        }
    }

    private var effects: some View {
        ControlSection("Effects") {
            SliderRow("Motion Blur", value: bind(\.motionBlurRadius), in: 0...40, default: 0, format: "%.0f")
            SliderRow("Angle", value: bind(\.motionBlurAngle), in: 0...360, default: 0, format: "%.0f")
            SliderRow("Overlay", value: bind(\.overlayOpacity), in: 0...0.8, default: 0)
            HStack {
                Text("Overlay Color")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                ColorPicker("", selection: overlayColor, supportsOpacity: false)
                    .labelsHidden()
                    .controlSize(.small)
            }
        }
    }

    private var lut: some View {
        ControlSection("LUT") {
            if let name = model.lutName {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button {
                        model.clearLUT()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.tertiary)
                }
            }
            Button(model.lutName == nil ? "Load .cube…" : "Replace .cube…") {
                if let url = Panels.openCube() { model.loadLUT(url: url) }
            }
            .controlSize(.small)
        }
    }

    private var footer: some View {
        HStack {
            Button("Reset") { model.reset() }
            Spacer()
            Button("Save Preset…") { showingSavePreset = true }
        }
        .controlSize(.small)
        .disabled(!model.hasImage)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // MARK: - Bindings

    private func bind(_ keyPath: WritableKeyPath<Params, Double>) -> Binding<Double> {
        Binding(
            get: { model.params[keyPath: keyPath] },
            set: { model.params[keyPath: keyPath] = $0 }
        )
    }

    private var overlayColor: Binding<Color> {
        Binding(
            get: { Color(hex: model.params.overlayHex) },
            set: { model.params.overlayHex = $0.toHex() }
        )
    }
}

// MARK: - Building blocks

private struct ControlSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            content
        }
    }
}

private struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let defaultValue: Double
    let format: String

    init(
        _ label: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        default defaultValue: Double,
        format: String = "%.2f"
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.defaultValue = defaultValue
        self.format = format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            // Double-click the label to return to neutral.
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { value = defaultValue }

            Slider(value: $value, in: range)
                .controlSize(.small)
        }
    }
}
