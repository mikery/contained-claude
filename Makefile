.PHONY: help dev up claude down stop list worktree/%

# Default target - show help
help:
	@echo "Devcontainer + Worktree Management"
	@echo ""
	@echo "Usage:"
	@echo "  make worktree/BRANCH    Create worktree, start container, open Claude"
	@echo "  make list               List all worktrees and container status"
	@echo "  make dev                Start devcontainer"
	@echo "  make claude             Open Claude Code in container"
	@echo "  make down               Stop container"
	@echo ""
	@echo "Examples:"
	@echo "  make worktree/feature-xyz    # Full workflow in .worktrees/feature-xyz"
	@echo "  make list                     # Show all worktrees and containers"
	@echo "  make dev                      # Start container in current worktree"

# Create worktree, start container, and launch Claude
worktree/%:
	@BRANCH=$* && \
	REPO_ROOT=$$(pwd) && \
	REPO_NAME=$$(basename "$$REPO_ROOT") && \
	WORKTREE_DIR=.worktrees/$$BRANCH && \
	echo "Creating worktree: $$WORKTREE_DIR" && \
	mkdir -p .worktrees && \
	git worktree add -B $$BRANCH $$WORKTREE_DIR && \
	echo "Fixing .git file to use relative path..." && \
	GITDIR_PATH=$$($$REPO_ROOT/.devcontainer/gitdir-path.sh $$WORKTREE_DIR $$BRANCH) && \
	echo "gitdir: $$GITDIR_PATH" > $$WORKTREE_DIR/.git && \
	echo "Starting devcontainer..." && \
	export REPO_NAME=$$REPO_NAME && \
	export REPO_ROOT=$$REPO_ROOT && \
	export WORKTREE_PATH=".worktrees/$$BRANCH" && \
	devcontainer up --workspace-folder $$WORKTREE_DIR --config $$REPO_ROOT/.devcontainer/devcontainer.json && \
	echo "Launching Claude Code..." && \
	devcontainer exec --workspace-folder $$WORKTREE_DIR --config $$REPO_ROOT/.devcontainer/devcontainer.json claude

# Start devcontainer
dev up:
	@if [ -f .git ] && grep -q 'gitdir:' .git; then \
		REPO_ROOT=$$(.devcontainer/repo-root.sh) && \
		REPO_NAME=$$(basename "$$REPO_ROOT") && \
		WORKTREE_REL=$$(python3 -c "import os.path; print(os.path.relpath('$$PWD', '$$REPO_ROOT'))") && \
		export REPO_ROOT=$$REPO_ROOT && \
		export REPO_NAME=$$REPO_NAME && \
		export WORKTREE_PATH=$$WORKTREE_REL && \
		devcontainer up --workspace-folder . --config $$REPO_ROOT/.devcontainer/devcontainer.json; \
	else \
		REPO_NAME=$$(basename "$$PWD") && \
		export REPO_NAME=$$REPO_NAME && \
		export REPO_ROOT=$$PWD && \
		devcontainer up --workspace-folder .; \
	fi

# Open Claude Code in container (auto-creates if needed)
claude:
	@if [ -f .git ] && grep -q 'gitdir:' .git; then \
		REPO_ROOT=$$(.devcontainer/repo-root.sh) && \
		REPO_NAME=$$(basename "$$REPO_ROOT") && \
		BRANCH=$$(basename $$(pwd)) && \
		CONTAINER_NAME="$$REPO_NAME--$$BRANCH" && \
		if [ -z "$$(docker ps -a --filter "name=$$CONTAINER_NAME" --format '{{.Names}}' | grep -x "$$CONTAINER_NAME")" ]; then \
			echo "Container not found. Creating with 'make dev'..." && \
			$(MAKE) dev && echo ""; \
		fi && \
		WORKTREE_REL=$$(python3 -c "import os.path; print(os.path.relpath('$$PWD', '$$REPO_ROOT'))") && \
		devcontainer exec --workspace-folder "$$REPO_ROOT" --config "$$REPO_ROOT/.devcontainer/devcontainer.json" -- bash -lc "cd /repo/$$WORKTREE_REL && claude"; \
	else \
		REPO_NAME=$$(basename "$$PWD") && \
		BRANCH=$$(git branch --show-current) && \
		CONTAINER_NAME="$$REPO_NAME--$$BRANCH" && \
		if [ -z "$$(docker ps -a --filter "name=$$CONTAINER_NAME" --format '{{.Names}}' | grep -x "$$CONTAINER_NAME")" ]; then \
			echo "Container not found. Creating with 'make dev'..." && \
			$(MAKE) dev && echo ""; \
		fi && \
		devcontainer exec --workspace-folder . claude; \
	fi

# List all worktrees and their container status
list:
	@echo "Worktrees and Container Status:"
	@echo ""
	@REPO_NAME=$$(basename $$(pwd)) && \
	git worktree list --porcelain | awk -v repo="$$REPO_NAME" ' \
		BEGIN { path=""; branch=""; printf "%-30s %-10s %s\n", "BRANCH", "STATUS", "PATH" } \
		/^worktree / { path=substr($$0, 10) } \
		/^branch / { \
			branch=substr($$0, 8); \
			gsub(/^refs\/heads\//, "", branch); \
			cmd="docker ps --filter name=" repo "--" branch " --format {{.Names}} 2>/dev/null"; \
			cmd | getline container; \
			close(cmd); \
			status = (container != "") ? "✓ running" : "✗ stopped"; \
			printf "%-30s %-10s %s\n", branch, status, path \
		}'

# Stop container
down stop:
	@FOLDER=$$(basename "$$PWD") && \
	docker stop "$$FOLDER" 2>/dev/null || docker ps --filter name="$$FOLDER" --format "{{.Names}}" | xargs -r docker stop || echo "Container not running"
