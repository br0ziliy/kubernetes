ENV_DIR = .venv
CURRENT_DIR := $(shell pwd)
INTERPRETER = $(CURRENT_DIR)/$(ENV_DIR)/bin/
PATH := ${PATH}:$(INTERPRETER)

help:
	@echo "Run make <target> with:"
	@echo " > env           : create virtualenv on folder $(ENV_DIR)"
	@echo " > deps          : install dependentcies"
	@echo " > cleanenv      : delete virtualenv"
	@echo " > start         : run vagrant up"
	@echo " > provisioning  : start ansible provisioning"
	@echo " > kill          : run vagrant destroy"

debug:
	@echo " > ansible location is     : $(INTERPRETER)"
	@echo " > environment variable is : $(PATH)"
	vagrant status

env:
	virtualenv $(ENV_DIR) && \
	. $(ENV_DIR)/bin/activate && \
	make deps

deps:
	$(ENV_DIR)/bin/pip install -r requirements.txt

cleanenv:
	rm -fr $(ENV_DIR)

start:
	vagrant up

provisioning:
	vagrant provision

kill:
	vagrant destroy -f

rebuild:
	vagrant destroy -f
	vagrant up
