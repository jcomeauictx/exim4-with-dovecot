# exim4-with-dovecot

Modify the dovecot configuration as so:

```
root@smarthost /etc # diff -r dovecot-20250614.orig/ dovecot
diff -r dovecot-20250614.orig/conf.d/10-master.conf dovecot/conf.d/10-master.conf
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
# diff exim4-20250615.orig/ exim4/
Only in exim4/: certbot_cert_fullchain.pem
Only in exim4/: certbot_cert_privkey.pem
Common subdirectories: exim4-20250615.orig/conf.d and exim4/conf.d
Only in exim4/: dkimprivkey.pem
Only in exim4/: dkimpubkey.pem
Only in exim4/: exim4.conf.localmacros
diff exim4-20250615.orig/exim4.conf.template exim4/exim4.conf.template
2090,2097c2090,2097
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
Only in exim4/: exim.crt
Only in exim4/: exim.key
diff exim4-20250615.orig/update-exim4.conf.conf exim4/update-exim4.conf.conf
19,21c19,21
< dc_eximconfig_configtype='local'
< dc_other_hostnames='smarthost.example.net'
< dc_local_interfaces='127.0.0.1 ; ::1'
---
> dc_eximconfig_configtype='internet'
> dc_other_hostnames='static.1.2.3.4.example.com:smarthost.example.com:example.net'
> dc_local_interfaces='<; [0.0.0.0]:25; [0.0.0.0]:465; [0.0.0.0]:587; [::0]:25; [::0]:465; [::0]:587'
27d26
< CFILEMODE='644'
31a31
> CFILEMODE='644'
```

Make sure to `chown Debian-exim /etc/exim4/exim.{crt,key}`, then:

```
systemctl restart dovecot
systemctl restart exim4
```

## resources
* [Debian Exim4 configuration](https://wiki.debian.org/Exim)
* <https://doc.dovecot.org/configuration_manual/howto/exim_and_dovecot_sasl/>,
  but see /etc/exim4/exim4.conf.template for corrections, *and* make sure
  to uncomment from `dovecot_plain_server:` to the end of the code block.
* <https://www.stevenrombauts.be/2018/12/test-smtp-with-telnet-or-openssl/>
* <https://www.transip.eu/knowledgebase/entry/3012-installing-configuring-dovecot-ubuntu-debian/>
* <https://serverfault.com/questions/313357/test-a-pop3-secure-ssl-port-995>
