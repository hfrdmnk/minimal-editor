# Minimal Editor

A tiny native macOS photo editor. Open a photo, apply a `.cube` LUT plus a
handful of basic tweaks, directional motion blur, a defocus blur (dreamy glow
or plain), and a dark overlay, then export. Save the whole look as a reusable
preset.

Built with SwiftUI + Core Image. Every effect is a stock, Metal-accelerated
`CIFilter`.

## Build and run

```sh
./build.sh
open "dist/Minimal Editor.app"
```

`build.sh` compiles a release build and assembles a double-clickable
`.app` bundle under `dist/`. Requires Xcode / the Swift toolchain (no Xcode
project to open).

## Test

```sh
swift test
```

The suite covers the parts that actually have logic: `.cube` parsing and axis
ordering (identity-LUT round trip), the render pipeline (neutral pass-through,
motion-blur extent crop), preset save/load, and PNG/JPEG export.

## Using it

- **Open** a photo from the toolbar, or drag one onto the canvas.
- **Adjust** with the sliders on the right, grouped into Light, Color, and
  Effects. Double-click a slider (or its label) to return it to neutral.
- **Load a `.cube`** in the LUT section to apply a color grade.
- **Presets** (toolbar) save and recall the full look, LUT included. They live
  in `~/Library/Application Support/MinimalEditor/presets/`, with each LUT
  copied in alongside so presets are self-contained.
- **Export** to PNG or JPEG from the toolbar.

## Layout

- `Sources/MinimalEditorCore/` — pure logic, no UI. `Params`, `Pipeline`,
  `CubeLUT`, `Preset`, `PresetStore`, `Exporter`. This is what the tests import.
- `Sources/MinimalEditor/` — the SwiftUI app: entry point, `EditorModel`, views.
- `Packaging/Info.plist`, `build.sh` — bundle assembly.

The render pipeline is one pure function in `Pipeline.swift`:
`(CIImage, Params, CubeLUT?) -> CIImage`. Fixed order — exposure, white
balance, highlights/shadows, brightness/contrast/saturation, vibrance, LUT,
motion blur, defocus, overlay — with every stage skipped when its parameters sit at
neutral, so an untouched photo renders identically to the source.
