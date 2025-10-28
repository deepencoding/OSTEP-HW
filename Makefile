# Makefile — CH and Q interface
SHELL := /bin/bash
CC := gcc
CFLAGS := -std=gnu11 -Wall -Wextra -g -O2
SANITIZE := -fsanitize=address,undefined
BIN_DIR := bin
INCLUDE_DIR := include

# discover q*.c files one level down: chapter/qX.c -> records "chapter/qX"
SRCS_BASE := $(shell find . -mindepth 2 -maxdepth 2 -type f -name 'q*.c' -printf '%P\n' | sed 's/\.c$$//' | sort)
PROGS := $(patsubst %,$(BIN_DIR)/%,$(SRCS_BASE))

.PHONY: all build clean single run sanitized valgrind test list help

all: build

# build all discovered binaries
build: $(PROGS)

# pattern rule: build bin/chapter/qX from chapter/qX.c
$(BIN_DIR)/%: %.c
	@echo "Building $@ from $<"
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< -I$(INCLUDE_DIR) -o $@

# Build a single file by chapter number and question number.
# Usage: make single CH=5 Q=1
single:
	@if [ -z "$(CH)" ] || [ -z "$(Q)" ]; then \
	  echo "Usage: make single CH=<chapter-number> Q=<question-number>"; exit 1; \
	fi
	@CH_DIR=$$(find . -maxdepth 1 -type d \( -name "$(CH)_*" -o -name "0$(CH)_*" -o -name "$(CH)*" \) -printf '%P\n' | head -n1); \
	if [ -z "$$CH_DIR" ]; then echo "Chapter directory for CH=$(CH) not found"; exit 1; fi; \
	SRC="$${CH_DIR}/q$(Q).c"; \
	if [ ! -f "$$SRC" ]; then echo "Source $$SRC not found"; exit 1; fi; \
	mkdir -p $(BIN_DIR)/$$CH_DIR; \
	$(CC) $(CFLAGS) "$$SRC" -I$(INCLUDE_DIR) -o $(BIN_DIR)/$$CH_DIR/q$(Q); \
	echo "Built $(BIN_DIR)/$$CH_DIR/q$(Q)"

# Run a single built exercise. Builds if needed.
# Usage: make run CH=5 Q=1
run:
	@if [ -z "$(CH)" ] || [ -z "$(Q)" ]; then \
	  echo "Usage: make run CH=<chapter-number> Q=<question-number>"; exit 1; \
	fi
	@CH_DIR=$$(find . -maxdepth 1 -type d \( -name "$(CH)_*" -o -name "0$(CH)_*" -o -name "$(CH)*" \) -printf '%P\n' | head -n1); \
	if [ -z "$$CH_DIR" ]; then echo "Chapter directory for Chapter $(CH) not found"; exit 1; fi; \
	BIN=$(BIN_DIR)/$$CH_DIR/q$(Q); \
	if [ ! -x "$$BIN" ]; then $(MAKE) single CH=$(CH) Q=$(Q) || exit 1; fi; \
	echo "Running $$BIN"; \
	$$BIN

# build with sanitizers
sanitized: CFLAGS += $(SANITIZE) -O1
sanitized: clean build

valgrind:
	@if [ -z "$(CH)" ] || [ -z "$(Q)" ]; then \
	  echo "Usage: make valgrind CH=<chapter-number> Q=<question-number>"; exit 1; \
	fi
	@CH_DIR=$$(find . -maxdepth 1 -type d \( -name "$(CH)_*" -o -name "0$(CH)_*" -o -name "$(CH)*" \) -printf '%P\n' | head -n1); \
	if [ -z "$$CH_DIR" ]; then echo "Chapter directory for CH=$(CH) not found"; exit 1; fi; \
	BIN=$(BIN_DIR)/$$CH_DIR/q$(Q); \
	if [ ! -x "$$BIN" ]; then $(MAKE) single CH=$(CH) Q=$(Q) || exit 1; fi; \
	valgrind --leak-check=full $$BIN

test:
	@if [ -z "$(CH)" ] || [ -z "$(Q)" ]; then \
		echo "Usage: make test CH=<chapter> Q=<question>"; exit 1;
	fi
	@CH_DIR=$$(find . -maxdepth 1 -type d \( -name "$(CH)_*" -o -name "0$(CH)_*" -o -name "$(CH)*" \) -printf '%P\n' | head -n1); \
	BIN=$(BIN_DIR)/$$CH_DIR/q$(Q); \
	if [ ! -x "$$BIN" ]; then $(MAKE) single CH=$(CH) Q=$(Q); fi; \
	IN="tests/$$CH_DIR/q$(Q)_input.txt"; \
	OUT_EXPECTED="tests/$$CH_DIR/q$(Q)_expected.txt"; \
	if [ ! -f "$$IN" ]; then echo "Input file $$IN not found"; exit 1; fi; \
	if [ ! -f "$$OUT_EXPECTED" ]; then echo "Expected output $$OUT_EXPECTED not found"; exit 1; fi; \
	ACTUAL=$$(mktemp); \
	./$$BIN < $$IN > $$ACTUAL; \
	if diff -q $$ACTUAL $$OUT_EXPECTED > /dev/null; then \
	  echo "Test passed for $$CH_DIR/q$(Q)"; \
	else \
	  echo "Test FAILED for $$CH_DIR/q$(Q):"; \
	  diff -u $$OUT_EXPECTED $$ACTUAL; \
	  exit 1; \
	fi; \
	rm -f $$ACTUAL

list:
	@echo "Discovered sources (chapter / question):"
	@printf '%s\n' $(SRCS_BASE) | sed 's|/| - |g' || true

clean:
	rm -rf $(BIN_DIR)

help:
	@echo "Build:"
	@echo "  make                    -> builds all exercises"
	@echo "  make single CH=5 Q=1    -> build specific exercise"
	@echo ""
	@echo "Run a single exercise:"
	@echo "  make run CH=5 Q=1"
	@echo ""
	@echo "Dev:"
	@echo "  make sanitized          -> build with sanitizers"
	@echo "  make valgrind CH=5 Q=1  -> run under valgrind"
	@echo "  make test CH=5 Q=1      -> tests the actual output against expected output for a given input"
	@echo ""
	@echo "Notes:"
	@echo "  - Chapter dirs should start with the chapter number (e.g. '05_interlude...' or '5_interlude...')."
	@echo "  - Question files must be named q<NUM>.c (e.g. q1.c, q2.c)."
