import Foundation

/// Every adjustment in the editor, with neutral defaults.
/// "Neutral" means the corresponding filter is skipped entirely, so an
/// untouched photo renders byte-for-byte identical to the source.
public struct Params: Equatable, Codable {
    /// How the defocus blur is applied.
    public enum DefocusMode: String, Codable, CaseIterable {
        case defocus   // sharp image with a blurred glow halo (the dreamy look)
        case hardBlur  // a plain Gaussian blur, no glow
    }

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
    public var defocusMode: DefocusMode = .defocus
    public var defocusRadius: Double = 0     // px, 0 = off (out-of-focus blur)
    public var defocusGlow: Double = 0       // 0...1, glow strength (defocus mode only)

    // Overlay (a flat dark wash over the graded image)
    public var overlayOpacity: Double = 0    // 0 = off
    public var overlayHex: String = "#000000"

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case exposure, contrast, brightness, highlights, shadows
        case temperature, tint, saturation, vibrance
        case motionBlurRadius, motionBlurAngle
        case defocusMode, defocusRadius, defocusGlow
        case overlayOpacity, overlayHex
    }

    // `defocus` was one slider that drove both radius and glow; read separately
    // so the main keys stay 1:1 with the properties and encoding stays synthesized.
    private enum LegacyCodingKeys: String, CodingKey {
        case defocus
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
        defocusMode = try c.decodeIfPresent(DefocusMode.self, forKey: .defocusMode) ?? d.defocusMode
        // Defocus was once a single 0...1 slider (radius = defocus * 30, glow =
        // defocus) in what is now the .defocus mode. Map it onto the pair when
        // the new keys are absent.
        let legacyDefocus = try decoder.container(keyedBy: LegacyCodingKeys.self)
            .decodeIfPresent(Double.self, forKey: .defocus)
        defocusRadius = try c.decodeIfPresent(Double.self, forKey: .defocusRadius)
            ?? legacyDefocus.map { $0 * 30 } ?? d.defocusRadius
        defocusGlow = try c.decodeIfPresent(Double.self, forKey: .defocusGlow)
            ?? legacyDefocus ?? d.defocusGlow
        overlayOpacity = try c.decodeIfPresent(Double.self, forKey: .overlayOpacity) ?? d.overlayOpacity
        overlayHex = try c.decodeIfPresent(String.self, forKey: .overlayHex) ?? d.overlayHex
    }
}
