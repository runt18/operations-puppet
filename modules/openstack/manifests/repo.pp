# sets upt APT repository for labs openstack.
#  We use the Ubuntu cloud archive for this -- this repo points us to the
#  package versions specified in $::openstack::version
class openstack::repo(
    $openstack_version=$::openstack::version,
) {
    # As of 26/10/2015 we support kilo on trusty (lsb_release -c)
    if ($::lsbdistcodename == 'trusty') {
        apt::repository { 'ubuntucloud':
            uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            dist       => "trusty-updates/${openstack_version}",
            components => 'main',
            # lint:ignore:puppet_url_without_modules
            keyfile    => 'puppet:///files/misc/ubuntu-cloud.key';
            # lint:endignore
        }
    }
}
