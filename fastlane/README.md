fastlane setup for FridgeManager

Usage

1) Install fastlane (recommended via bundler or Homebrew):
   gem install fastlane

2) Configure Appfile with your Apple ID and Team ID (inside fastlane/Appfile).
   - Set your Apple ID in `apple_id("your@appleid.example.com")`.
   - Ensure `team_id("22L5CCVC3A")` is correct for your developer account.

3) Create an App Store Connect API key (recommended for CI/non-interactive):
   - Sign in to App Store Connect: https://appstoreconnect.apple.com
   - Go to Users and Access → Keys → +
   - Create a key (role: App Manager) and download the .p8 file
   - Note the Key ID and Issuer ID

4) Prepare the JSON wrapper for the API key (paste your .p8 into the `key` value):

```json
{
  "key_id": "<KEY_ID>",
  "issuer_id": "<ISSUER_ID>",
  "key": "-----BEGIN PRIVATE KEY-----\n<PASTE_YOUR_.p8_CONTENT_HERE>\n-----END PRIVATE KEY-----\n",
  "in_house": false
}
```

5) Add the JSON above to your GitHub repository secrets:
   - Go to GitHub: Settings → Secrets → Actions → New repository secret
   - Name: `APP_STORE_CONNECT_API_KEY`
   - Value: the JSON text (single secret)
   - Also add `FASTLANE_USER` (your Apple ID email) and `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` (if you prefer using an app-specific password for uploads)

6) CI behavior (already added):
   - On push to `main`, the workflow writes `APP_STORE_CONNECT_API_KEY` to `./AuthKey.json` and runs `fastlane beta`.

7) Running locally (interactive):
   - If you run `fastlane beta` locally without API key, fastlane will prompt for your Apple ID and may require 2FA.

8) Running locally (non-interactive using API key):
   - Save the JSON wrapper to `fastlane/AuthKey.json` and set env var `APP_STORE_CONNECT_API_KEY_PATH=fastlane/AuthKey.json` before running `fastlane beta`.

9) Troubleshooting:
   - If code signing fails during export, ensure your machine has the proper provisioning profiles or set `signingStyle` to manual and provide provisioning profiles.
   - If fastlane can't find the app or scheme, confirm the `FridgeManager.xcodeproj` and `FridgeManager` scheme exist.
