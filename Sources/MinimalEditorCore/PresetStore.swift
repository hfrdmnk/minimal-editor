import Foundation

public enum PresetStoreError: Error {
    case nameTaken
}

/// Reads and writes presets (and their copied-in LUTs) under
/// `Application Support/MinimalEditor/presets/`.
public struct PresetStore {
    public let directory: URL

    public init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directory = base.appendingPathComponent("MinimalEditor/presets", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    public func names() -> [String] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil)) ?? []
        return contents
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    public func load(_ name: String) throws -> Preset {
        let url = directory.appendingPathComponent(name).appendingPathExtension("json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Preset.self, from: data)
    }

    public func save(_ preset: Preset) throws {
        let url = directory.appendingPathComponent(preset.name).appendingPathExtension("json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(preset).write(to: url)
    }

    public func delete(_ name: String) {
        let url = directory.appendingPathComponent(name).appendingPathExtension("json")
        try? FileManager.default.removeItem(at: url)
    }

    /// Rename a preset, keeping its stored `name` field in sync with the file.
    /// Throws `PresetStoreError.nameTaken` rather than clobbering an existing preset.
    public func rename(_ name: String, to newName: String) throws {
        let dest = directory.appendingPathComponent(newName).appendingPathExtension("json")
        if FileManager.default.fileExists(atPath: dest.path) {
            throw PresetStoreError.nameTaken
        }
        var preset = try load(name)
        preset.name = newName
        try save(preset)
        delete(name)
    }

    /// Absolute URL of a LUT that was copied into the store.
    public func lutURL(forFileName fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    /// Copy a LUT into the store so presets are self-contained. Returns its filename.
    @discardableResult
    public func importLUT(from url: URL) throws -> String {
        let fileName = url.lastPathComponent
        let dest = directory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: dest.path) {
            try? FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: url, to: dest)
        return fileName
    }
}
