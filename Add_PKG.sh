#!/bin/bash

# Function to display an error message
error() {
    echo "Error: $1" >&2
    exit 1
}

# Prompt for package name and local repository path
read -p "Enter package name: " package_name
read -p "Enter local repository path: " repo_path

# Check if the specified local repository path exists
if [ ! -d "$repo_path" ]; then
    error "The specified local repository path does not exist."
fi

# Download the package
echo "Downloading package $package_name..."
sudo pacman -Sw --noconfirm $package_name || error "Failed to download package $package_name."

# Move the package to the local repository
echo "Moving package to the local repository..."
sudo mv /var/cache/pacman/pkg/$package_name-*.pkg.tar.zst "$repo_path" || error "Failed to move package to the local repository."

# Add the package to the local repository database
echo "Updating local repository database..."
repo-add "$repo_path"/your-localrepo.db.tar.gz "$repo_path"/$package_name-*.pkg.tar.zst || error "Failed to update local repository database."

echo "Package $package_name successfully added to the local repository."

exit 0
