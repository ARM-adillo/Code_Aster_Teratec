SHELL = /bin/bash

default: help

# --- build of Singularity images
# usage:
#	- set proxy environment if necessary

export TMPDIR ?= /local00/tmp

%.sif: %.def
	cd .. && sudo -E singularity build --tmpdir $(TMPDIR) --force $@ container/$<
	cd .. && sha1sum $@ > $@.sha1

%.sif.sha1: %.sif
	sha1sum $< > $@
