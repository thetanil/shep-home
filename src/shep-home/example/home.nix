{ config, pkgs, username, ... }: {
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -lah";
      gs = "git status";
    };
  };

  programs.git = {
    enable = true;
    # Users can extend via their own flake or an overlay module.
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    htop
  ];

  programs.home-manager.enable = true;
}
