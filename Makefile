.PHONY: install uninstall check help

help:
	@echo "targets:"
	@echo "  install    install the hook and wire it into ~/.zshrc"
	@echo "  uninstall  remove the hook and unwire ~/.zshrc"
	@echo "  check      lint the shell scripts (zsh -n, shellcheck if available)"

install:
	sh ./install.sh

uninstall:
	sh ./uninstall.sh

check:
	zsh -n zmx-ssh-login.zsh && echo "zsh -n: zmx-ssh-login.zsh OK"
	sh -n install.sh && echo "sh -n: install.sh OK"
	sh -n uninstall.sh && echo "sh -n: uninstall.sh OK"
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck --shell=sh install.sh uninstall.sh; \
		echo "shellcheck: OK"; \
	else \
		echo "shellcheck not installed; skipped"; \
	fi
