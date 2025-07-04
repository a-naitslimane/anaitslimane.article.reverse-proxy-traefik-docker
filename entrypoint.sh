#! /bin/sh
set -e

echo "Setting acme.json permissions 0600"
touch /letsencrypt/acme.json
chmod 600 /letsencrypt/acme.json
chown root:root /letsencrypt
chown root:root /letsencrypt/acme.json

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- traefik "$@"
fi

# if our command is a valid Traefik subcommand, let's invoke it through Traefik instead
# (this allows for "docker run traefik version", etc)
if traefik "$1" --help >/dev/null 2>&1
then
    set -- traefik "$@"
else
    echo "= '$1' is not a Traefik command: assuming shell execution." 1>&2
fi

exec "$@"