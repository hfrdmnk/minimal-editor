import CoreImage
import ImageIO
import XCTest
@testable import MinimalEditorCore

final class PipelineExportTests: XCTestCase {
    private let context = CIContext(options: [.useSoftwareRenderer: true])

    /// A neutral Params object must leave the image untouched (every stage skipped).
    func testNeutralParamsPassThrough() {
        let source = CIImage(color: CIColor(red: 0.3, green: 0.5, blue: 0.7))
            .cropped(to: CGRect(x: 0, y: 0, width: 16, height: 16))
        let out = Pipeline.apply(to: source, params: Params(), lut: nil)
        XCTAssertEqual(out.extent, source.extent)
    }

    /// Motion blur expands the working extent; the pipeline must crop it back.
    func testMotionBlurKeepsExtent() {
        let source = CIImage(color: CIColor(red: 0.4, green: 0.4, blue: 0.4))
            .cropped(to: CGRect(x: 0, y: 0, width: 64, height: 64))
        var params = Params()
        params.motionBlurRadius = 20
        params.motionBlurAngle = 30
        let out = Pipeline.apply(to: source, params: params, lut: nil)
        XCTAssertEqual(out.extent, source.extent)
    }

    /// Defocus runs a Gaussian blur, which also expands the extent; crop it back.
    /// Both modes must preserve the extent.
    func testDefocusKeepsExtent() {
        let source = CIImage(color: CIColor(red: 0.4, green: 0.4, blue: 0.4))
            .cropped(to: CGRect(x: 0, y: 0, width: 64, height: 64))

        var hardBlur = Params()
        hardBlur.defocusMode = .hardBlur
        hardBlur.defocusRadius = 18
        XCTAssertEqual(Pipeline.apply(to: source, params: hardBlur, lut: nil).extent, source.extent)

        var defocus = Params()
        defocus.defocusMode = .defocus
        defocus.defocusRadius = 18
        defocus.defocusGlow = 0.6
        XCTAssertEqual(Pipeline.apply(to: source, params: defocus, lut: nil).extent, source.extent)
    }

    /// Full pipeline through the PNG and JPEG writers, then re-read to confirm
    /// the files are valid images at the original resolution.
    func testExportRoundTrip() throws {
        let source = CIImage(color: CIColor(red: 0.55, green: 0.35, blue: 0.2))
            .cropped(to: CGRect(x: 0, y: 0, width: 80, height: 60))

        var params = Params()
        params.exposure = 0.3
        params.contrast = 1.1
        params.saturation = 1.2
        params.temperature = 5200
        params.motionBlurRadius = 6
        params.overlayOpacity = 0.2
        params.overlayHex = "#101820"

        let rendered = Pipeline.apply(to: source, params: params, lut: nil)

        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MinimalEditorExport-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let png = dir.appendingPathComponent("out.png")
        let jpg = dir.appendingPathComponent("out.jpg")
        let avif = dir.appendingPathComponent("out.avif")
        try Exporter.write(rendered, to: png, settings: ExportSettings(format: .png), context: context)
        try Exporter.write(rendered, to: jpg, settings: ExportSettings(format: .jpeg, quality: 0.9), context: context)
        try Exporter.write(rendered, to: avif, settings: ExportSettings(format: .avif, quality: 0.6), context: context)

        for url in [png, jpg, avif] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "\(url.lastPathComponent) missing")
            let image = try readImage(url)
            XCTAssertEqual(image.width, 80)
            XCTAssertEqual(image.height, 60)
        }
    }

    /// Max width scales the image down (aspect preserved) only when it's wider.
    func testMaxWidthDownscale() throws {
        let source = CIImage(color: CIColor(red: 0.2, green: 0.6, blue: 0.4))
            .cropped(to: CGRect(x: 0, y: 0, width: 80, height: 60))
        let rendered = Pipeline.apply(to: source, params: Params(), lut: nil)

        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MinimalEditorExport-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        // Narrower than the source: scales to width 40, height follows to 30.
        let small = dir.appendingPathComponent("small.png")
        try Exporter.write(rendered, to: small, settings: ExportSettings(format: .png, maxWidth: 40), context: context)
        let smallImage = try readImage(small)
        XCTAssertEqual(smallImage.width, 40)
        XCTAssertEqual(smallImage.height, 30)

        // Wider than the source: left at full resolution.
        let big = dir.appendingPathComponent("big.png")
        try Exporter.write(rendered, to: big, settings: ExportSettings(format: .png, maxWidth: 999), context: context)
        let bigImage = try readImage(big)
        XCTAssertEqual(bigImage.width, 80)
        XCTAssertEqual(bigImage.height, 60)
    }

    private func readImage(_ url: URL) throws -> CGImage {
        let src = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(src, 0, nil))
    }
}
