class mediawiki::maintenance::cirrussearch( $ensure = present ) {
    require mediawiki::users

    # Rebuilds the completion suggester indices daily. This is scheduled
    # to run during the low period of cirrus usage, which is generally 3am
    # to 7am UTC. The `|| true` statement ensures one failing wiki doesn't
    # fail the entire job. This job, as of mar 2015, takes around 5 hours
    # to run.
    Cron {
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 30,
        hour    => 2,
    }

    cron {
        'cirrus_build_completion_indices_eqiad':
            command => '/usr/local/bin/expanddblist all | xargs -I{} -P 4 sh -c \'/usr/local/bin/mwscript extensions/CirrusSearch/maintenance/updateSuggesterIndex.php --wiki={} --masterTimeout=10m --replicationTimeout=5400 --cluster=eqiad --optimize > /var/log/mediawiki/cirrus-suggest/{}.eqiad.log 2>&1 || true\'';
        'cirrus_build_completion_indices_codfw':
            command => '/usr/local/bin/expanddblist all | xargs -I{} -P 4 sh -c \'/usr/local/bin/mwscript extensions/CirrusSearch/maintenance/updateSuggesterIndex.php --wiki={} --masterTimeout=10m --replicationTimeout=5400 --cluster=codfw --optimize > /var/log/mediawiki/cirrus-suggest/{}.codfw.log 2>&1 || true\''
    }

    file { '/var/log/mediawiki/cirrus-suggest':
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
        mode   => '0775'
    }

    logrotate::conf { 'cirrus-suggest':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/logrotate.d_cirrus-suggest',
    }
}
