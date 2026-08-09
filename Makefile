STOW_DIR := $(abspath $(CURDIR)/..)
STOW_TARGET := $(HOME)
STOW_PACKAGE := $(notdir $(CURDIR))

.PHONY: stow-adopt stow-adopt-dry-run iterm-setup iterm-verify

stow-adopt:
	stow --verbose --dir "$(STOW_DIR)" --target "$(STOW_TARGET)" "$(STOW_PACKAGE)" --adopt

stow-adopt-dry-run:
	stow --verbose --simulate --dir "$(STOW_DIR)" --target "$(STOW_TARGET)" "$(STOW_PACKAGE)" --adopt

iterm-setup:
	./bin/iterm-shell-integration-install
	./bin/iterm-zle-profile-sync --apply
	./bin/iterm-zle-profile-sync --verify-aps

iterm-verify:
	./bin/iterm-zle-profile-sync --verify-aps
