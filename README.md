# Add_PKG_to_Local_Rep
A script to add packages from official archlinux repositories to local repositories. The main purpose is to save current versions of packages for "rolling back" versions or for system recovery. It can also be used for local installations of archlinux without the need to connect to the internet. 

This script facilitates the process of downloading a package from the Arch Linux repositories and adding it to a local repository. It performs the following steps:

1. Prompts the user for the package name and the local repository path.
2. Verifies the existence of the specified local repository path.
3. Downloads the specified package.
4. Moves the downloaded package to the local repository.
5. Updates the local repository database.

## Prerequisites

- Arch Linux or an Arch-based distribution.
- `pacman` package manager.
- `repo-add` utility.

## Usage

1. **Clone the repository:**

    ```bash
    git clone https://github.com/MX-Goliath/Add_PKG_to_Local_Rep.git
    cd Add_PKG_to_Local_Rep
    ```

2. **Make the script executable:**

    ```bash
    chmod +x local-repo.sh
    ```

3. **Run the script:**

    ```bash
    ./local-repo.sh
    ```

4. **Follow the prompts:**
    - Enter the name of the package you wish to download.
    - Enter the path to your local repository.

## Example

```bash
./local-repo.sh
Enter package name: vim
Enter local repository path: /path/to/local/repo
```

## Script Details

```bash
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
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributions

Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## Issues

If you encounter any issues, please open an issue on GitHub.
