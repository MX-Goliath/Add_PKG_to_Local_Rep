#!/bin/bash

# Function to display an error message
error() {
    echo "Error: $1" >&2
    exit 1
}

# Prompt the user to choose the package source (official repository or AUR)
read -p "Download the package from the official repository or AUR? (repo/aur): " source

if [ "$source" == "repo" ]; then
    # Prompt for the package name and local repository path
    read -p "Enter the package name: " package_name
elif [ "$source" == "aur" ]; then
    # Prompt for the AUR clone URL
    read -p "Enter the AUR clone URL: " aur_url
    # Extract the package name from the URL
    package_name=$(basename "$aur_url" .git)
else
    error "Invalid source choice. Please choose 'repo' or 'aur'."
fi

# Prompt for the local repository path
read -p "Enter the local repository path: " repo_path

# Check if the specified local repository path exists
if [ ! -d "$repo_path" ]; then
    error "The specified local repository path does not exist."
fi

if [ "$source" == "repo" ]; then
    # Download the package from the official repository
    echo "Downloading package $package_name from the official repository..."
    sudo pacman -Sw --noconfirm $package_name || error "Failed to download package $package_name."

    # Move the package to the local repository
    echo "Moving the package to the local repository..."
    sudo mv /var/cache/pacman/pkg/$package_name-*.pkg.tar.zst "$repo_path" || error "Failed to move the package to the local repository."
elif [ "$source" == "aur" ]; then
    # Clone the repository from AUR
    echo "Cloning repository $package_name from AUR..."
    git clone "$aur_url" || error "Failed to clone repository $aur_url."

    # Change to the package source directory
    cd "$package_name" || error "Failed to change to directory $package_name."

    # Build the package
    echo "Building package $package_name..."
    makepkg --noconfirm || error "Failed to build package $package_name."

    # Move the built package to the local repository
    echo "Moving the built package to the local repository..."
    mv *.pkg.tar.zst "$repo_path" || error "Failed to move the built package to the local repository."

    # Change back to the original directory
    cd ..
fi

# Add the package to the local repository database
echo "Updating the local repository database..."
repo-add "$repo_path"/your-localrepo.db.tar.gz "$repo_path"/$package_name-*.pkg.tar.zst || error "Failed to update the local repository database."

echo "Package $package_name successfully added to the local repository."

exit 0
