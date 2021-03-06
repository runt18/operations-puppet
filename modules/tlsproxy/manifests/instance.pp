# This defines the actual nginx daemon/instance which tlsproxy "sites" belong to
class tlsproxy::instance {
    # Tune kernel settings
    include base::mysterious_sysctl

    $nginx_worker_connections = '32768'
    $nginx_ssl_conf = ssl_ciphersuite('nginx', 'compat')
    $do_spdy = hiera('tlsproxy::localssl::do_spdy', true)

    class { 'nginx': managed => false, }

    file { '/etc/nginx/nginx.conf':
        content => template('tlsproxy/nginx.conf.erb'),
        tag     => 'nginx',
    }

    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/tlsproxy/logrotate',
        tag    => 'nginx',
    }
}
