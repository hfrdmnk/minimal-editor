import MinimalEditorCore
import SwiftUI

/// Picks the format, quality, and an optional max width before the save panel
/// opens. Quality is shown as a percentage and hidden for lossless PNG.
struct ExportSheet: View {
    let imageWidth: Int?
    let onExport: (ExportSettings) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var format: ImageFormat = .jpeg
    @State private var quality: Double = 80
    @State private var maxWidthText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Export")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                Picker("", selection: $format) {
                    ForEach(ImageFormat.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)

                if format.isLossy {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Quality")
                            Spacer()
                            Text("\(Int(quality))")
                                .monospacedDigit()
                                .foregroundStyle(.tertiary)
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        Slider(value: $quality, in: 1...100, step: 1)
                            .controlSize(.small)
                    }
                }

                HStack {
                    Text("Max Width")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField(imageWidth.map(String.init) ?? "original", text: $maxWidthText)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 72)
                        .controlSize(.small)
                    Text("px")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Export…") {
                    onExport(settings)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private var settings: ExportSettings {
        let parsed = Int(maxWidthText.trimmingCharacters(in: .whitespaces))
        return ExportSettings(
            format: format,
            quality: quality / 100,
            maxWidth: (parsed ?? 0) > 0 ? parsed : nil
        )
    }
}
