# https://www.stevenrombauts.be/2018/12/test-smtp-with-telnet-or-openssl/
SHELL := /bin/bash
PACKAGES := dovecot-core dovecot-imapd dovecot-pop3d dovecot-sieve
SERVER ?= smarthost
NETRC := $(HOME)/.netrc
USERFIELDS := $$1 " " $$2 " " $$3
PASSFIELDS := $$1 " " $$2 " " $$5
USERPATTERN := machine $(SERVER) login
PASSPATTERN := machine $(SERVER) password
# can't use USER, the shell has already set that
MUSER ?= $(shell awk '$(USERFIELDS) == "$(USERPATTERN)" {print $$4}' $(NETRC))
MPASS ?= $(shell awk '$(PASSFIELDS) == "$(PASSPATTERN)" {print $$6}' $(NETRC))
PLAINAUTH := $(shell echo -ne "\0$(MUSER)\0$(MPASS)" | base64)
TLSINIT := EHLO me\r\n
TLSAUTH := AUTH PLAIN $(PLAINAUTH)\r\n
S_CLIENT := openssl s_client -ign_eof
TLSCONNECT := $(S_CLIENT) -starttls smtp -connect $(SERVER):587
SSLCONNECT := $(S_CLIENT) -connect $(SERVER):465
ifneq ($(SHOWENV),)
 export nothing
else
 export
endif
tlstest:
	echo -ne '$(TLSINIT)$(TLSAUTH)' | $(TLSCONNECT)
auth:
	echo username: $(MUSER) password: $(MPASS) auth: $(PLAINAUTH)
env:
ifneq ($(SHOWENV),)
	$@
else
	$(MAKE) SHOWENV=1 $@
endif
install:
	sudo apt update
	sudo apt install $(PACKAGES)
