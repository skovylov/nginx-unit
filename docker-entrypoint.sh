#!/usr/bin/env bash

set -e

. /usr/share/helpers/timezone
. /usr/share/helpers/useradd

curl_put()
{
    RET=`/usr/bin/curl -s -w '%{http_code}' -X PUT --data-binary @$1 --unix-socket /var/run/control.unit.sock http://localhost/$2`
    RET_BODY=${RET::-3}
    RET_STATUS=$(echo $RET | /usr/bin/tail -c 4)
    if [ "$RET_STATUS" -ne "200" ]; then
        print_log $ERR "$0: Error: HTTP response status code is '$RET_STATUS'"
        print_log $ERR "$RET_BODY"
        return 1
    else
        print_log $OK "$0: OK: HTTP response status code is '$RET_STATUS'"
        print_log $OK "$RET_BODY"
    fi
    return 0
}

# setting timezone to user-defined
set_timezone $UNIT_TZ


if [ "$1" = "unitd" ]; then
    if /usr/bin/find "/var/lib/unit/" -mindepth 1 -print -quit 2>/dev/null | /bin/grep -q .; then
        print_log $INFO "$0: /var/lib/unit/ is not empty, skipping initial configuration..."
    else
        if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -print -quit 2>/dev/null | /bin/grep -q .; then
            print_log $OK "$0: /docker-entrypoint.d/ is not empty, launching Unit daemon to perform initial configuration..."
            /usr/sbin/unitd --control unix:/var/run/control.unit.sock

            while [ ! -S /var/run/control.unit.sock ]; do echo "$0: Waiting for control socket to be created..."; /bin/sleep 0.1; done
            # even when the control socket exists, it does not mean unit has finished initialisation
            # this curl call will get a reply once unit is fully launched
            /usr/bin/curl -s -X GET --unix-socket /var/run/control.unit.sock http://localhost/

            print_log $INFO "$0: Looking for certificate bundles in /docker-entrypoint.d/..."
            for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -name "*.pem"); do
                print_log $OK "$0: Uploading certificates bundle: $f"
                curl_put $f "certificates/$(basename $f .pem)"
            done

            print_log $INFO "$0: Looking for configuration snippets in /docker-entrypoint.d/..."
            for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -name "*.json"); do
                print_log $OK "$0: Applying configuration $f";
                curl_put $f "config"
            done

            print_log $INFO "$0: Looking for shell scripts in /docker-entrypoint.d/..."
            for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -name "*.sh"); do
                print_log $OK "$0: Launching $f";
                "$f"
            done

            # warn on filetypes we don't know what to do with
            for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -not -name "*.sh" -not -name "*.json" -not -name "*.pem"); do
                print_log $WARN "$0: Ignoring $f";
            done

            print_log $OK "$0: Stopping Unit daemon after initial configuration..."
            kill -TERM `/bin/cat /var/run/unit.pid`

            while [ -S /var/run/control.unit.sock ]; do print_log $INFO "$0: Waiting for control socket to be removed..."; /bin/sleep 0.1; done

            echo
            print_log $OK "$0: Unit initial configuration complete; ready for start up..."
            echo
        else
            print_log $OK "$0: /docker-entrypoint.d/ is empty, skipping initial configuration..."
        fi
    fi
fi

exec "$@"