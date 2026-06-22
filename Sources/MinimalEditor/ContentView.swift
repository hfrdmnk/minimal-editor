import MinimalEditorCore
import SwiftUI

struct ContentView: View {
    @StateObject private var model = EditorModel()
    @State private var showingSavePreset = false
    @State private var newPresetName = ""
    @State private var showingExport = false
    @State private var pendingExport: ExportSettings?

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
        .sheet(isPresented: $showingExport, onDismiss: {
            if let settings = pendingExport {
                pendingExport = nil
                runExport(settings)
            }
        }) {
            ExportSheet(imageWidth: model.imagePixelWidth) { settings in
                pendingExport = settings
            }
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

            Button("Export…") { showingExport = true }
                .disabled(!model.hasImage)
        }
    }

    private func runExport(_ settings: ExportSettings) {
        let base = (model.imageName as NSString?)?.deletingPathExtension ?? "Untitled"
        let suggested = "\(base).\(settings.format.fileExtension)"
        if let url = Panels.save(suggestedName: suggested, type: settings.format.utType) {
            model.export(to: url, settings: settings)
        }
    }
}
