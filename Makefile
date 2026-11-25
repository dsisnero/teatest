PARITY_SKILL_DIR ?= $(HOME)/.agents/skills/crystal_forge/skills/cross-language-crystal-parity
PARITY_LANGUAGE ?= go
PARITY_PARSER ?= regex
PARITY_SOURCE ?= vendor/x/exp/teatest/v2
PARITY_LEDGER ?= plans/inventory/$(PARITY_LANGUAGE)_port_inventory.tsv

.PHONY: install update format lint test inventory parity-refresh sidecars clean

install:
	shards install

update:
	shards update

format: sidecars
	crystal tool format --check src spec

lint: sidecars
	ameba src spec

test: sidecars
	crystal spec

# Drift check for the curated parity ledger. Forwards to the installed
# cross-language-crystal-parity skill; see AGENTS.md -> Parity tooling.
inventory:
	PORT_PARSER=$(PARITY_PARSER) ./scripts/check_port_inventory.sh \
		"$(CURDIR)" "$(PARITY_LEDGER)" "$(PARITY_SOURCE)" "$(PARITY_LANGUAGE)"

# Intentional upstream bump only: regenerate the source/test manifests.
parity-refresh:
	PORT_PARSER=$(PARITY_PARSER) ./scripts/ensure_parity_plan.sh \
		"$(CURDIR)" "$(PARITY_SOURCE)" "$(PARITY_LANGUAGE)" "$(PARITY_PARSER)" 1

# This checkout lives on a volume where macOS writes AppleDouble `._*` files.
# They break shell/find-based tooling, so drop them before the gates run.
sidecars:
	@find . -name '._*' -not -path './.git/*' -not -path './node_modules/*' -delete

clean: sidecars
	rm -rf ./temp/*
