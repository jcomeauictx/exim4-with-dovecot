# https://www.stevenrombauts.be/2018/12/test-smtp-with-telnet-or-openssl/
SERVER ?= hetzner
test587:
	openssl s_client -starttls smtp -connect $(SERVER):587
test465:
	openssl s_client -connect $(SERVER):465
