fastlane setup for FridgeManager

Usage

1) Install fastlane (recommended via bundler or Homebrew):
   gem install fastlane

2) Configure Appfile with your Apple ID and Team ID (inside fastlane/Appfile)

3) Run the beta lane:
   cd FridgeManager
   fastlane beta

Notes
- For CI and non-interactive uploads, create an App Store Connect API key and configure fastlane to use it (FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD or API key configuration).
- You may need to set APP_STORE_CONNECT_USERNAME or use the Appfile apple_id value.
