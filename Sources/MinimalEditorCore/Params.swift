import Foundation

/// Every adjustment in the editor, with neutral defaults.
/// "Neutral" means the corresponding filter is skipped entirely, so an
/// untouched photo renders byte-for-byte identical to the source.
public struct Params: Equatable, Codable {
    // Light
    public var exposure: Double = 0      // EV, applied by CIExposureAdjust
    public var contrast: Double = 1      // 1 = neutral
    public var brightness: Double = 0    // 0 = neutral
    public var highlights: Double = 1    // 1 = neutral (CIHighlightShadowAdjust)
    public var shadows: Double = 0       // 0 = neutral

    // Color
    public var temperature: Double = 6500  // Kelvin, 6500 = neutral
    public var tint: Double = 0            // 0 = neutral
    public var saturation: Double = 1      // 1 = neutral
    public var vibrance: Double = 0        // 0 = neutral (midtone-weighted)

    // Effects
    public var motionBlurRadius: Double = 0  // px, 0 = off
    public var motionBlurAngle: Double = 0   // degrees
    public var defocus: Double = 0           // 0 = off, soft-focus "dreamy" glow

    // Overlay (a flat dark wash over the graded image)
    public var overlayOpacity: Double = 0    // 0 = off
    public var overlayHex: String = "#000000"

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case exposure, contrast, brightness, highlights, shadows
        case temperature, tint, saturation, vibrance
        case motionBlurRadius, motionBlurAngle, defocus
        case overlayOpacity, overlayHex
    }

    // Decode tolerantly so presets saved before a field existed still load:
    // a missing key falls back to that field's neutral default.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Params()
        exposure = try c.decodeIfPresent(Double.self, forKey: .exposure) ?? d.exposure
        contrast = try c.decodeIfPresent(Double.self, forKey: .contrast) ?? d.contrast
        brightness = try c.decodeIfPresent(Double.self, forKey: .brightness) ?? d.brightness
        highlights = try c.decodeIfPresent(Double.self, forKey: .highlights) ?? d.highlights
        shadows = try c.decodeIfPresent(Double.self, forKey: .shadows) ?? d.shadows
        temperature = try c.decodeIfPresent(Double.self, forKey: .temperature) ?? d.temperature
        tint = try c.decodeIfPresent(Double.self, forKey: .tint) ?? d.tint
        saturation = try c.decodeIfPresent(Double.self, forKey: .saturation) ?? d.saturation
        vibrance = try c.decodeIfPresent(Double.self, forKey: .vibrance) ?? d.vibrance
        motionBlurRadius = try c.decodeIfPresent(Double.self, forKey: .motionBlurRadius) ?? d.motionBlurRadius
        motionBlurAngle = try c.decodeIfPresent(Double.self, forKey: .motionBlurAngle) ?? d.motionBlurAngle
        defocus = try c.decodeIfPresent(Double.self, forKey: .defocus) ?? d.defocus
        overlayOpacity = try c.decodeIfPresent(Double.self, forKey: .overlayOpacity) ?? d.overlayOpacity
        overlayHex = try c.decodeIfPresent(String.self, forKey: .overlayHex) ?? d.overlayHex
    }
}
