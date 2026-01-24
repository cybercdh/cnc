.PHONY: install uninstall test clean help

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

CC = cc
CFLAGS = -O3 -Wall -Wextra -pedantic

cnc: cnc.c
	$(CC) $(CFLAGS) -o cnc cnc.c

help:
	@echo "cnc - Cat No Comments"
	@echo ""
	@echo "Available targets:"
	@echo "  make           - Build cnc"
	@echo "  make install   - Install cnc to $(BINDIR)"
	@echo "  make uninstall - Remove cnc from $(BINDIR)"
	@echo "  make test      - Run tests"
	@echo "  make clean     - Remove build artifacts"
	@echo ""
	@echo "Installation options:"
	@echo "  make install PREFIX=/usr/local  (default, requires sudo)"
	@echo "  make install PREFIX=~/.local    (user install, no sudo)"

install: cnc
	@echo "Installing cnc to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 cnc $(BINDIR)/cnc
	@echo "Done. Run 'cnc --help' to get started."

uninstall:
	@echo "Removing cnc from $(BINDIR)..."
	@rm -f $(BINDIR)/cnc
	@echo "Done."

test: cnc
	@echo "Running tests..."
	@./cnc --version > /dev/null && echo "Version check passed"
	@./cnc --help > /dev/null && echo "Help check passed"
	@if [ -x tests/run.sh ]; then bash tests/run.sh; fi
	@echo "All tests passed!"

clean:
	rm -f cnc
