# Dotfiles repo
Repo stores my config files that I want to be able to easily use in any Linux environment.

Use stow to create the symlinks in the appropriate config directory.

Notes:
* To symlink configuration files stored in the `config` folder of the repo to ~/.config: `stow config -t ~/.config`
* To start to track a folder or file that already exists in the target directory:
    * Move it to the repo and run the `stow` command again
    * This is needed because if a file / folder exitst in the target directory, it won't be symlinked
* Same applies for newly added files: run the `stow` command again
