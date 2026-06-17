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
    func testDefocusKeepsExtent() {
        let source = CIImage(color: CIColor(red: 0.4, green: 0.4, blue: 0.4))
            .cropped(to: CGRect(x: 0, y: 0, width: 64, height: 64))
        var params = Params()
        params.defocus = 0.6
        let out = Pipeline.apply(to: source, params: params, lut: nil)
        XCTAssertEqual(out.extent, source.extent)
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
        try Exporter.write(rendered, to: png, format: .png, context: context)
        try Exporter.write(rendered, to: jpg, format: .jpeg(quality: 0.9), context: context)

        for url in [png, jpg] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "\(url.lastPathComponent) missing")
            let src = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(src, 0, nil))
            XCTAssertEqual(image.width, 80)
            XCTAssertEqual(image.height, 60)
        }
    }
}
