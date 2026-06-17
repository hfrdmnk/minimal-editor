import CoreImage

/// The one pure function at the heart of the editor: `(CIImage, Params, LUT) -> CIImage`.
///
/// Fixed order: technical corrections, then the creative LUT, then blur, then the
/// overlay. Every stage is skipped when its parameters sit at neutral.
public enum Pipeline {
    public static func apply(to input: CIImage, params: Params, lut: CubeLUT?) -> CIImage {
        var image = input

        // 1. Exposure
        if params.exposure != 0 {
            image = image.applyingFilter("CIExposureAdjust", parameters: [
                kCIInputEVKey: params.exposure,
            ])
        }

        // 2. White balance
        if params.temperature != 6500 || params.tint != 0 {
            image = image.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: params.temperature, y: params.tint),
            ])
        }

        // 3. Highlights & shadows
        if params.highlights != 1 || params.shadows != 0 {
            image = image.applyingFilter("CIHighlightShadowAdjust", parameters: [
                "inputHighlightAmount": params.highlights,
                "inputShadowAmount": params.shadows,
            ])
        }

        // 4. Brightness / contrast / saturation
        if params.brightness != 0 || params.contrast != 1 || params.saturation != 1 {
            image = image.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: params.brightness,
                kCIInputContrastKey: params.contrast,
                kCIInputSaturationKey: params.saturation,
            ])
        }

        // 5. Vibrance (midtone-weighted, distinct from saturation)
        if params.vibrance != 0 {
            image = image.applyingFilter("CIVibrance", parameters: [
                kCIInputAmountKey: params.vibrance,
            ])
        }

        // 6. The LUT
        if let lut, let filter = lut.makeFilter() {
            filter.setValue(image, forKey: kCIInputImageKey)
            if let out = filter.outputImage { image = out }
        }

        // 7. Directional motion blur. Clamp before blurring and crop back after,
        // otherwise the blur samples transparent pixels past the edge and darkens it.
        if params.motionBlurRadius > 0 {
            let extent = image.extent
            image = image.clampedToExtent()
                .applyingFilter("CIMotionBlur", parameters: [
                    kCIInputRadiusKey: params.motionBlurRadius,
                    kCIInputAngleKey: params.motionBlurAngle * .pi / 180,
                ])
                .cropped(to: extent)
        }

        // 8. Defocus: a soft-focus "dreamy" glow. Screen-blend a blurred copy
        // over the sharp image so highlights bloom while detail survives. The
        // slider drives both the blur radius and the glow strength: the blurred
        // layer is faded toward black, and screen-blending black is a no-op, so
        // the effect scales smoothly from none (0) to full (1). Clamp/crop like
        // the motion blur so the Gaussian doesn't darken the edges.
        if params.defocus > 0 {
            let extent = image.extent
            let soft = image.clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [
                    kCIInputRadiusKey: params.defocus * 30,
                ])
                .cropped(to: extent)
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: params.defocus, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: params.defocus, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: params.defocus, w: 0),
                ])
            image = soft.applyingFilter("CIScreenBlendMode", parameters: [
                kCIInputBackgroundImageKey: image,
            ])
        }

        // 9. Flat dark overlay
        if params.overlayOpacity > 0 {
            let color = CIColor.fromHex(params.overlayHex, alpha: params.overlayOpacity)
            if let overlay = CIFilter(name: "CIConstantColorGenerator", parameters: [
                kCIInputColorKey: color,
            ])?.outputImage?.cropped(to: image.extent) {
                image = overlay.applyingFilter("CISourceOverCompositing", parameters: [
                    kCIInputBackgroundImageKey: image,
                ])
            }
        }

        return image
    }
}
