# https://www.stevenrombauts.be/2018/12/test-smtp-with-telnet-or-openssl/
SHELL := /bin/bash
DOVE_PACKAGES := dovecot-core dovecot-imapd dovecot-pop3d dovecot-sieve
EXIM_PACKAGES := exim4-base exim4-config exim4-daemon-heavy
PACKAGES := $(DOVE_PACKAGES) $(EXIM_PACKAGES)
SERVER ?= smarthost
NETRC := $(wildcard $(HOME)/.netrc)
ifneq ($(NETRC),)
USERFIELDS := $$1 " " $$2 " " $$3
PASSFIELDS := $$1 " " $$2 " " $$5
ACCTFIELDS := $$1 " " $$2 " " $$7
USERPATTERN := machine $(SERVER) login
PASSPATTERN := machine $(SERVER) password
ACCTPATTERN := machine $(SERVER) account
# can't use USER, the shell has already set that
MUSER ?= $(shell awk '$(USERFIELDS) == "$(USERPATTERN)" {print $$4}' $(NETRC))
MPASS ?= $(shell awk '$(PASSFIELDS) == "$(PASSPATTERN)" {print $$6}' $(NETRC))
DOMAIN ?= $(shell awk '$(ACCTFIELDS) == "$(ACCTPATTERN)" {print $$8}' $(NETRC))
PLAINAUTH := $(shell echo -ne "\0$(MUSER)\0$(MPASS)" | base64)
LUSER := $(shell echo -ne "$(MUSER)" | base64)
LPASS := $(shell echo -ne "$(MPASS)" | base64)
TLSINIT := EHLO me\r\n
TLSAUTH := AUTH PLAIN $(PLAINAUTH)\r\n
SSLINIT := EHLO me\r\n
SSLAUTH := AUTH LOGIN\r\n$(LUSER)\r\n$(LPASS)\r\n
S_CLIENT := openssl s_client -ign_eof
TESTMAIL := MAIL FROM: $(USER)@$(DOMAIN)\r\n
TESTMAIL := $(TESTMAIL)RCPT TO: $(USER)@$(DOMAIN)\r\n
TESTMAIL := $(TESTMAIL)DATA\r\n
TESTMAIL := $(TESTMAIL)From: $(USER)@$(DOMAIN)\r\n
TESTMAIL := $(TESTMAIL)To: $(USER)@$(DOMAIN)\r\n
TESTMAIL := $(TESTMAIL)Subject: test message\r\n
TESTMAIL := $(TESTMAIL)\r\n
TESTMAIL := $(TESTMAIL)This is a test. It is only a test.\r\n
TESTMAIL := $(TESTMAIL).\r\n
ENTRY := $(word 1, $(MUSER))
endif
TLSCONNECT := $(S_CLIENT) -starttls smtp -connect $(SERVER):587
SSLCONNECT := $(S_CLIENT) -connect $(SERVER):465
QUIT := QUIT\r\n
ifneq ($(SHOWENV),)
 export nothing
else
 export
endif
tlstest: $(HOME)/.netrc @$(ENTRY)@
	echo -ne '$(TLSINIT)$(TLSAUTH)$(TESTMAIL)$(QUIT)' | $(TLSCONNECT)
ssltest:
	#echo -ne '$(SSLINIT)$(SSLAUTH)$(TESTMAIL)$(QUIT)' | $(SSLCONNECT)
	echo -ne '$(SSLINIT)$(SSLAUTH)' | $(TLSCONNECT)
auth:
	echo username: $(MUSER) password: $(MPASS) auth: $(PLAINAUTH)
testmail:
	@echo -ne '$(TESTMAIL)'
env:
ifneq ($(SHOWENV),)
	$@
else
	$(MAKE) SHOWENV=1 $@
endif
$(HOME)/.netrc:
	@echo You need to create a file named .netrc in your home directory.
	@echo It needs at least one line in it according to this pattern:
	@echo machine smarthost login myname password mypwd account example.com
	false
@$(ENTRY)@:
	if [ "$@" = "@@" ]; then \
	 echo 'You have no entry for "smarthost" in your .netrc file' >&2; \
	 false; \
	fi
install:
	sudo apt update
	sudo apt install $(PACKAGES)
