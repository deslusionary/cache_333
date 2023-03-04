############
# Filename: Makefile
# Author: Christopher Tinker
# Date: 2022/02/28
# 
# Generic Makefile
######## ####

SRC_DIR = ./src/rtl
CONSTRAINTS_DIR = ./src/constraints
INCLUDE_DIR = ./include

LINTER := verilator
LINT_OPTIONS += --lint-only -sv -Wall -I$(INCLUDE_DIR)

SRC_FILES := $(wildcard $(SRC_DIR)/*.sv)
INCLUDE_FILES := $(wildcard $(INCLUDE_DIR)/*.svh)
TOP_MODULE := dcache

# Filter out a file we don't want linted
SRC_FILES := $(filter-out '', $(SRC_FILES))

# .PHONY: formal
# formal:
# 	sby test.sby -f -d ./sim/formal/output

# .PHONY: lint
lint: 
	$(LINTER) $(LINT_OPTIONS) $(SRC_FILES)

