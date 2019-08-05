#!/usr/bin/env bash

set -Eeuo pipefail

function addStanzaToFile() {
  local file=$1
  local name=${2//\//\\/}
  local value=${3//\//\\/}

  [ -f "${file}" ] || echo -e "# This file is automatically generated.\n" >> "$file"

  sed -i \
      -e '/^#\?\(\s*'"${name}"'\s*=\s*\).*/{s//\1'"${value}"'/;:a;n;ba;q}' \
      -e '$a'"${name}"'='"${value}" "$file"
}

function configureFileFromEnvironment() {
    local file=$1
    local prefix=$2

    local var
    local value

    echo "Configuring $file"
    for c in $(printenv | perl -sne 'print "$1 " if m/^${prefix}_(.+?)=.*/' -- -prefix="$prefix"); do
        name=$(echo "${c}" | perl -pe 's/___/-/g; s/__/./g')
        var="${prefix}_${c}"
        value=${!var}
        echo " - Setting $name=$value"
        addStanzaToFile "$file" "$name" "$value"
    done
}

configureFileFromEnvironment /usr/local/etc/kismet_site.conf SITE_CONF

if [ "${1:0:1}" = '-' ]; then
  set -- kismet "$@"
fi

exec gosu kismet "$@"
