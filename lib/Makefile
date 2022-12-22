# Make virtualenvs

.PHONY: tools

SHELL=/bin/bash

OSC_LIB_DIR=$(HOME)/src/openstack/osc-lib
OSC_DIR=$(HOME)/src/openstack/python-openstackclient

DWARF_SRC=$(HOME)/src/misc/dwarf

PKGS=pip stestr
TOOLS=bindep lxml

PY_VER=python3
VENV_CMD=$(PY_VER) -m venv

venv:
	[ -n "$(VENV_DIR)" ] || \
		( echo "+++ Usage: make venv release VENV_DIR=<path>" ; false )
	$(VENV_CMD) $(VENV_DIR)
	$(VENV_DIR)/bin/pip install -U $(PKGS)

#	$(MAKE) VENV_DIR=$@

ansible: PY_VER=python3
ansible: VENV_DIR=ansible
ansible: venv
	$@/bin/pip install "ansible<3.0" openstacksdk

osc: PY_VER=python3
osc: VENV_DIR=osc
osc: venv
	$@/bin/pip install python-openstackclient

tools:
	$(MAKE) VENV_DIR=tools
	(source tools/bin/activate; \
	  pip install -U $(TOOLS); \
	)

gitdep:
	virtualenv gitdep
	gitdep/bin/pip install pygit2==0.27 git-deps

dl: PY_VER=python3
dl: VENV_DIR=dl
dl: venv
	$@/bin/pip install -U yt-dlp
