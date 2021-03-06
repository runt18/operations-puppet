# == Define: varnish::logging::media
#
#  Accumulate browser cache hit ratio and total request volume statistics
#  for Media requests and report to StatsD.
#
# === Parameters
#
# [*statsd_server*]
#   StatsD server address, in "host:port" format.
#   Defaults to localhost:8125.
#
# === Examples
#
#  varnish::logging::media {
#    statsd_server => 'statsd.eqiad.wmnet:8125
#  }
#
define varnish::logging::media( $statsd_server = 'statsd' ) {
    include varnish::common

    file { '/usr/local/bin/varnishmedia':
        source  => 'puppet:///modules/varnish/varnishmedia',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/usr/local/lib/python2.7/dist-packages/varnishlog.py'],
        notify  => Service['varnishmedia'],
    }

    base::service_unit { 'varnishmedia':
        ensure         => present,
        systemd        => true,
        strict         => false,
        template_name  => 'varnishmedia',
        require        => File['/usr/local/bin/varnishmedia'],
        service_params => {
            enable => true,
        },
    }
}
