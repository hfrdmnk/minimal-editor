import SwiftUI
import UniformTypeIdentifiers

struct PreviewView: View {
    @ObservedObject var model: EditorModel
    @State private var targeted = false

    // A neutral gray, so the eye judges the photo and not the chrome.
    private let canvas = Color(red: 0.91, green: 0.91, blue: 0.91)

    var body: some View {
        ZStack {
            canvas
            if let cg = model.preview {
                Image(decorative: cg, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(28)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            } else {
                emptyState
            }
        }
        .overlay(alignment: .bottomLeading) { statusBar }
        .overlay {
            if targeted {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .padding(8)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $targeted, perform: handleDrop)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo")
                .font(.system(size: 34, weight: .ultraLight))
                .foregroundStyle(.secondary)
            Text("Drop a photo here")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Button("Open…") {
                if let url = Panels.openImage() { model.open(url: url) }
            }
            .controlSize(.small)
        }
    }

    @ViewBuilder
    private var statusBar: some View {
        if let status = model.status {
            Text(status)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .padding(16)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url, url.isFileURL else { return }
            DispatchQueue.main.async { model.open(url: url) }
        }
        return true
    }
}
