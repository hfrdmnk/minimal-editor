import CoreImage

extension CIColor {
    /// Build a CIColor from a `#RRGGBB` string. Falls back to black on a bad string.
    public static func fromHex(_ hex: String, alpha: Double) -> CIColor {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        guard s.count == 6 else { return CIColor(red: 0, green: 0, blue: 0, alpha: alpha) }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        return CIColor(red: r, green: g, blue: b, alpha: alpha)
    }
}
