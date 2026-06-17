import CoreImage
import XCTest
@testable import MinimalEditorCore

final class CubeLUTTests: XCTestCase {
    /// A 2×2×2 identity LUT in `.cube` order (red fastest).
    private let identityCube = """
    # tiny identity LUT
    TITLE "identity"
    LUT_3D_SIZE 2
    0 0 0
    1 0 0
    0 1 0
    1 1 0
    0 0 1
    1 0 1
    0 1 1
    1 1 1
    """

    func testParsesDimensionAndEntryCount() throws {
        let lut = try CubeLUT.parse(identityCube)
        XCTAssertEqual(lut.dimension, 2)
        // 2³ entries × 4 floats (RGBA) × 4 bytes each.
        XCTAssertEqual(lut.data.count, 8 * 4 * MemoryLayout<Float>.size)
    }

    func testRejectsMissingSize() {
        XCTAssertThrowsError(try CubeLUT.parse("0 0 0\n1 1 1")) { error in
            XCTAssertEqual(error as? CubeLUT.ParseError, .missingSize)
        }
    }

    func testRejects1D() {
        XCTAssertThrowsError(try CubeLUT.parse("LUT_1D_SIZE 4")) { error in
            XCTAssertEqual(error as? CubeLUT.ParseError, .oneDimensionalUnsupported)
        }
    }

    func testRejectsWrongEntryCount() {
        let truncated = "LUT_3D_SIZE 2\n0 0 0\n1 0 0"
        XCTAssertThrowsError(try CubeLUT.parse(truncated)) { error in
            guard case .wrongEntryCount = (error as? CubeLUT.ParseError) else {
                return XCTFail("expected wrongEntryCount, got \(error)")
            }
        }
    }

    /// The single most important test: an identity LUT must leave colors unchanged.
    /// A wrong axis ordering would permute channels, so a non-gray color would shift.
    func testIdentityLUTPreservesColor() throws {
        let lut = try CubeLUT.parse(identityCube)
        let context = CIContext(options: [.useSoftwareRenderer: true])

        for color in [
            CIColor(red: 0.2, green: 0.6, blue: 0.8),
            CIColor(red: 0.9, green: 0.1, blue: 0.3),
            CIColor(red: 0.5, green: 0.5, blue: 0.5),
        ] {
            let source = CIImage(color: color).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4))
            let baseline = pixel(of: source, context: context)
            let through = pixel(of: Pipeline.apply(to: source, params: Params(), lut: lut), context: context)

            for c in 0..<3 {
                XCTAssertEqual(Double(baseline[c]), Double(through[c]), accuracy: 4,
                               "channel \(c) drifted for \(color)")
            }
        }
    }

    /// Read the bottom-left pixel as RGBA8 in sRGB.
    private func pixel(of image: CIImage, context: CIContext) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        context.render(
            image,
            toBitmap: &buffer,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: space)
        return buffer
    }
}
