# https://www.stevenrombauts.be/2018/12/test-smtp-with-telnet-or-openssl/
SHELL := /bin/bash
SERVER ?= smarthost
NETRC := $(HOME)/.netrc
USERFIELDS := $$1 " " $$2 " " $$3
PASSFIELDS := $$1 " " $$2 " " $$5
USERPATTERN := machine $(SERVER) login
PASSPATTERN := machine $(SERVER) password
USER ?= $(shell awk '$(USERFIELDS) == "$(USERPATTERN)" {print $$4}' $(NETRC))
PASS ?= $(shell awk '$(PASSFIELDS) == "$(PASSPATTERN)" {print $$6}' $(NETRC))
PLAINAUTH := $(shell echo -ne "\0$(USER)\0$(PASS)" | base64)
ifneq ($(SHOWENV),)
 export nothing
else
 export
endif
test587: env
	openssl s_client -starttls smtp -connect $(SERVER):587
test465:
	openssl s_client -connect $(SERVER):465
env:
ifneq ($(SHOWENV),)
	$@
else
	$(MAKE) SHOWENV=1 $@
endif
