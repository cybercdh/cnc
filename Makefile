.PHONY: install uninstall test clean help

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
NAME ?= cnc

help:
	@echo "cnc - Cat No Comments"
	@echo ""
	@echo "Available targets:"
	@echo "  make install     - Install cnc to $(BINDIR)"
	@echo "  make uninstall   - Remove cnc from $(BINDIR)"
	@echo "  make test        - Run basic tests"
	@echo "  make clean       - Clean build artifacts"
	@echo ""
	@echo "Installation options:"
	@echo "  make install PREFIX=/usr/local  (default, requires sudo)"
	@echo "  make install PREFIX=~/.local    (user install, no sudo)"

install:
	@echo "Installing cnc to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 cnc $(BINDIR)/$(NAME)
	@echo "✓ cnc installed successfully to $(BINDIR)/$(NAME)"
	@echo ""
	@echo "Try it out:"
	@echo "  $(BINDIR)/$(NAME) --help"

uninstall:
	@echo "Removing cnc from $(BINDIR)..."
	@rm -f $(BINDIR)/$(NAME)
	@echo "✓ cnc uninstalled successfully"

test:
	@echo "Running basic tests..."
	@bash -n cnc && echo "✓ Syntax check passed"
	@./cnc --version > /dev/null && echo "✓ Version check passed"
	@./cnc --help > /dev/null && echo "✓ Help check passed"
	@if [ -x tests/run.sh ]; then \
		echo "✓ Running test suite..."; \
		bash tests/run.sh; \
	fi
	@echo "All tests passed!"

clean:
	@echo "Nothing to clean (no build artifacts)"
