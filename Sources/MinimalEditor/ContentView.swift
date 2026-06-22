import MinimalEditorCore
import SwiftUI

struct ContentView: View {
    @StateObject private var model = EditorModel()
    @State private var showingSavePreset = false
    @State private var newPresetName = ""
    @State private var showingExport = false
    @State private var pendingExport: ExportSettings?
    @State private var showingPresets = false
    @State private var renameTarget: String?
    @State private var renameText = ""
    @State private var deleteTarget: String?

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
        .alert("Rename Preset", isPresented: renamePresented) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renameTarget = nil }
            Button("Rename") {
                if let old = renameTarget { model.renamePreset(old, to: renameText) }
                renameTarget = nil
            }
        }
        .alert("Delete Preset", isPresented: deletePresented, presenting: deleteTarget) { name in
            Button("Cancel", role: .cancel) { deleteTarget = nil }
            Button("Delete", role: .destructive) {
                model.deletePreset(name)
                deleteTarget = nil
            }
        } message: { name in
            Text("\"\(name)\" will be deleted. This can't be undone.")
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
            Button("Presets") { showingPresets.toggle() }
                .popover(isPresented: $showingPresets, arrowEdge: .bottom) {
                    PresetListPopover(
                        model: model,
                        onApply: { name in model.applyPreset(name); showingPresets = false },
                        onUpdate: { name in model.updatePreset(name); showingPresets = false },
                        onRename: { name in showingPresets = false; renameText = name; renameTarget = name },
                        onDelete: { name in showingPresets = false; deleteTarget = name },
                        onSave: { showingPresets = false; showingSavePreset = true })
                }

            Button("Export…") { showingExport = true }
                .disabled(!model.hasImage)
        }
    }

    private var renamePresented: Binding<Bool> {
        Binding(get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } })
    }

    private var deletePresented: Binding<Bool> {
        Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })
    }

    private func runExport(_ settings: ExportSettings) {
        let base = (model.imageName as NSString?)?.deletingPathExtension ?? "Untitled"
        let suggested = "\(base).\(settings.format.fileExtension)"
        if let url = Panels.save(suggestedName: suggested, type: settings.format.utType) {
            model.export(to: url, settings: settings)
        }
    }
}
