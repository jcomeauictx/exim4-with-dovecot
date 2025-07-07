# exim4-with-dovecot

Modify the dovecot configuration as so:

```
root@smarthost /etc # diff -r dovecot.orig/ dovecot/
diff -r dovecot.orig/conf.d/10-master.conf dovecot/conf.d/10-master.conf
88a89,91
> # doc.dovecot.org/2.3/configuration_manual/howto/exim_and_dovecot_sasl/
> auth_mechanisms = plain login
> 
115a119,125
> 
>   # doc.dovecot.org/2.3/configuration_manual/howto/exim_and_dovecot_sasl/
>   # BUT also see /etc/exim4/exim4.conf.template for corrections
>   unix_listener /var/spool/exim4/dovecot.auth-client {
>     mode = 0660
>     group = Debian-exim
>   }
diff -r dovecot.orig/conf.d/10-ssl.conf dovecot/conf.d/10-ssl.conf
6c6
< ssl = yes
---
> ssl = required
18c18,19
< ssl_server_cert_file = /etc/dovecot/private/dovecot.pem
---
> #ssl_server_cert_file = /etc/dovecot/private/dovecot.pem
> ssl_server_cert_file = /etc/letsencrypt/live/certbot_cert/fullchain.pem
20c21,22
< ssl_server_key_file = /etc/dovecot/private/dovecot.key
---
> #ssl_server_key_file = /etc/dovecot/private/dovecot.key
> ssl_server_key_file = /etc/letsencrypt/live/certbot_cert/privkey.pem
```

Then the exim4 configuration:
```
root@smarthost /etc # diff -r exim4.orig/ exim4/
Only in exim4/: certbot_cert_fullchain.pem
Only in exim4/: certbot_cert_privkey.pem
Only in exim4/: dkimprivkey.pem
Only in exim4/: dkimpubkey.pem
Only in exim4/: exim4.conf.localmacros
diff -r exim4.orig/exim4.conf.template exim4/exim4.conf.template
51a52,53
> # Make some ports enforce SSL on connect:
> tls_on_connect_ports = 465
2090,2097c2092,2108
< # dovecot_plain_server:
< #   driver = dovecot
< #   public_name = PLAIN
< #   server_socket = /var/spool/exim4/dovecot.auth-client
< #   server_set_id = $auth1
< #   .ifndef AUTH_SERVER_ALLOW_NOTLS_PASSWORDS
< #   server_advertise_condition = ${if eq{$tls_in_cipher}{}{}{*}}
< #   .endif
---
>   dovecot_plain_server:
>     driver = dovecot
>     public_name = PLAIN
>     server_socket = /var/spool/exim4/dovecot.auth-client
>     server_set_id = $auth1
>     .ifndef AUTH_SERVER_ALLOW_NOTLS_PASSWORDS
>     server_advertise_condition = ${if eq{$tls_in_cipher}{}{}{*}}
>     .endif
> 
>   dovecot_login_server:
>     driver = dovecot
>     public_name = LOGIN
>     server_socket = /var/spool/exim4/dovecot.auth-client
>     server_set_id = $auth1
>     .ifndef AUTH_SERVER_ALLOW_NOTLS_PASSWORDS
>     server_advertise_condition = ${if eq{$tls_in_cipher}{}{}{*}}
>     .endif
Only in exim4/: exim.crt
Only in exim4/: exim.key
diff -r exim4.orig/update-exim4.conf.conf exim4/update-exim4.conf.conf
19,21c19,21
< dc_eximconfig_configtype='local'
< dc_other_hostnames='smarthost.example.com'
< dc_local_interfaces='127.0.0.1 ; ::1'
---
> dc_eximconfig_configtype='internet'
> dc_other_hostnames='static.1.2.3.4.example.net:smarthost.example.com'
> dc_local_interfaces='<; [0.0.0.0]:25; [0.0.0.0]:465; [0.0.0.0]:587; [::0]:25; [::0]:465; [::0]:587'
```

Make sure to `chgrp Debian-exim /etc/exim4/exim.{crt,key}`, then:

```
systemctl restart dovecot
systemctl restart exim4
```

If you want to use letsencrypt certs instead of exim.{crt,key}, you have
to copy the "privkey" and "fullchain" files from the
/etc/letsencrypt/live/$CERTNAME/ folder into /etc/exim4, and also `chgrp`
them to the `Debian-exim` group name. Then add to
`/etc/exim4/exim4.conf.localmacros`, creating it if necessary:
```
MAIN_TLS_ENABLE=yes
MAIN_TLS_PRIVATEKEY=/etc/exim4/certbot_cert_privkey.pem
MAIN_TLS_CERTIFICATE=/etc/exim4/certbot_cert_fullchain.pem
```
Then run `sudo update-exim4.conf`, and `sudo systemctl restart exim4`

## resources
* [Debian Exim4 configuration](https://wiki.debian.org/Exim)
* <https://doc.dovecot.org/configuration_manual/howto/exim_and_dovecot_sasl/>,
  but see /etc/exim4/exim4.conf.template for corrections, *and* make sure
  to uncomment from `dovecot_plain_server:` to the end of the code block.
* <https://www.stevenrombauts.be/2018/12/test-smtp-with-telnet-or-openssl/>
* <https://www.transip.eu/knowledgebase/entry/3012-installing-configuring-dovecot-ubuntu-debian/>
* <https://serverfault.com/questions/313357/test-a-pop3-secure-ssl-port-995>
* (Possible reason why letsencrypt certificate/key not recognized (Base64 decoding error.): need to remove passphrase?)[https://blog.differentpla.net/blog/2007/07/17/gnu-tls-reports-base64-decoding-error/] (nope, that wasn't it.)
* <https://www.linode.com/docs/guides/what-are-pop-and-imap/>
* previous versions of this README listed problems with certbot certs and keys
  which were only caused by my use of the wrong exim4 macros; closer inspection
  of the exim4 mainlog showed that it was trying to use the privkey file for
  both cert and key.
* for spam filtering, I added the following to
  `/etc/exim4/exim4.conf.localmacros`, and they seem to work, but I don't
  remember where I got all this from:
  ```
  # spam filtering
  CHECK_RCPT_IP_DNSBLS=zen.spamhaus.org:bl.spamcop.net:cbl.abuseat.org
  CHECK_RCPT_SPF=true
  DKIM_DOMAIN=${lc:${domain:$h_from:}}
  DKIM_FILE=/etc/exim4/dkimprivkey.pem
  DKIM_SELECTOR=default
  DKIM_CANON=relaxed
  DKIM_PRIVATE_KEY=${if match_domain{DKIM_DOMAIN}{+local_domains}{DKIM_FILE}{0}}
  ```
  of course, you need to run `sudo update-exim4.conf` and
  `sudo systemctl restart exim4` afterwards.
