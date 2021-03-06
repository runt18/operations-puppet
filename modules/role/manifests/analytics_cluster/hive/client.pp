# == Class role::analytics_cluster::hive::client
# Installs base configs and packages for hive client nodes.
#
class role::analytics_cluster::hive::client {
    require role::analytics_cluster::hadoop::client

    # The WMF webrequest table uses HCatalog's JSON Serde.
    # Automatically include this in Hive client classpaths.
    $hcatalog_jar = 'file:///usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core.jar'

    $auxpath = $hcatalog_jar

    # You must set at least:
    #   metastore_host
    class { '::cdh::hive':
        # Hive uses Zookeeper for table locking.
        zookeeper_hosts           => keys(hiera('zookeeper_hosts')),
        # We set support concurrency to false by default.
        # if someone needs to use it in their hive job, they
        # may manually set it to true via
        # set hive.support.concurrency = true;
        support_concurrency       => false,
        # Set this pretty high, to avoid limiting the number
        # of substitution variables a Hive script can use.
        variable_substitute_depth => 10000,
        auxpath                   => $auxpath,
        # default to using Snappy for parquet formatted tables
        parquet_compression       => 'SNAPPY',
    }
}
