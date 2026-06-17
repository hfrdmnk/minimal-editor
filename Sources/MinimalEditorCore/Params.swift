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

    // Overlay (a flat dark wash over the graded image)
    public var overlayOpacity: Double = 0    // 0 = off
    public var overlayHex: String = "#000000"

    public init() {}
}
