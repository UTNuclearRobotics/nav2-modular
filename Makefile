PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin
CONFIG_DIR := $(PREFIX)/share/nav2-modular
CONFIG_FILE := $(CONFIG_DIR)/config
SCRIPT := nav2

.PHONY: install uninstall update help

install:
	@echo "Installing $(SCRIPT) CLI..."
	@mkdir -p $(BINDIR)
	@mkdir -p $(CONFIG_DIR)
	@echo "DOCKER_DIR=$(CURDIR)/Docker" > "$(CONFIG_FILE)"
	@install -m 755 scripts/$(SCRIPT) $(BINDIR)/$(SCRIPT)
	@echo ""
	@echo "Installation complete!"
	@echo "Docker directory recorded as: $(CURDIR)"
	@echo ""
	@echo "Run '$(SCRIPT) help' for usage"
	@echo "   $(SCRIPT) build -v    # rebuild image"
	@echo "   $(SCRIPT) start       # start container"
	@echo "   $(SCRIPT) shell       # jump in"
	@echo ""

update: uninstall install
	@echo "Update complete!"

uninstall:
	@echo "Removing $(SCRIPT) CLI..."
	@rm -f $(BINDIR)/$(SCRIPT)
	@rm -rf $(CONFIG_DIR)
	@echo "Uninstalled."

help:
	@echo "Makefile targets:"
	@echo "  make install    Install CLI"
	@echo "  make uninstall  Remove CLI"
	@echo "  make update     Reinstall CLI"
	@echo "After install, run '$(SCRIPT) help' for CLI commands."