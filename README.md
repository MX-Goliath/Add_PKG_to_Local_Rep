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
    chmod +x Add_PKG.sh
    ```

3. **Run the script:**

    ```bash
    ./Add_PKG.sh
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


