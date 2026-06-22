import MinimalEditorCore
import SwiftUI

/// The preset list shown in the toolbar popover. Left-click a row to apply it,
/// right-click for management (update / rename / delete).
struct PresetListPopover: View {
    @ObservedObject var model: EditorModel
    let onApply: (String) -> Void
    let onUpdate: (String) -> Void
    let onRename: (String) -> Void
    let onDelete: (String) -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.presetNames.isEmpty {
                Text("No presets yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(model.presetNames, id: \.self) { name in
                            PresetRow(
                                name: name,
                                canUpdate: model.hasImage,
                                onApply: { onApply(name) },
                                onUpdate: { onUpdate(name) },
                                onRename: { onRename(name) },
                                onDelete: { onDelete(name) })
                        }
                    }
                }
                .frame(maxHeight: 280)
            }

            Divider()

            Button(action: onSave) {
                Label("Save Preset…", systemImage: "plus")
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .disabled(!model.hasImage)
        }
        .padding(.vertical, 4)
        .frame(width: 240)
    }
}

private struct PresetRow: View {
    let name: String
    let canUpdate: Bool
    let onApply: () -> Void
    let onUpdate: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onApply) {
            Text(name)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(hovering ? Color.primary.opacity(0.08) : Color.clear)
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Update with Current Settings", action: onUpdate)
                .disabled(!canUpdate)
            Button("Rename…", action: onRename)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
