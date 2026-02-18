# Test DevContainer

This directory contains a test configuration for the home-manager devcontainer feature.

The feature files are copied into `.devcontainer/home-manager/` to comply with devcontainer CLI requirements that features must be within the `.devcontainer/` directory.

The test validates that:
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

## Note

The feature files in `.devcontainer/home-manager/` are copies from `src/home-manager/`. 
When updating the main feature, remember to update these test copies as well.
