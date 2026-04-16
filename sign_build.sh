#!/bin/bash

# ==============================================================================
# Final Signing Script for Arianth IPA
# ==============================================================================

PROJECT_ROOT="/Users/admin/Downloads/flutter_projects/tara/arihanth-flutter"
ARCHIVE_PATH="$PROJECT_ROOT/build/ios/archive/Runner.xcarchive"
EXPORT_OPTIONS="$PROJECT_ROOT/ExportOptions.plist"
EXPORT_PATH="$PROJECT_ROOT/build/ios/ipa"
KEYCHAIN_PASS="Admin@123"

echo "🔓 Unlocking keychain for signing..."
security unlock-keychain -p "$KEYCHAIN_PASS" login.keychain-db

echo "🏗️  Starting final signed export..."
echo "⚠️  When the pop-up appears, enter your password and click 'Always Allow'"

# Run the export command
/usr/bin/arch -arm64e xcrun xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH" \
    -allowProvisioningUpdates

if [ $? -eq 0 ]; then
    echo "✅ SUCCESS! Your signed IPA is located at: $EXPORT_PATH"
    open "$EXPORT_PATH"
else
    echo "❌ Signing failed. Please ensure you clicked 'Always Allow' on the prompt."
fi
