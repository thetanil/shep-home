# Test DevContainer

This directory contains a test configuration for the home-manager devcontainer feature.

It is used by the GitHub Actions workflow to verify that:
1. The feature installs Nix correctly
2. home-manager is available
3. The /cache directory is mounted
4. Nix configuration is properly set up

## Manual Testing

You can also test this locally by:

```bash
cd test-devcontainer
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . nix --version
devcontainer exec --workspace-folder . home-manager --version
```
