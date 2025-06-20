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
< dc_other_hostnames='example.net'
< dc_local_interfaces='127.0.0.1 ; ::1'
---
> dc_eximconfig_configtype='internet'
> dc_other_hostnames='static.1.2.3.4.example.com:example.net'
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
them to the `Debian-exim` group name.

However, I (jc@unternet.net) still cannot get them to work. The privkeys are
an odd format, the only way I can dump them with openssl is to use:
```
openssl pkey -in /etc/exim4/certbot_cert_privkey.pem -noout -text
```
And it shows "Private-Key: (256 bit)", the "priv" and "pub" data, then
"ASN1 OID: prime256v1" and "NIST CURVE: P-256". Exim doesn't seem to know
what to do with it, and I don't know enough to convert it to something that
might work.

`openssl pkcs8 -nocrypt -in /etc/exim4/certbot_cert_privkey.pem` also "works",
as in no errors, but it merely outputs the same as the input.

Anyway, assuming you can find a way to solve the problem, add
```
MAIN_TLS_CERTKEY=/etc/exim4/certbot_cert_privkey.pem
MAIN_TLS_CERTIFICATE=/etc/exim4/certbot_cert_fullchain.pem
```
to `/etc/exim4/exim4.conf.localmacros`, creating the file if it doesn't
already exist. `MAIN_TLS_ENABLE=yes` should already be in there somewhere.

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
