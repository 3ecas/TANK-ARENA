#!/usr/bin/env bash
# Builds Frontline in release mode and packages it as dist/Frontline.app
# (icon generated in code, Info.plist, ad-hoc code signature).
set -euo pipefail

cd "$(dirname "$0")/.."
APP_NAME="Frontline"
BUNDLE_ID="com.frontline.game"
VERSION="1.0.0"
DIST_DIR="dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"

# --- Requirements -----------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "error: Frontline is a native macOS game and must be built on macOS." >&2
    exit 1
fi
if ! xcode-select -p >/dev/null 2>&1; then
    echo "error: the Xcode Command Line Tools are not installed." >&2
    echo "       Install them with:  xcode-select --install" >&2
    exit 1
fi
if ! command -v swift >/dev/null 2>&1; then
    echo "error: 'swift' was not found. Install the Command Line Tools with: xcode-select --install" >&2
    exit 1
fi
echo "==> Command Line Tools: $(xcode-select -p)"
echo "==> $(swift --version 2>&1 | head -n 1)"

# --- Build ------------------------------------------------------------------
echo "==> Building $APP_NAME (release)..."
LOG_FILE="$DIST_DIR/build.log"
mkdir -p "$DIST_DIR"
if ! swift build -c release --product "$APP_NAME" 2>&1 | tee "$LOG_FILE"; then
    echo ""
    echo "================ BUILD ERRORS ================"
    grep -E "error:" "$LOG_FILE" | grep -v "Build failed" | sort -u | head -40 || true
    echo "=============================================="
    echo "Full log: $LOG_FILE"
    exit 1
fi
BIN_DIR="$(swift build -c release --show-bin-path)"

# --- Bundle -----------------------------------------------------------------
echo "==> Packaging $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# App icon: the game binary draws it, sips/iconutil (built into macOS) build the .icns.
WORK_DIR="$(mktemp -d)"
ICONSET="$WORK_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
if "$APP_DIR/Contents/MacOS/$APP_NAME" --generate-icon "$WORK_DIR/icon_1024.png"; then
    for size in 16 32 128 256 512; do
        double=$((size * 2))
        sips -z "$size" "$size" "$WORK_DIR/icon_1024.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
        sips -z "$double" "$double" "$WORK_DIR/icon_1024.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
    echo "==> App icon generated"
else
    echo "warning: icon generation failed; the app will use the default icon." >&2
fi
rm -rf "$WORK_DIR"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.strategy-games</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLIST
printf "APPL????" > "$APP_DIR/Contents/PkgInfo"

# --- Sign ---------------------------------------------------------------------
echo "==> Ad-hoc code signing"
xattr -cr "$APP_DIR" 2>/dev/null || true
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --verbose=1 "$APP_DIR"

echo ""
echo "Done: $APP_DIR"
echo "Double-click it in Finder, or run:  open \"$APP_DIR\""
