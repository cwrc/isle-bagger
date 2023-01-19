# Display help by default.
.DEFAULT_GOAL := help

# Require bash to use foreach loops.
SHELL := bash

# Used to include host-platform specific docker compose files.
OS := $(shell uname -s | tr A-Z a-z)

# Output directory for generated / downloaded artifacts.
BUILDDIR ?= $(CURDIR)/custom

# For text display in the shell.
RESET=$(shell tput sgr0)
RED=$(shell tput setaf 9)
BLUE=$(shell tput setaf 6)
TARGET_MAX_CHAR_NUM=30

# Some targets will only be included if the appropriate condition is met.
DOCKER_COMPOSE_INSTALLED=$(shell docker compos version &>/dev/null && echo "true")

.phony: confirm
confirm:
	@echo -n "Are you sure you want to continue and drop your data? [y/N] " && read ans && [ $${ans:-N} = y ]

.PHONY: initialize 
.SILENT: initialize
## For a new instance, initialize the UID/GID.
initialize: confirm
	# When doing local development it is preferable to have the containers nginx
	# user have the same uid/gid as the host machine to prevent permission issues.
	mkdir -p $(BUILDDIR)/secrets
	id -u > $(BUILDDIR)/secrets/UID
	id -g > $(BUILDDIR)/secrets/GID


.PHONY: initialize_secrets
.SILENT: initialize_secrets
## For a new instance, initialize a set of secretss
initialize_secrets: confirm
	## generate JWT
	openssl genrsa -out "${BUILDDIR}/secrets/JWT_PRIVATE_KEY" 2048 &> /dev/null
	openssl rsa -pubout -in	"${BUILDDIR}/secrets/JWT_PRIVATE_KEY" -out "${BUILDDIR}/secrets/JWT_PUBLIC_KEY" &> /dev/null 
        ## random secrets	
	for secret in \
		"${BUILDDIR}/secrets/ACTIVEMQ_PASSWORD" \
		"${BUILDDIR}/secrets/ACTIVEMQ_WEB_ADMIN_PASSWORD" \
		"${BUILDDIR}/secrets/ALPACA_ACTIVEMQ_PASSWORD" \
		"${BUILDDIR}/secrets/ALPACA_KARAF_ADMIN_PASSWORD" \
		"${BUILDDIR}/secrets/DB_ROOT_PASSWORD" \
		"${BUILDDIR}/secrets/DRUPAL_DEFAULT_ACCOUNT_PASSWORD" \
		"${BUILDDIR}/secrets/DRUPAL_DEFAULT_DB_PASSWORD" \
		"${BUILDDIR}/secrets/MATOMO_DB_PASSWORD" \
		"${BUILDDIR}/secrets/MATOMO_USER_PASS_NON_HASH" \
		"${BUILDDIR}/secrets/TOMCAT_ADMIN_PASSWORD" \
	; \
	do \
		echo "$$secret"; \
		tr -dc "A-Za-z0-9-_" </dev/urandom | head -c "16" > $${secret}; \
	done;
	for secret in \
		"${BUILDDIR}/secrets/DRUPAL_DEFAULT_SALT" \
		"${BUILDDIR}/secrets/JWT_ADMIN_TOKEN" \
	; \
	do \
		echo "$$secret"; \
		tr -dc "A-Za-z0-9-_'" </dev/urandom | head -c "64" > $${secret}; \
	done;
	## Todo: Matomo hash
	# doesn't work echo "create MATOMO_USER_PASS from MATOMO_USER_PASS_NON_HASH  - python3 -c 'import bcrypt; print(bcrypt.hashpw(pw.encode(\"utf-8\"), bcrypt.gensalt()))' > \"${BUILDDIR}/secrets/MATOMO_USER_PASS\" "
	echo "\n\n=========== Todo ==========="
	echo "create MATOMO_USER_PASS from MATOMO_USER_PASS_NON_HASH - https://matomo.org/faq/how-to/faq_191/ "
	echo "\n\n=========== end ==========="



.PHONY: help
.SILENT: help
## Displays this help message.
help: 
	@echo ''
	@echo 'Usage:'
	@echo '  ${RED}make${RESET} ${BLUE}<target>${RESET}'
	@echo ''
	@echo 'General:'
	@awk '/^[a-zA-Z\-_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = $$1; sub(/:$$/, "", helpCommand); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			if (helpCommand !~ "^compose-" && helpCommand !~ "^helm-" && helpCommand !~ "^helmfile-" && helpCommand !~ "^kubectl-") { \
				printf "  ${RED}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${BLUE}%s${RESET}\n", helpCommand, helpMessage; \
			} \
		} \
	} \
	{lastLine = $$0}' $(MAKEFILE_LIST)
	@echo ''

