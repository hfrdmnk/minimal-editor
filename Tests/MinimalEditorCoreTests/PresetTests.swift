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
}
