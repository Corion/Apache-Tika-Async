#!/usr/bin/env bash

JARS=${APACHE_TIKA_JARS:-jar}

declare -a SUPPORTED_VERSIONS=("1.14")

if [ ! -d "$JARS" ]; then
    mkdir "$JARS"
fi

for VERSION in "${SUPPORTED_VERSIONS[@]}"
do
   if [ ! -f "$JARS/tika-app-$VERSION.jar" ]; then
        wget "https://archive.apache.org/dist/tika/tika-app-$VERSION.jar" -O "$JARS/tika-app-$VERSION.jar"
   fi

   if [ ! -f "$JARS/tika-server-$VERSION.jar" ]; then
        wget "https://archive.apache.org/dist/tika/tika-server-$VERSION.jar" -O "$JARS/tika-server-$VERSION.jar"
   fi
done