.PHONY: ensure-devcontainer test

ensure-devcontainer:
	@command -v devcontainer >/dev/null 2>&1 || npm install -g @devcontainers/cli

test: ensure-devcontainer
	devcontainer features test --features user-sync
