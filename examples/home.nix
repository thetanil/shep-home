{ config, pkgs, ... }:

{
  # Home Manager configuration
  # This file defines your personal environment setup
  
  home.username = "vscode";  # Change to your username
  home.homeDirectory = "/home/vscode";  # Change to match your home directory
  home.stateVersion = "23.11";  # Don't change this after first run

  # Packages to install in your environment
  home.packages = with pkgs; [
    # CLI tools
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    
    # Development tools
    git
    vim
    tmux
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
    };
  };

  # Zsh configuration (optional)
  # programs.zsh = {
  #   enable = true;
  #   enableCompletion = true;
  #   oh-my-zsh = {
  #     enable = true;
  #     theme = "robbyrussell";
  #   };
  # };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
