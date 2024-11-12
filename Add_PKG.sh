#!/bin/bash

error() {
    echo "Error: $1" >&2
    exit 1
}

check_dependencies() {
    local deps=("pacman" "repo-add" "git" "makepkg")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "The required command '$cmd' was not found. Please install it."
        fi
    done
}

prompt() {
    local prompt_text="$1"
    local __resultvar=$2
    local default_value="$3"
    local input=""
    if [ -n "$default_value" ]; then
        prompt_text="$prompt_text [$default_value]: "
    else
        prompt_text="$prompt_text: "
    fi
    while true; do
        read -p "$prompt_text" input
        if [ -z "$input" ]; then
            if [ -n "$default_value" ]; then
                input="$default_value"
                break
            else
                echo "Input cannot be empty. Please try again."
            fi
        else
            break
        fi
    done
    eval "$__resultvar=\"\$input\""
}

select_source() {
    local __resultvar=$1
    local valid=0
    while [ $valid -eq 0 ]; do
        echo "Select the package source:"
        echo "1) Official repository"
        echo "2) AUR"
        read -p "Enter the option number (1 or 2): " choice
        case "$choice" in
            1)
                source="repo"
                valid=1
                ;;
            2)
                source="aur"
                valid=1
                ;;
            *)
                echo "Invalid selection. Please enter 1 or 2."
                ;;
        esac
    done
    eval "$__resultvar=\"$source\""
}

ensure_repo_path() {
    if [ ! -d "$repo_path" ]; then
        echo "Local repository not found. Creating repository..."
        mkdir -p "$repo_path" || error "Failed to create local repository."
    else
        echo "Local repository already exists. Skipping creation."
    fi
}

download_from_repo() {
    for pkg in "${package_names[@]}"; do
        echo "Downloading package $pkg from the official repository..."
        sudo pacman -Sw --noconfirm "$pkg" || error "Failed to download package $pkg."
        echo "Moving package $pkg to the local repository..."
        sudo mv /var/cache/pacman/pkg/$pkg-*.pkg.tar.zst "$repo_path" || error "Failed to move package $pkg to the local repository."
    done
}

download_from_aur() {
    for pkg in "${package_names[@]}"; do
        echo "Cloning repository $pkg from AUR..."
        git clone "https://aur.archlinux.org/$pkg.git" || error "Failed to clone repository $pkg."
        cd "$pkg" || error "Failed to enter directory $pkg."
        echo "Building package $pkg..."
        makepkg --noconfirm --needed || error "Failed to build package $pkg."
        echo "Moving built package $pkg to the local repository..."
        mv *.pkg.tar.zst "$repo_path" || error "Failed to move built package $pkg to the local repository."
        cd ..
        rm -rf "$pkg"
    done
}

update_repo_db() {
    echo "Updating local repository database..."
    repo_add_db="$repo_path/$(basename $repo_path).db.tar.gz"
    for pkg in "${package_names[@]}"; do
        repo-add "$repo_add_db" "$repo_path"/$pkg-*.pkg.tar.zst || error "Failed to update database for package $pkg."
    done
}

check_dependencies

select_source source

prompt "Enter package names (space-separated)" package_names_input

IFS=' ' read -r -a package_names <<< "$package_names_input"

default_repo_path="./LocalUserRepo"

prompt "Enter the path to the local repository" repo_path "$default_repo_path"

ensure_repo_path

if [ "$source" == "repo" ]; then
    download_from_repo
elif [ "$source" == "aur" ]; then
    download_from_aur
fi

update_repo_db

echo "Packages successfully added to the local repository."

exit 0
