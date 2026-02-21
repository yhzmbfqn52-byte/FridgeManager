fastlane setup for FridgeManager

Usage

1) Install fastlane (recommended via bundler or Homebrew):
   gem install fastlane

2) Configure Appfile with your Apple ID and Team ID (inside `fastlane/Appfile`).
   - Set your Apple ID in `apple_id("your@appleid.example.com")`.
   - Ensure `team_id("22L5CCVC3A")` is correct for your developer account.

3) Create an App Store Connect API key (recommended for CI/non-interactive):
   - Sign in to App Store Connect: https://appstoreconnect.apple.com
   - Go to Users and Access → Keys → +
   - Create a key (role: App Manager) and download the `.p8` file
   - Note the Key ID and Issuer ID

4) Prepare the JSON wrapper for the API key (paste your `.p8` contents into the `key` value):

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

6) fastlane match (managing certs & profiles)

fastlane `match` centralizes signing by storing certificates & provisioning profiles in an encrypted git repo. To use it:

  a) Create a private git repository to store certificates (e.g., `https://github.com/<you>/certificates.git`).
  b) Set `git_url` in `fastlane/Matchfile` to point to that repo.
  c) Run the helper locally (you will be prompted for Apple credentials and an encryption passphrase):

```bash
# install fastlane dependencies (if using bundler)
bundle install

# initialize match (one-time)
fastlane match init

# create or sync certificates/profiles (example: development)
./scripts/match_sync.sh development
# or for app store distribution
./scripts/match_sync.sh appstore
```

Notes on match and CI
- For CI, use `match` in `--readonly` mode and store access credentials in GitHub Secrets; fastlane will fetch profiles during CI runs.
- `match` requires an Apple ID with appropriate permissions to create certificates/profiles.

7) Running locally (interactive):
   - Run `fastlane beta` locally to build and upload interactively. Fastlane will prompt for credentials if needed.

8) Troubleshooting:
   - If Xcode complains "No profiles for '...'", enable automatic signing in Xcode or use `match` to install profiles.
   - For CI, ensure the runner has access to the certificates repo or uses an API key and `match` in readonly mode.

That's it — the repo includes helper scripts (`scripts/build_export.sh`, `scripts/match_sync.sh`) and fastlane lanes (see `fastlane/Fastfile`) to automate building, uploading, inviting testers, and distributing builds.
