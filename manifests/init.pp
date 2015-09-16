# == Class: openldap
#
# Full description of class openldap here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'openldap':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class openldap(
    $ensure     = 'present'
    $ldap_type  = 'master',
    $base_dn    = 'dc=mozilla'
){

    include openldap::params

    if !($ldap_type in ['master', 'slave']) {
        fail("${ldap_type} is not a valid parameter")
    }

    if !($ensure in ['present', 'absent']) {
        fail("${ensure} is not a valid parameter")
    }

    if $ensure == 'present' {
        $package_ensure     = 'latest'
        $file_ensure        = 'file'
        $directory_ensure   = 'absent'
        $service_ensure     = 'running'
    }
    else {
        $package_ensure     = 'absent'
        $file_ensure        = 'absent'
        $directory_ensure   = 'absent'
        $service_ensure     = 'stopped'
    }

    # you get ldap client package no matter what
    package { 'openldap-clients':
        ensure => $package_ensure,
        name   => $openldap::params::client_package
    }

    package { 'openldap-servers':
        ensure => $package_ensure,
        name   => $openldap::params::server_package
    }

    file { "${openldap::params::conf_basedir}/restart-openldap.sh":
        ensure  => $file_ensure,
        owner   => root,
        owner   => root,
        mode    => '0755',
        require => Package['openldap-servers']
    }

    service { 'slapd':
        ensure     => $service_ensure
        hasstatus  => true,
        hasrestart => true,
        restart    => '/etc/openldap/restart-openldap.sh',
        require    => [ Package['openldap-servers'], File['/etc/openldap/restart-openldap.sh'] ]
    }

    # config file, the one that matters
    file { $openldap::params::server_conffile:
        ensure  => $file_ensure,
        owner   => $openldap::params::server_owner,
        group   => $openldap::params::server_group,
        content => template('openldap/slapd.conf.erb')
        notify  => Service['slapd']
    }

    # misc file portion
    file { '/var/lib/ldap_access_logs':
        ensure  => $directory_ensure,
        owner   => $openldap::params::server_owner,
        group   => 'ldap',
        recurse => true,
        before  => Service['slapd'],
        require => Package['openldap-servers']
    }

    file { '/var/lib/ldap_access_logs/DB_CONFIG':
        ensure  => $file_ensure,
        owner   => $openldap::params::server_owner,
        group   => $openldap::params::server_group,
        source  => 'puppet:///modules/openldap/DB_CONFIG'
        notify  => Service['slapd'],
        require => File['/var/lib/ldap_access_logs'],
    }

    file { '/var/lib/ldap_access_logs/logs':
        ensure  => $directory_ensure,
        owner   => $openldap::params::server_owner,
        group   => $openldap::params::server_group,
        before  => Service['slapd'],
        require => File['/var/lib/ldap_access_logs'];
    }

    file { '/var/lib/ldap/DB_CONFIG':
        ensure  => $file_ensure,
        owner   => $openldap::params::server_owner,
        group   => $openldap::params::server_group,
        notify  => Service['slapd'],
        require => Package['openldap-servers'],
        source  => "puppet:///modules/openldap/DB_CONFIG";
    }
    file { '/var/lib/ldap/logs':
        ensure  => $directory_ensure,
        owner   => $openldap::params::server_owner,
        group   => $openldap::params::server_group,
        before  => Service['slapd'],
        require => Package['openldap-servers'];
    }

    file { '/var/lib/ldap/auditlogs':
        ensure  => $directory_esnure,
        owner   => $openldap::params::server_owner,
        group   => $openldap::params::server_group,
        before  => Service['slapd'],
        require => Package['openldap-servers'];
    }

    # schema portion


    # Cert portion
    file { '/etc/openldap/certs':
        ensure  => $directory_ensure,
        owner   => root,
        group   => root,
        require => Package['openldap-servers']
    }

    file { '/etc/openldap/cacerts':
        ensure  => $directory_ensure,
        owner   => root,
        group   => root,
        require => Package['openldap-servers']
    }

}
