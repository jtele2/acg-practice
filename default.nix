{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "ubuntu-setup";

  buildInputs = with pkgs; [
    awscli2
    fzf
    git
    jq
    tlrc
    trash-cli
    unzip
    uv
    zsh
  ];

  shellHook = ''
    # echo "=================SETTING UP DOTFILES================="
    # if [ ! -d "$HOME/configs" ]; then
    #     git clone https://github.com/jtele2/configs.git $HOME/configs
    # else
    #     echo "configs dir already exists"
    # fi
    # ln -sf $HOME/configs/.vimrc $HOME/.vimrc
    # ln -sf $HOME/configs/.zshrc $HOME/.zshrc
    # ln -sf $HOME/configs/functions.zsh $HOME/.oh-my-zsh/custom/functions.zsh
    # ln -sf $HOME/configs/aliases.zsh $HOME/.oh-my-zsh/custom/aliases.zsh
    # cp -asf $HOME/configs/completions $HOME/.zsh

    # echo "=================SETTING UP ACG PRACTICE REPO================="
    # if [ ! -d "$HOME/acg" ]; then
    #     git clone https://github.com/jtele2/acg-practice.git $HOME/acg
    # else
    #     echo "acg dir already exists"
    # fi

    echo "=================SETTING UP ZSH================="
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "oh-my-zsh is already installed"
    fi

    # Set the default shell to zsh
    export SHELL=$(which zsh)

    # Start a Login shell
    exec zsh -l


    echo "Environment setup complete!"
  '';
}