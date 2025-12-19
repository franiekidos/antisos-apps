#!/usr/bin/env bash

# --- CONFIGURATION ---
# Change these to match your repository settings
REPO_NAME="antisos-apps"
ARCH="x86_64"
REPO_DIR="./$ARCH"

echo "==> Starting repository maintenance..."

# Check if directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Error: Directory $REPO_DIR not found."
    exit 1
fi

cd "$REPO_DIR" || exit

# 1. Remove old database files and symlinks to prevent conflicts
# This ensures a clean state before repo-add runs
echo "==> Cleaning old database files..."
rm -f "$REPO_NAME.db" "$REPO_NAME.db.tar.gz" "$REPO_NAME.db.tar.gz.sig" "$REPO_NAME.db.sig"
rm -f "$REPO_NAME.files" "$REPO_NAME.files.tar.gz" "$REPO_NAME.files.tar.gz.sig" "$REPO_NAME.files.sig"

# 2. Add all packages to the database and sign it
# -s: Sign the database
# -v: Verify packages
# -R: Remove old entries from the database
echo "==> Running repo-add and signing..."
repo-add -s -v -R "$REPO_NAME.db.tar.gz" *.pkg.tar.zst

# 3. GitHub Compatibility Fix
# GitHub Pages/Raw does not resolve symlinks. We must replace the symlinks 
# (db/files) with the actual tarball content so Pacman can download them.
echo "==> Replacing symlinks with actual files for GitHub compatibility..."

# Handle the .db file: Remove the symlink created by repo-add and replace with a real file
if [ -L "$REPO_NAME.db" ] || [ -f "$REPO_NAME.db" ]; then
    rm -f "$REPO_NAME.db"
    cp "$REPO_NAME.db.tar.gz" "$REPO_NAME.db"
fi

# Handle the .files file: Remove the symlink and replace with a real file
if [ -L "$REPO_NAME.files" ] || [ -f "$REPO_NAME.files" ]; then
    rm -f "$REPO_NAME.files"
    cp "$REPO_NAME.files.tar.gz" "$REPO_NAME.files"
fi

# 4. Copy signatures to the non-tarball filenames
# We use -f to force overwrite and avoid any link-related identity errors
echo "==> Finalizing signatures..."
if [ -f "$REPO_NAME.db.tar.gz.sig" ]; then
    rm -f "$REPO_NAME.db.sig"
    cp "$REPO_NAME.db.tar.gz.sig" "$REPO_NAME.db.sig"
fi

if [ -f "$REPO_NAME.files.tar.gz.sig" ]; then
    rm -f "$REPO_NAME.files.sig"
    cp "$REPO_NAME.files.tar.gz.sig" "$REPO_NAME.files.sig"
fi

cd ..

echo "==> Maintenance complete."
echo "==> You can now git add, commit, and push your changes."
