#!/usr/bin/env bash

# --- CONFIGURATION ---
PKG_LIST="packages.txt"      # File containing one AUR package name per line
REPO_DIR="./x86_64"          # Where to move finished .pkg.tar.zst files
BUILD_DIR="./build_temp"     # Temporary directory for building
LOG_FILE="build_log.txt"     # Log file for build results

# Ensure directories exist
mkdir -p "$REPO_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Starting AUR Build Automation"
echo "==> Build started at: $(date)" > "$LOG_FILE"

# Check if package list exists
if [ ! -f "$PKG_LIST" ]; then
    echo "Error: $PKG_LIST not found. Create it with one package name per line."
    exit 1
fi

# Function to build a package
build_pkg() {
    local pkg_name=$1
    echo "--------------------------------------"
    echo "==> Building: $pkg_name"
    echo "--------------------------------------"

    cd "$BUILD_DIR" || return

    # 1. Clone or Update
    if [ -d "$pkg_name" ]; then
        echo "Updating existing source..."
        cd "$pkg_name" && git pull && cd ..
    else
        echo "Cloning source..."
        git clone "https://aur.archlinux.org/$pkg_name.git"
    fi

    # 2. Build with makepkg
    # -s: Install missing dependencies
    # -f: Force build even if already built
    # --noconfirm: Don't ask for permission to install deps
    # --needed: Don't reinstall up-to-date deps
    cd "$pkg_name" || return
    
    if makepkg -sf --noconfirm --needed; then
        echo "SUCCESS: $pkg_name built successfully." | tee -a "../../$LOG_FILE"
        
        # 3. Move the resulting packages to the repo directory
        # We use mv to ensure we don't build it again next time if logic is added
        mv *.pkg.tar.zst "../../$REPO_DIR/"
        
        # 4. Clean up the build directory to save space
        makepkg -c --noconfirm
    else
        echo "FAILED: $pkg_name failed to build." | tee -a "../../$LOG_FILE"
        return 1
    fi

    cd "../../"
}

# Read package list and iterate
while IFS= read -r package || [ -n "$package" ]; do
    # Skip empty lines or lines starting with #
    [[ -z "$package" || "$package" =~ ^# ]] && continue
    
    # Trim whitespace
    package=$(echo "$package" | xargs)
    
    build_pkg "$package"
done < "$PKG_LIST"

echo "--------------------------------------"
echo "==> All builds finished."
echo "==> Check $LOG_FILE for details."
echo "==> Check $REPO_DIR for your new packages."
