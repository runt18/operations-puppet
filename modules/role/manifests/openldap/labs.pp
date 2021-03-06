# LDAP servers for labs (based on OpenLDAP)

class role::openldap::labs {
    include passwords::openldap::labs
    include base::firewall

    $ldap_labs_hostname = hiera('ldap_labs_hostname')

    system::role { 'role::openldap::labs':
        description => 'LDAP servers for labs (based on OpenLDAP)'
    }

    # Certificate needs to be readable by slapd
    sslcert::certificate { $ldap_labs_hostname:
        group => 'openldap',
    }

    $sync_pass = $passwords::openldap::labs::sync_pass
    class { '::openldap':
        sync_pass     => $sync_pass,
        mirrormode    => true,
        suffix        => 'dc=wikimedia,dc=org',
        datadir       => '/var/lib/ldap/labs',
        ca            => '/etc/ssl/certs/ca-certificates.crt',
        certificate   => "/etc/ssl/localcerts/${ldap_labs_hostname}.crt",
        key           => "/etc/ssl/private/${ldap_labs_hostname}.key",
        extra_schemas => ['dnsdomain2.schema', 'nova_sun.schema', 'openssh-ldap.schema',
                          'puppet.schema', 'sudo.schema'],
        extra_indices => 'openldap/labs-indices.erb',
        extra_acls    => 'openldap/labs-acls.erb',
    }

    # Ldap services are used all over the place, including within
    #  labs and on various prod hosts.
    ferm::service { 'labs_ldap':
        proto  => 'tcp',
        port   => '(389 636)',
        srange => '$ALL_NETWORKS',
    }

    monitoring::service { 'labs_ldap_check':
        description   => 'Labs LDAP ',
        check_command => 'check_ldap!dc=wikimedia,dc=org',
        critical      => false,
    }

    $monitor_pass = $passwords::openldap::labs::monitor_pass
    diamond::collector { 'OpenLDAP':
        settings => {
            host     => $ldap_labs_hostname,
            username => '"cn=monitor,dc=wikimedia,dc=org"',
            password => $monitor_pass,
        },
    }
}
