Invite testers to TestFlight — steps and fastlane examples

This document explains how to send TestFlight invites (internal, external, or public link) after you have uploaded a build to App Store Connect.

Prerequisites
- You must have an uploaded, processed build in App Store Connect for `be.razor.FridgeManager`.
- If using fastlane for invites, ensure `fastlane` is configured and you have `fastlane pilot` available.

Internal testers (no review)
1. Go to App Store Connect → My Apps → FridgeManager → TestFlight → Internal Testing
2. Add users from your team (they need App Store Connect access and suitable roles)
3. Select the build and enable internal testing
4. They will receive an email invite immediately.

External testers (requires beta review on first distribution)
1. App Store Connect → My Apps → FridgeManager → TestFlight → External Testing
2. Create a new group (e.g., "Beta Testers")
3. Add external tester emails (you can import a CSV)
4. Choose the build and submit for Beta App Review
5. After approval the testers receive email invites

Create a public TestFlight link
1. In TestFlight → External Testing → select a group (or create one)
2. Click Enable Public Link
3. Configure max testers and link settings
4. Copy the link and send it via email

Automating invites with fastlane (pilot)
- Add testers via command line (fastlane/pilot). Example:

# invite a single tester
fastlane pilot add --first_name "John" --last_name "Doe" --email "john@example.com"

# add multiple testers from a CSV (email,first name,last name)
cat testers.csv | while IFS=, read -r email first last; do fastlane pilot add --email "$email" --first_name "$first" --last_name "$last"; done

- To distribute a build to external testers using pilot:
fastlane pilot distribute -a be.razor.FridgeManager -b 1.0 -g "Beta Testers" --groups "Beta Testers"

Notes
- `pilot` operations may require additional permissions on your App Store Connect account.
- Creating a public link via the API is not officially supported; using the App Store Connect UI is recommended for public links.
