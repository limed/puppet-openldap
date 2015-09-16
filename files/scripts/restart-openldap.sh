#!/bin/bash

slapd_lockfile=/var/lock/subsys/slapd
slapd_pidfile=/var/run/openldap/slapd.pid
pidfile=/var/run/slapd.pid
slapd_pid=$(cat $slapd_pidfile)
/bin/kill -INT $slapd_pid
while /bin/kill -0 $slapd_pid >/dev/null; do sleep 1; done
/bin/rm -f $pidfile $slapd_lockfile
/bin/rm -rf /etc/openldap/slapd.d/*
/usr/sbin/slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
/bin/chown -R ldap:ldap /etc/openldap/slapd.d
/bin/chmod -R 000 /etc/openldap/slapd.d
/bin/chmod -R u+rwX /etc/openldap/slapd.d
/etc/init.d/slapd start
