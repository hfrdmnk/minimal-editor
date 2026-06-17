import AppKit
import UniformTypeIdentifiers

/// Thin wrappers around the AppKit open/save panels. Simpler than juggling
/// several SwiftUI `.fileImporter` modifiers for a single-window app.
enum Panels {
    static func openImage() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Open"
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func openCube() -> URL? {
        let panel = NSOpenPanel()
        if let cube = UTType(filenameExtension: "cube") {
            panel.allowedContentTypes = [cube]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Load"
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func save(suggestedName: String, type: UTType) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = suggestedName
        panel.prompt = "Export"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
