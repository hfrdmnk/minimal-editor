import XCTest
@testable import MinimalEditorCore

final class PresetTests: XCTestCase {
    func testRoundTrip() throws {
        var params = Params()
        params.exposure = 0.4
        params.temperature = 5200
        params.tint = -12
        params.saturation = 1.15
        params.motionBlurRadius = 8
        params.motionBlurAngle = 90
        params.overlayOpacity = 0.18
        params.overlayHex = "#0A1F3C"

        let preset = Preset(name: "Evening", params: params, lutFileName: "look.cube")

        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(Preset.self, from: data)

        XCTAssertEqual(preset, decoded)
    }

    /// A preset JSON written before the defocus fields existed must still
    /// decode, with the missing fields falling back to their neutral defaults.
    func testDecodesPresetMissingNewField() throws {
        let json = """
        {
          "name": "Legacy",
          "params": {
            "exposure": 0.4,
            "contrast": 1.1,
            "brightness": 0,
            "highlights": 1,
            "shadows": 0,
            "temperature": 5200,
            "tint": -12,
            "saturation": 1.15,
            "vibrance": 0,
            "motionBlurRadius": 8,
            "motionBlurAngle": 90,
            "overlayOpacity": 0.18,
            "overlayHex": "#0A1F3C"
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Preset.self, from: json)
        XCTAssertEqual(decoded.params.defocusRadius, 0)
        XCTAssertEqual(decoded.params.defocusGlow, 0)
        XCTAssertEqual(decoded.params.defocusMode, .defocus)
        XCTAssertEqual(decoded.params.motionBlurRadius, 8)
        XCTAssertEqual(decoded.params.overlayHex, "#0A1F3C")
    }

    /// The old single `defocus` slider maps onto the radius/glow pair in the
    /// .defocus mode, which reproduces its original look.
    func testMigratesLegacyDefocusField() throws {
        let json = """
        { "name": "Legacy Defocus", "params": { "defocus": 0.6 } }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Preset.self, from: json)
        XCTAssertEqual(decoded.params.defocusMode, .defocus)
        XCTAssertEqual(decoded.params.defocusRadius, 18, accuracy: 1e-9)
        XCTAssertEqual(decoded.params.defocusGlow, 0.6, accuracy: 1e-9)
    }

    func testStoreSaveLoadDelete() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MinimalEditorTests-\(UUID().uuidString)")
        let store = PresetStore(directory: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        XCTAssertTrue(store.names().isEmpty)

        let preset = Preset(name: "Soft", params: Params())
        try store.save(preset)

        XCTAssertEqual(store.names(), ["Soft"])
        XCTAssertEqual(try store.load("Soft"), preset)

        store.delete("Soft")
        XCTAssertTrue(store.names().isEmpty)
    }

    func testStoreRename() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MinimalEditorTests-\(UUID().uuidString)")
        let store = PresetStore(directory: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        var params = Params()
        params.exposure = 0.3
        try store.save(Preset(name: "A", params: params, lutFileName: "look.cube"))

        try store.rename("A", to: "B")

        XCTAssertEqual(store.names(), ["B"])
        let renamed = try store.load("B")
        XCTAssertEqual(renamed.name, "B")
        XCTAssertEqual(renamed.params.exposure, 0.3)
        XCTAssertEqual(renamed.lutFileName, "look.cube")

        // Renaming onto an existing name must throw rather than clobber it.
        try store.save(Preset(name: "C", params: Params()))
        XCTAssertThrowsError(try store.rename("B", to: "C")) { error in
            guard case PresetStoreError.nameTaken = error else {
                return XCTFail("expected nameTaken, got \(error)")
            }
        }
        XCTAssertEqual(store.names(), ["B", "C"])
    }
}
