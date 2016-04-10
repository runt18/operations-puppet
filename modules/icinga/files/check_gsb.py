#!/usr/bin/env python
import urllib
import argparse
import sys

APP_VERSION = 0.1
PROTOCOL_VERSION = 3.1
GSB_URL = 'https://sb-ssl.google.com/safebrowsing/api/lookup'
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3


def check_url(url, client_id, api_key):
    t = urllib.urlopen(
        '{0!s}?client={1!s}&key={2!s}&appver={3!s}&pver={4!s}&url={5!s}'.format(GSB_URL, client_id, api_key, APP_VERSION, PROTOCOL_VERSION, url))
    status = t.getcode()
    if status == 200:
        return (CRITICAL, '{0!s} marked as {1!s}'.format(url, t.read()))
    elif status == 204:
        return (OK, '{0!s} is OK'.format(url))
    else:
        return (UNKNOWN, 'Status: {0!s}'.format(status))


def handle_args():
    parser = argparse.ArgumentParser(
        description='Google Safebrowsing Lookup API client')
    parser.add_argument('-v',
                        '--version',
                        action='version',
                        version='{0!s}'.format(APP_VERSION))
    parser.add_argument(
        'client_id',
        help='Client ID as specified by developers console',
        action='store')
    parser.add_argument(
        'api_key',
        help='API key as specified by developers console',
        action='store')
    parser.add_argument(
        'url',
        help='url to check',
        action='store')
    args = parser.parse_args()
    return vars(args)


def main():
    args = handle_args()
    url = args['url']
    client_id = args['client_id']
    api_key = args['api_key']
    state, text = check_url(url, client_id, api_key)
    print text
    sys.exit(state)


if __name__ == '__main__':
    main()
