import MinimalEditorCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = EditorModel()
    @State private var showingSavePreset = false
    @State private var newPresetName = ""

    var body: some View {
        HSplitView {
            PreviewView(model: model)
                .frame(minWidth: 460, minHeight: 420)
                .layoutPriority(1)
            ControlsPanel(model: model, showingSavePreset: $showingSavePreset)
                .frame(width: 296)
        }
        .frame(minWidth: 860, minHeight: 600)
        .toolbar { toolbarContent }
        .navigationTitle(model.imageName ?? "Minimal Editor")
        .alert("Save Preset", isPresented: $showingSavePreset) {
            TextField("Name", text: $newPresetName)
            Button("Cancel", role: .cancel) { newPresetName = "" }
            Button("Save") {
                model.savePreset(named: newPresetName)
                newPresetName = ""
            }
        } message: {
            Text("Saves the current look, including the LUT.")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button("Open") {
                if let url = Panels.openImage() { model.open(url: url) }
            }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Menu("Presets") {
                if model.presetNames.isEmpty {
                    Text("No presets yet")
                } else {
                    ForEach(model.presetNames, id: \.self) { name in
                        Button(name) { model.applyPreset(name) }
                    }
                }
                Divider()
                Button("Save Preset…") { showingSavePreset = true }
                    .disabled(!model.hasImage)
            }

            Menu("Export") {
                Button("PNG…") { export(.png) }
                Button("JPEG…") { export(.jpeg(quality: 0.92)) }
            }
            .disabled(!model.hasImage)
        }
    }

    private func export(_ format: ExportFormat) {
        let base = (model.imageName as NSString?)?.deletingPathExtension ?? "Untitled"
        let type: UTType = {
            if case .png = format { return .png }
            return .jpeg
        }()
        let suggested = "\(base).\(format.fileExtension)"
        if let url = Panels.save(suggestedName: suggested, type: type) {
            model.export(to: url, format: format)
        }
    }
}
