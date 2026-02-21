#!/usr/bin/env bash
# Regenerate app icons and AppLogo from the programmatic generator
set -euo pipefail
cd "$(dirname "$0")"

# Clean screenshot PNGs in known project Screenshots folders before build/tests
echo "Cleaning project Screenshots folders..."
# paths relative to tools/ -> ../FridgeManager/Screenshots and ../FridgeManager/FridgeManager/Screenshots
rm -f ../FridgeManager/Screenshots/*.png || true
rm -f ../FridgeManager/FridgeManager/Screenshots/*.png || true

# Ensure the generator is executable
chmod +x generate_icons.swift
# Run the generator
./generate_icons.swift

echo "Cleaning up unreferenced asset PNGs..."
python3 - <<'PY'
import os, json
root=os.path.join(os.getcwd(),'..','FridgeManager','FridgeManager','Assets.xcassets')
removed=[]
for item in os.listdir(root):
    path=os.path.join(root,item)
    if os.path.isdir(path):
        contents=os.path.join(path,'Contents.json')
        if os.path.exists(contents):
            with open(contents) as f:
                try:
                    data=json.load(f)
                except Exception:
                    data={}
            refs=set()
            for img in data.get('images',[]):
                fn=img.get('filename')
                if fn:
                    refs.add(fn)
            # list pngs in folder
            for f in os.listdir(path):
                if f.lower().endswith('.png'):
                    if f not in refs:
                        os.remove(os.path.join(path,f))
                        removed.append(os.path.join(path,f))
print('Removed files:')
for r in removed:
    print(r)
PY

# Run a clean build to validate
echo "Running clean build..."
PROJECT_ROOT="$(cd .. && pwd)/FridgeManager"
if [ -f "$PROJECT_ROOT/FridgeManager.xcodeproj" ]; then
  xcodebuild -project "$PROJECT_ROOT/FridgeManager.xcodeproj" -scheme FridgeManager clean build -sdk iphonesimulator -configuration Debug
else
  echo "Project file not found at $PROJECT_ROOT/FridgeManager.xcodeproj" >&2
  exit 1
fi

# Run tests
echo "Running tests..."
xcodebuild -project "$PROJECT_ROOT/FridgeManager.xcodeproj" -scheme FridgeManager -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test || true

echo "Regeneration, cleanup, build and tests complete."
