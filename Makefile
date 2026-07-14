MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

TOP = chip_top

PROJECT_DIR ?= ../expresso
$(info project director used $(PROJECT_DIR)) 

PROJECT_GDS := $(PROJECT_DIR)/final/gds/$(TOP).gds
PROJECT_BUILD_LOGS := $(PROJECT_DIR)/final/metrics.csv
PROJECT_UPLOAD := $(PROJECT_DIR)/precheck
PROJECT_OAS_MD5 := $(PROJECT_UPLOAD)/$(TOP).oas.md5

MANUFACTURING_ID := G802CAFE
THREADS ?= 8

RUN_TAG = $(shell ls librelane/runs/ | tail -n 1)
SLOT ?= 0p5x0p5

PDK_ROOT ?= $(MAKEFILE_DIR)/gf180mcu
PDK ?= gf180mcuD
PDK_COMMIT ?= d658698bd8bcf4e05fc7b5991a701247ba0d744c

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

precheck: clone-pdk $(PROJECT_GDS)
	python3 precheck.py --slot ${SLOT} --cob --input $(PROJECT_GDS) --id $(MANUFACTURING_ID) --workers max --threads $(THREADS) --output ${TOP}.oas
.PHONY: precheck

precheck-no-cob: clone-pdk $(PROJECT_GDS)
	python3 precheck.py --slot ${SLOT} --input $(PROJECT_GDS) --id $(MANUFACTURING_ID) --workers max --threads $(THREADS) --output ${TOP}.oas
.PHONY: precheck-no-cob

upload: $(TOP).oas
	md5sum $< | awk '{print $$1}' > $(PROJECT_OAS_MD5)
	gzip -kf $<
	cp $<.gz $(PROJECT_UPLOAD)/.
	cp $(PROJECT_BUILD_LOGS) $(PROJECT_UPLOAD)/.
	# get latest render ( even if it is ugly without colors ) 
	latest_run=$$(ls runs/. | sort | tail -n 1) && \
	render_dir=$$(ls runs/$$latest_run/. | grep "render") && \
	cp ./runs/$$latest_run/$$render_dir/*.png $(PROJECT_UPLOAD)/.

