#!/bin/bash

error() {
    echo "Error: $1" >&2
    exit 1
}

check_dependencies() {
    local deps=("pacman" "repo-add" "git" "makepkg")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "The command '$cmd' is required. Please install it."
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
        echo "1) Official Repository"
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
                echo "Invalid choice. Please enter 1 or 2."
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
        sudo mv /var/cache/pacman/pkg/"$pkg"-*.pkg.tar.zst "$repo_path" || error "Failed to move package $pkg to the local repository."
    done
}

download_from_aur() {
    for pkg in "${package_names[@]}"; do
        echo "Cloning repository $pkg from AUR..."
        git clone "https://aur.archlinux.org/$pkg.git" || error "Failed to clone repository $pkg."
        cd "$pkg" || error "Failed to navigate to directory $pkg."
        echo "Building package $pkg..."
        makepkg --noconfirm --needed || error "Failed to build package $pkg."
        echo "Moving the built package $pkg to the local repository..."
        mv *.pkg.tar.zst "$repo_path" || error "Failed to move the built package $pkg to the local repository."
        cd ..
        rm -rf "$pkg"
    done
}

update_repo_db() {
    echo "Updating the local repository database..."
    repo_add_db="$repo_path/$(basename "$repo_path").db.tar.gz"
    repo-add "$repo_add_db" "$repo_path"/*.pkg.tar.zst || error "Failed to update the local repository database."
}

view_packages() {
    echo "List of packages in the local repository ($repo_path):"
    if [ -d "$repo_path" ]; then
        ls -1 "$repo_path"/*.pkg.tar.zst 2>/dev/null | awk -F/ '{print $NF}' || echo "No packages in the repository."
    else
        echo "Local repository does not exist."
    fi
}

add_repo_to_pacman_conf() {
    echo "Adding the local repository to pacman.conf..."
    if grep -q "\[LocalUserRepo\]" /etc/pacman.conf; then
        echo "Local repository is already added to pacman.conf."
    else
        sudo bash -c "echo -e '\n[LocalUserRepo]\nSigLevel = Optional TrustAll\nServer = file://$repo_path' >> /etc/pacman.conf" || error "Failed to add the repository to pacman.conf."
        echo "Local repository successfully added to pacman.conf."
        sudo pacman -Sy
    fi
}

remove_repo_from_pacman_conf() {
    echo "Removing the local repository from pacman.conf..."
    if grep -q "\[LocalUserRepo\]" /etc/pacman.conf; then
        sudo sed -i '/\[LocalUserRepo\]/,/^$/d' /etc/pacman.conf || error "Failed to remove the repository from pacman.conf."
        echo "Local repository successfully removed from pacman.conf."
        sudo pacman -Sy
    else
        echo "Local repository not found in pacman.conf."
    fi
}

install_from_local_repo() {
    prompt "Enter the package name to install from the local repository" package_name

    if grep -q "\[LocalUserRepo\]" /etc/pacman.conf; then
        echo "Installing package '$package_name' from the local repository..."
        sudo pacman -S "LocalUserRepo/$package_name" || error "Failed to install package '$package_name'."
    else
        echo "Local repository is not added to pacman.conf."
        echo "Please add the repository through the menu before installing the package."
    fi
}

main_menu() {
    echo "Select an action:"
    echo "1) Add packages to the local repository"
    echo "2) View packages in the local repository"
    echo "3) Add the local repository to pacman.conf"
    echo "4) Remove the local repository from pacman.conf"
    echo "5) Install a package from the local repository"
    echo "6) Exit"
    read -p "Enter the option number (1-6): " action
    case "$action" in
        1)
            add_packages
            ;;
        2)
            set_default_repo_path
            view_packages
            echo
            main_menu
            ;;
        3)
            set_default_repo_path
            add_repo_to_pacman_conf
            echo
            main_menu
            ;;
        4)
            remove_repo_from_pacman_conf
            echo
            main_menu
            ;;
        5)
            install_from_local_repo
            echo
            main_menu
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            main_menu
            ;;
    esac
}

add_packages() {
    select_source source

    prompt "Enter the package names (separated by space)" package_names_input

    IFS=' ' read -r -a package_names <<< "$package_names_input"

    set_default_repo_path

    ensure_repo_path

    if [ "$source" == "repo" ]; then
        download_from_repo
    elif [ "$source" == "aur" ]; then
        download_from_aur
    fi

    update_repo_db

    echo "Packages successfully added to the local repository."
    echo
    main_menu
}

set_default_repo_path() {
    default_repo_path="$(pwd)/LocalUserRepo"
    repo_path="$default_repo_path"
}


check_dependencies

main_menu

exit 0
