# shep-home

A devcontainer feature repository. Features live in `src/`, tests in `test/`.

## Project layout

```
src/user-sync/
  devcontainer-feature.json   — feature metadata and options
  install.sh                  — runs at image BUILD time (not container startup)

test/user-sync/
  test.sh                     — default test, runs against ubuntu:focal
  host-user.sh                — scenario test script
  scenarios.json              — scenario definitions

Makefile
```

## How the user-sync feature works

The feature creates a user at UID 1000 inside the container image so file
permissions on bind mounts match the host user.

**The username is not passed as a build arg.** Instead, the caller sets
`remoteUser` in their `devcontainer.json` using `${localEnv:USER}`, which the
devcontainer CLI resolves to the host username and exposes as `_REMOTE_USER`
during feature installation. The feature's `install.sh` reads `_REMOTE_USER`
automatically (the "automatic" default for the `username` option).

Minimal consumer `devcontainer.json`:

```json
{
  "image": "debian:trixie-slim",
  "features": {
    "ghcr.io/your-org/user-sync:1": {}
  },
  "remoteUser": "${localEnv:USER}",
  "updateContainerUserID": true
}
```

No username option needed. `${localEnv:USER}` on the host becomes the username
in the container.

### What install.sh actually does (and where)

`install.sh` runs inside `docker buildx build` — every command executes inside
the throwaway image layer being constructed. **The host system is never
touched.** Specifically:

1. Removes all regular users from the image (UID ≥ 1000, except `nobody`).
   This prevents UID conflicts: `updateContainerUserID` can only remap one user,
   and if another user already holds the target UID the remap silently fails.
2. Removes any leftover group at GID 1000 for the same reason.
3. Creates the new user at UID 1000 / GID 1000 with a home directory.
4. Writes a passwordless sudoers entry.

System users (UID < 1000) are never touched — they are filtered out by the
`awk '$3 >= 1000'` condition.

### Why `updateContainerUserID: true` is required

`install.sh` hardcodes UID/GID 1000 because it runs at build time and cannot
know the host UID yet. On most single-user Linux systems the first user is
UID 1000 and nothing more is needed. But if your host UID is anything else
(common on shared or multi-user machines), `updateContainerUserID: true` tells
the devcontainer CLI to remap the in-image UID to match your actual host UID
after the build. Without it, file permissions on bind mounts will still be
wrong even though the username matches.

## Running tests

```sh
make test
```

This runs `devcontainer features test --features user-sync` with no extra
arguments. The `host-user` scenario in `test/user-sync/scenarios.json` uses
`"remoteUser": "${localEnv:USER}"`, so the devcontainer CLI automatically picks
up whoever is logged in and creates that user in the test container. No
hardcoded usernames anywhere.

Test scripts check for the UID 1000 user dynamically (`getent passwd 1000`)
rather than hardcoding a name.

## Adding a new feature

1. Create `src/<name>/devcontainer-feature.json` and `src/<name>/install.sh`
2. Create `test/<name>/test.sh` and optionally `test/<name>/scenarios.json`
3. Add a make target: `devcontainer features test --features <name>`
4. Add a GitHub Actions job to `.github/workflows/`

## Nix single-user install gotchas (shep-home)

### PATH / profile sourcing

- Immediately after the Nix installer runs, source it via `~/.nix-profile/etc/profile.d/nix.sh`.
- **After `home-manager switch` runs, it overwrites `~/.nix-profile`** to point at its own
  generation profile (e.g. `/home/user/.local/state/nix/profiles/profile`). That profile does
  NOT contain `etc/profile.d/nix.sh`. So source `nix.sh` before `home-manager switch`, never after.
- `/nix/var/nix/profiles/default` does NOT exist for single-user installs (daemon mode only).
  `/nix/var/nix/profiles/per-user/<user>/profile/etc/profile.d/nix.sh` also does not exist.
  The only reliable path is `~/.nix-profile/etc/profile.d/nix.sh` pre-switch.
- In **test scripts**, home-manager has already moved `~/.nix-profile`. Do not try to source
  `nix.sh`. Instead prepend `~/.nix-profile/bin` to PATH directly:
  `PATH=${TARGET_HOME}/.nix-profile/bin:$PATH nix --version`

### experimental-features

- Enable before running `nix run` by writing to `~/.config/nix/nix.conf` as root:
  `experimental-features = nix-command flakes`
- Create `~/.config/nix/` and `~/.config/systemd/user/` as root before the `su` block,
  then `chown -R` to the user. `mkdir` inside the `su` block will fail with permission denied.

### home-manager switch flags

- `-b backup` — avoid failing on existing files like `.bashrc`, `.profile`
- `--impure` — required so `builtins.getEnv` works in the flake
- `--flake "path#username"` — must be explicit; pure evaluation makes `builtins.getEnv "USER"`
  return an empty string, producing `homeConfigurations.""` which doesn't match anything

### Quoting inside `su -c '...'`

- The block is single-quoted. Embed single quotes with `'"'"'`.
- Outer-script variables (e.g. `${USERNAME}`) must be interpolated outside the single-quoted
  region: `'"${USERNAME}"'`.

### devcontainer test framework behaviour

- Test scripts run as `remoteUser` (UID 1000 user), not root. `su` requires a password — don't use it in tests.
- Use absolute paths (`${TARGET_HOME}`) not `~`, since HOME may differ depending on who runs the script.
- The test framework does NOT wait for entrypoint scripts — don't rely on entrypoints for anything tests need.
- BuildKit layer cache persists even after removing named images. `docker builder prune -af` forces
  a clean rebuild but clears cache for all projects.
