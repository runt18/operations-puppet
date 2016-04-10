#! /usr/bin/env python
import urllib2
import json
import sys

if '-h' in sys.argv:
    print "Monitor the failure rate of a target with RIPE Atlas"
    print "Usage {0!s} <UDM_id> <loss_allow> <failures> ".format((sys.argv[0]))
    print ""
    print "UDM_id       = numeric check ID from RIPE Atlas"
    print "loss_allow   = number percentage of packet loss allowable"
    print "failures     = how many failures before CRITICAL (in one poll)"
    sys.exit(0)

ripeurl = 'https://atlas.ripe.net/api/v1/status-checks/'
UDM_id = sys.argv[1]
loss_allowed = sys.argv[2]
allowed_failures = sys.argv[3]
msg = "%s - failed %d probes of %d (alerts on %s) - " \
      "https://atlas.ripe.net/measurements/%s/#!map"


def main():

    udm = '{0!s}/'.format(UDM_id)
    failures = '?permitted_total_alerts={0!s}'.format(allowed_failures)
    loss = '&max_packet_loss={0!s}'.format((loss_allowed))
    url = ripeurl + udm + failures + loss

    request = urllib2.Request(url)
    jout = json.load(urllib2.urlopen(request, timeout=120))
    total_probes = len(jout['probes'].keys())
    failed_probes = [k for k, v in jout['probes'].iteritems() if v['alert']]

    if '-v' in sys.argv:
        print "UDM ", UDM_id
        print "Allowed Failures ", allowed_failures
        print "Allowed % percent loss", loss_allowed
        print "Total", total_probes
        print "Failed ({0:d}): {1!s}".format(len(failed_probes),
                                   failed_probes)
        print url
        print ''

    elif '-vv' in sys.argv:
        print jout
        exit(0)

    if jout['global_alert']:

        print msg % ('CRITICAL',
                     len(failed_probes),
                     total_probes,
                     allowed_failures,
                     UDM_id)
        sys.exit(2)
    else:
        print msg % ('OK',
                     len(failed_probes),
                     total_probes,
                     allowed_failures,
                     UDM_id)
main()
