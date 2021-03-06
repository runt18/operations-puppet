# == Class: phabricator
#
# Phabricator is a collection of open source web applications
# that help software companies build better software.
#
# === Parameters
#
# [*phabdir*]
#    The path on disk to clone the needed repositories
#
# [*timezone]
#     A php.ini compatible timezone
#     http://www.php.net//manual/en/datetime.configuration.php
#
# [*settings*]
#     A hash of configuration options for the local settings json file.
#     https://secure.phabricator.com/book/phabricator/article/advanced_configuration/#configuration-sources
#
# [*mysql_admin_user*]
#     Specify to use a different user for schema upgrades and database
#     maintenance
#     Requires: mysql_admin_pass
#
# [*mysql_admin_pass*]
#     Specify to use a different password for schema upgrades and database
#     maintenance
#     Requires: mysql_admin_user
#
# [*extensions*]
#     Array of extensions to load
#
# [*serveralias*]
#     Alternative domain on which to respond too
#
# [*deploy_user*]
#     The username that is used for scap deployments
#
# [*deploy_target*]
#     The name of the scap3 deployment repo, e.g. phabricator/deployment
#
# [*deploy_key*]
#     The url of the public key for the deploy_user to deploy with scap

# === Examples
#
#    class { 'phabricator':
#        settings    => {
#            'phabricator.base-uri' => 'http://myurl.domain',
#        },
#    }
#
# See README for post install instructions
#

class phabricator (
    $phabdir          = '/srv/phab',
    $timezone         = 'UTC',
    $trusted_proxies  = [],
    $libraries        = [],
    $extensions       = [],
    $settings         = {},
    $mysql_admin_user = '',
    $mysql_admin_pass = '',
    $serveradmin      = '',
    $serveralias      = '',
    $deploy_user      = 'phab-deploy',
    $deploy_target    = 'phabricator/deployment',
    $deploy_key       = "puppet:///modules/phabricator/phab-deploy-key.${::realm}",
) {

    $deploy_root = "/srv/deployment/${deploy_target}"

    # base dependencies to ensure the phabricator deployment root exists
    # save as a var since this will be required by many resources in this class
    $base_requirements = [Package[$deploy_target]]

    #A combination of static and dynamic conf parameters must be merged
    $module_path = get_module_path($module_name)
    $fixed_settings = loadyaml("${module_path}/data/fixed_settings.yaml")

    #per stdlib merge the dynamic settings will take precendence for conflicts
    $phab_settings = merge($fixed_settings, $settings)

    if empty($mysql_admin_user) {
        $storage_user = $phab_settings['mysql.user']
    } else {
        $storage_user = $mysql_admin_user
    }

    if empty($mysql_admin_pass) {
        $storage_pass = $phab_settings['mysql.pass']
    } else {
        $storage_pass = $mysql_admin_pass
    }

    package { [
        'python-pygments',
        'python-phabricator',
        'php5-mysql',
        'php5-gd',
        'php-apc',
        'php5-mailparse',
        'php5-dev',
        'php5-curl',
        'php5-cli',
        'php5-json',
        'php5-ldap',
        'apachetop',
        'subversion']:

            ensure => present;
    }

    include apache::mod::php5
    include apache::mod::rewrite
    include apache::mod::headers

    $docroot = "${phabdir}/phabricator/webroot"
    $phab_servername = $phab_settings['phabricator.base-uri']

    apache::site { 'phabricator':
        content => template('phabricator/phabricator-default.conf.erb'),
        require => $base_requirements,
    }

    # Robots.txt disallowing to crawl the alias domain
    if $serveralias {
        file {"${phabdir}/robots.txt":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "User-agent: *\nDisallow: /\n",
        }
    }

    class { '::phabricator::deployment::target':
        deploy_user   => $deploy_user,
        deploy_key    => $deploy_key,
        deploy_target => $deploy_target,
    }

    file { $phabdir:
        ensure  => 'link',
        target  => $deploy_root,
        require => Package[$deploy_target],
    }

    file { "${phabdir}/phabricator/scripts/":
        mode    => '0754',
        recurse => true,
        before  => File["${phabdir}/phabricator/scripts/mail/"],
        require => $base_requirements,
    }

    file { "${phabdir}/phabricator/scripts/mail/":
        mode    => '0755',
        recurse => true,
        require => $base_requirements,
    }

    if ($libraries) {
        phabricator::libext { $libraries:
            rootdir => $phabdir,
            require => $base_requirements,
        }
        $phab_settings['load-libraries'] = $libraries
    }

    if ($extensions) {
        file { "${phabdir}/phabricator/src/extensions":
            ensure  => 'directory',
            path    => "${phabdir}/phabricator/src/extensions",
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            require => $base_requirements,
        }

        phabricator::extension { $extensions:
            rootdir => $phabdir,
            require => $base_requirements,
        }
    }

    file { '/etc/php5/apache2/php.ini':
        content => template('phabricator/php.ini.erb'),
        notify  => Service['apache2'],
        require => Package['libapache2-mod-php5'],
    }

    file { '/etc/apache2/phabbanlist.conf':
        content => template('phabricator/phabbanlist.conf.erb'),
        require => Package['libapache2-mod-php5'],
        notify  => Service['apache2'],
    }

    file { "${phabdir}/phabricator/conf/local/local.json":
        content => template('phabricator/local.json.erb'),
        require => $base_requirements,
    }

    #default location for phabricator tracked repositories
    if ($phab_settings['repository.default-local-path']) {
        $repo_root = $phab_settings['repository.default-local-path']
        file { $repo_root:
            ensure => directory,
            mode   => '0755',
            owner  => 'phd',
            group  => 'www-data',
        }
        file { "${deploy_root}/repos":
            ensure  => 'link',
            target  => $repo_root,
            require => $base_requirements,
        }
    }

    file { '/usr/local/bin/arc':
        ensure  => 'link',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        target  => '/srv/phab/arcanist/bin/arc',
        require => $base_requirements,
    }

    class { 'phabricator::vcs':
        basedir  => $phabdir,
        settings => $phab_settings,
        require  => $base_requirements,
    }

    class { 'phabricator::phd':
        basedir  => $phabdir,
        settings => $phab_settings,
        before   => Service['phd'],
        require  => $base_requirements,
    }

    # This needs to become Upstart managed
    # https://secure.phabricator.com/book/phabricator/article/managing_daemons/
    # Meanwhile upstream has a bug to make an LSB friendly wrapper
    # https://secure.phabricator.com/T8129
    service { 'phd':
        ensure     => running,
        start      => '/usr/sbin/service phd start --force',
        status     => '/usr/bin/pgrep -f phd-daemon',
        hasrestart => true,
        require    => $base_requirements,
    }
}
