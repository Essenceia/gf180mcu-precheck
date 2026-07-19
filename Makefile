MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

RUN_TAG = $(shell ls librelane/runs/ | tail -n 1)
TOP = chip_top
SLOT ?= 1x1
DOMAIN ?= 5v

PDK_ROOT ?= $(MAKEFILE_DIR)/gf180mcu
PDK ?= gf180mcuD
PDK_COMMIT ?= d658698bd8bcf4e05fc7b5991a701247ba0d744c

MANIFACTURING_ID ?= DEADBEEF 
THREADS ?= 1
INPUT ?= gf180mcu-example-layouts/${DOMAIN}/${SLOT}/${TOP}.oas  
 
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
.PHONY: help

all: clone-pdk ## Default target
.PHONY: all

$(PDK_ROOT)/$(PDK):
	ciel enable $(PDK_COMMIT) --pdk-root $(PDK_ROOT) --pdk-family $(PDK)

clone-pdk: $(PDK_ROOT)/$(PDK) ## Clone the gf180mcu PDK
.PHONY: clone-pdk

gf180mcu-example-layouts:
	git clone https://github.com/wafer-space/gf180mcu-example-layouts.git

clone-layouts: gf180mcu-example-layouts
.PHONY: clone-layouts

precheck: clone-pdk clone-layouts
	python3 precheck.py --slot ${SLOT} --cob --input ${INPUT} --id ${MANIFACTURER_ID} --workers max --threads ${THREADS} --output ${TOP}.oas
	md5sum ${INPUT} | awk '{print $$1}' > $(TOP).mds
	gzip -kf ${TOP}.oas
.PHONY: precheck

precheck-no-cob: clone-pdk clone-layouts
	python3 precheck.py --slot ${SLOT} --input ${INPUT} --id ${MANIFACTURER_ID} --workers max --threads ${THREADS} --output ${TOP}.oas
	md5sum ${INPUT} | awk '{print $$1}' > $(TOP).mds
	gzip -kf ${TOP}.oas	
.PHONY: precheck-no-cob

clean: ## Delete *.oas, *.md5 and *.gz 
	rm -f ./*.oas
	rm -f ./*.md5
	rm -f ./*.gz
.PHONY: clean
