BASE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

include $(BASE)/VERSION

PRODUCTS ?= \
	hdf5 med metis parmetis mfront mgis homard scotch scalapack \
	mumps petsc miss3d medcoupling ecrevisse mpi4py gmsh grace asrun

.NOTPARALLEL:

default: products env_file

products: _check $(PRODUCTS) version_file

NUMVERS = $(shell echo ${VERSION})

export DEST ?= $(ROOT)/$(NUMVERS)/$(ARCH)
export BUILD ?= $(BASE)/.build-$(ARCH)
export CACHE ?= /tmp/.cache_$(shell whoami)
export ARCHIVESDIR = $(BASE)/archives

# for each product:
#          hdf5: _check $(DEST)/.installed/hdf5
$(PRODUCTS): % : _check $(DEST)/.installed/%

# products with dependencies, using files to rebuild if a dependency is newer
$(DEST)/.installed/med: \
	$(DEST)/.installed/hdf5
$(DEST)/.installed/parmetis: \
	$(DEST)/.installed/metis
$(DEST)/.installed/mumps: \
	$(DEST)/.installed/scotch \
	$(DEST)/.installed/metis \
	$(DEST)/.installed/parmetis \
	$(DEST)/.installed/scalapack
$(DEST)/.installed/petsc: \
	$(DEST)/.installed/mumps \
	$(DEST)/.installed/scotch \
	$(DEST)/.installed/parmetis \
	$(DEST)/.installed/metis \
	$(DEST)/.installed/scalapack
$(DEST)/.installed/medcoupling: \
	$(DEST)/.installed/hdf5 \
	$(DEST)/.installed/med \
	$(DEST)/.installed/metis \
	$(DEST)/.installed/parmetis \
	$(DEST)/.installed/scotch


# call <product>.sh > .../<product>.log
# 	<product>.passed is used to pass exit code that is reset by 'tee'
$(DEST)/.installed/%:
	export CURRENT_PRODUCT=$$(basename $@) ; \
	printf "\n***************** Installing $${CURRENT_PRODUCT} *******************\n\n"; \
	(\
		rm -f $(BUILD)/$${CURRENT_PRODUCT}.passed ; \
		$(BASE)/src/$${CURRENT_PRODUCT}.sh && \
		echo passed > $(BUILD)/$${CURRENT_PRODUCT}.passed \
	) 2>&1 | tee $(BUILD)/$${CURRENT_PRODUCT}.log ; \
	gzip -c $(BUILD)/$${CURRENT_PRODUCT}.log > $(DEST)/.installed/$${CURRENT_PRODUCT}.log.gz ; \
	test -e $(BUILD)/$${CURRENT_PRODUCT}.passed


version_file: _check $(DEST)/VERSION

check: _check $(DEST)/.installed/env_check

env: _check $(DEST)/.installed/env_file

setup_venv: _check $(DEST)/.installed/setup_venv

env_file: products env

$(DEST)/VERSION: $(BASE)/VERSION
	$(BASE)/src/version.sh

archive: $(ROOT)/$(NUMVERS).tar.gz

$(ROOT)/$(NUMVERS).tar.gz: $(PRODUCTS)
	cd $(ROOT) ; tar czf $@ $(NUMVERS)

dist: download
	@$(BASE)/utils/dist.sh

distclean:
	@echo "removing build directory: $(BUILD)*..."
	@rm -rf $(BUILD)*
	@if [ -d .git ]; then \
		echo "removing archives directory: $(BASE)/archives..." ; \
		rm -rf $(BASE)/archives/* ; \
	fi
	@echo "removing vitual environments: $(BASE)/.venv_*..."
	@rm -rf $(BASE)/.venv_*
	@echo "removing cache directory: $(CACHE)..."
	@rm -rf $(CACHE)

download: _check_download
	@$(BASE)/utils/download_only.sh

# shortcut for local builds
%.sif: container/%.def
	$(MAKE) -C container $@

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
	$(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, $(error $1 not defined$(if $2, ($2))))

_check: _check_dirs _check_download

_check_dirs:
	$(call check_defined, ROOT, root installation directory)
	$(call check_defined, ARCH, compiler-math-mpi definition)
	$(call check_defined, RESTRICTED, 0: open-source or 1: private)
	@mkdir -p $(DEST)/.installed $(BUILD)

_check_download:
	@if [ ! -d $(BASE)/archives ]; then \
		if [ -z "$${GITLAB_PREREQ_TOKEN}" ]; then \
			echo "GITLAB_PREREQ_TOKEN not defined." ; \
			exit 1 ; \
		fi ; \
	fi
	@mkdir -p $(CACHE)

.PHONY: archive distclean dist download _check _check_dirs _check_download $(PRODUCTS)
