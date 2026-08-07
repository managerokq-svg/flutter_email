#!/bin/bash
# Fix malformed framework symbolic links for App Store submission
# Apple requires: Resources -> Versions/Current/Resources (not Versions/A/Resources)

fix_framework() {
    local framework_path="$1"
    local framework_name=$(basename "$framework_path" .framework)

    if [ -d "$framework_path/Versions" ]; then
        echo "Fixing framework: $framework_name"
        cd "$framework_path"

        # Remove old symbolic links
        rm -f Resources
        rm -f "$framework_name"

        # Create correct symbolic links
        ln -sf Versions/Current/Resources Resources
        ln -sf "Versions/Current/$framework_name" "$framework_name"

        echo "  Fixed: Resources -> Versions/Current/Resources"
        echo "  Fixed: $framework_name -> Versions/Current/$framework_name"
    fi
}

# Find all frameworks in the app bundle
APP_PATH="$1"
if [ -z "$APP_PATH" ]; then
    echo "Usage: $0 <path-to-app-bundle>"
    exit 1
fi

FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"
if [ ! -d "$FRAMEWORKS_PATH" ]; then
    echo "Frameworks folder not found at: $FRAMEWORKS_PATH"
    exit 1
fi

echo "Fixing framework symbolic links in: $FRAMEWORKS_PATH"
for framework in "$FRAMEWORKS_PATH"/*.framework; do
    if [ -d "$framework" ]; then
        fix_framework "$framework"
    fi
done

echo "Done fixing framework symbolic links"
