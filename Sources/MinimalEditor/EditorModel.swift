import AppKit
import Combine
import CoreImage
import MinimalEditorCore

/// Holds the open photo, the live parameters, the parsed LUT, and a debounced
/// preview render. Preview renders from a downscaled copy; export uses full res.
final class EditorModel: ObservableObject {
    @Published var params = Params() { didSet { scheduleRender() } }
    @Published private(set) var preview: CGImage?
    @Published private(set) var imageName: String?
    @Published private(set) var lutName: String?
    @Published private(set) var presetNames: [String] = []
    @Published var status: String?

    private let context = CIContext(options: [.cacheIntermediates: false])
    private let store = PresetStore()
    private let previewMaxDimension: CGFloat = 2048

    private var fullResImage: CIImage?
    private var previewSource: CIImage?
    private var lut: CubeLUT?
    private var renderWork: DispatchWorkItem?

    init() {
        refreshPresets()
    }

    var hasImage: Bool { fullResImage != nil }

    var imagePixelWidth: Int? { fullResImage.map { Int($0.extent.width.rounded()) } }

    // MARK: - Opening

    func open(url: URL) {
        guard let image = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            status = "Couldn't open \(url.lastPathComponent)."
            return
        }
        fullResImage = image
        previewSource = downscaled(image)
        imageName = url.lastPathComponent
        status = nil
        scheduleRender()
    }

    private func downscaled(_ image: CIImage) -> CIImage {
        let maxDim = max(image.extent.width, image.extent.height)
        guard maxDim > previewMaxDimension else { return image }
        let scale = previewMaxDimension / maxDim
        return image.applyingFilter("CILanczosScaleTransform", parameters: [
            kCIInputScaleKey: scale,
            kCIInputAspectRatioKey: 1.0,
        ])
    }

    // MARK: - LUT

    func loadLUT(url: URL) {
        do {
            lut = try CubeLUT.load(from: url)
            lutName = url.lastPathComponent
            status = nil
            scheduleRender()
        } catch {
            status = "LUT: \(error.localizedDescription)"
        }
    }

    func clearLUT() {
        lut = nil
        lutName = nil
        scheduleRender()
    }

    // MARK: - Presets

    func refreshPresets() {
        presetNames = store.names()
    }

    func applyPreset(_ name: String) {
        do {
            let preset = try store.load(name)
            if let fileName = preset.lutFileName {
                lut = try? CubeLUT.load(from: store.lutURL(forFileName: fileName))
                lutName = lut == nil ? nil : fileName
            } else {
                lut = nil
                lutName = nil
            }
            params = preset.params  // didSet schedules the render
            status = nil
        } catch {
            status = "Couldn't load preset \"\(name)\"."
        }
    }

    func savePreset(named name: String) {
        if let saved = writePreset(named: name) {
            status = "Saved preset \"\(saved)\"."
        }
    }

    /// Re-save an existing preset from the live editor state.
    func updatePreset(_ name: String) {
        if writePreset(named: name) != nil {
            status = "Updated preset \"\(name)\"."
        }
    }

    func deletePreset(_ name: String) {
        store.delete(name)
        refreshPresets()
        status = "Deleted preset \"\(name)\"."
    }

    func renamePreset(_ name: String, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != name else { return }
        do {
            try store.rename(name, to: trimmed)
            refreshPresets()
            status = "Renamed to \"\(trimmed)\"."
        } catch PresetStoreError.nameTaken {
            status = "A preset named \"\(trimmed)\" already exists."
        } catch {
            status = "Couldn't rename preset."
        }
    }

    /// Writes the current params and LUT under `name`. Returns the trimmed name
    /// on success, or nil if the name was blank or the write failed.
    private func writePreset(named name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var fileName: String?
        if let source = lut?.sourceURL {
            fileName = try? store.importLUT(from: source)
        } else if let existing = lutName {
            fileName = existing  // LUT came from a preset already in the store
        }
        do {
            try store.save(Preset(name: trimmed, params: params, lutFileName: fileName))
            refreshPresets()
            return trimmed
        } catch {
            status = "Couldn't save preset."
            return nil
        }
    }

    // MARK: - Reset

    func reset() {
        params = Params()
    }

    // MARK: - Export

    func export(to url: URL, settings: ExportSettings) {
        guard let fullResImage else { return }
        let rendered = Pipeline.apply(to: fullResImage, params: params, lut: lut)
        do {
            try Exporter.write(rendered, to: url, settings: settings, context: context)
            status = "Exported \(url.lastPathComponent)."
        } catch {
            status = "Export failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Rendering

    private func scheduleRender() {
        // Snapshot everything the render reads here on the main thread, so the
        // background work item never touches mutable model state concurrently.
        guard let source = previewSource else { return }
        let params = self.params
        let lut = self.lut
        renderWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.render(source: source, params: params, lut: lut)
        }
        renderWork = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.015, execute: work)
    }

    private func render(source: CIImage, params: Params, lut: CubeLUT?) {
        let output = Pipeline.apply(to: source, params: params, lut: lut)
        let cg = context.createCGImage(
            output,
            from: source.extent,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
        DispatchQueue.main.async { [weak self] in self?.preview = cg }
    }
}
