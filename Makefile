.DEFAULT_GOAL := help

.PHONY: help build run test clean

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

build: ## Assemble PBasic binary
	@.make/build.sh

run: build ## Run PBasic in Mojave simulator
	@mojave --machine m6502 --load-bin bin/pbasic.bin@0000

test: build ## Run verification and test suite
	@.make/test.sh

clean: ## Remove build artifacts
	@rm -rf bin/pbasic.bin bin/*.lst /tmp/pbasic_*.s /tmp/pbasic_*.o
