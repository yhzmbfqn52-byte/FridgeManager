# FridgeManager — Logo export & dark theme

This project includes a programmatic `AppLogoView` (a scalable SwiftUI fridge logo) and forces a dark app theme. The app prefers an `AppLogo` asset (if present) on the splash screen but otherwise uses the programmatic logo.

## Export `AppLogoView` to PNG
You can export the logo from the `AppLogoView` for use in `Assets.xcassets`.

Option A — Xcode preview (manual):
1. Open `AppLogoView.swift` in Xcode and show the canvas.
2. Set the preview size (e.g., 1024x1024) and use `Export Preview...` to save a PNG.

Option B — Programmatic helper (macOS):
A small macOS Swift script is included at `tools/generate_icons.swift` that renders a fridge logo at the requested pixel sizes and writes PNGs directly into the asset catalog. There's also a convenience wrapper `tools/regenerate_icons.sh` which regenerates icons, removes stray PNGs, runs a clean build, and runs tests.

Example:

```bash
# Regenerate icons and run a validation build & tests
chmod +x tools/regenerate_icons.sh
./tools/regenerate_icons.sh
```

After regenerating, the script writes all icon PNGs into `FridgeManager/Assets.xcassets/AppIcon.appiconset/` and `FridgeManager/Assets.xcassets/AppLogo.imageset/`.

## Adding or replacing the assets manually
1. In Xcode, open `Assets.xcassets`.
2. Create an Image Set named exactly `AppLogo` and drop the exported PNG(s) into the appropriate scale slots (1x/2x/3x) or use a PDF vector.
3. For the application icon, open the `AppIcon` image set and add PNGs in the required sizes (1024, 180, 120, 76, 152, etc.). The generator already populates common sizes.

## Run the app in Simulator (CLI)
1. Build the project for the iOS simulator:

```bash
xcodebuild -project /path/to/FridgeManager.xcodeproj -scheme FridgeManager -sdk iphonesimulator -configuration Debug build
```

2. Locate the built `.app` (example path):
```
~/Library/Developer/Xcode/DerivedData/<project>/Build/Products/Debug-iphonesimulator/FridgeManager.app
```

3. Install and launch on a booted iOS 26.2 simulator (example UDID), or boot one with `simctl`:

```bash
# List simulators
xcrun simctl list devices

# Boot an iOS 26.2 device (if needed)
xcrun simctl boot <UDID>

# Install and launch
xcrun simctl install <UDID> /path/to/FridgeManager.app
xcrun simctl launch <UDID> be.razor.FridgeManager
```

## Screenshots
The helper scripts / ci steps will save a screenshot under `build/screenshots/FridgeManager-simulator.png` when requested locally.

## Notes
- The app forces dark mode via `.preferredColorScheme(.dark)`—ensure exported assets look correct on a dark background or provide light/dark variants.
- A small generator is included to create consistent fridge-themed icons; run `./tools/regenerate_icons.sh` to rebuild and validate.

## Commit changes
If you want these changes recorded in git, run:

```bash
# create branch, stage, commit
git checkout -b feat/assets-and-scripts
git add tools/generate_icons.swift tools/regenerate_icons.sh FridgeManager/Assets.xcassets FridgeManager/FridgeManagerApp.swift FridgeManager/SplashView.swift FridgeManager/FridgeSettingsView.swift FridgeManager/ContentView.swift FridgeManager/AboutView.swift FridgeManager/AppLogoView.swift README.md

git commit -m "feat: add icon generator, regen script, splash & wizard UX; tidy assets"
```

If you want me to create the branch and commit for you, I can do that now.
