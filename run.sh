#!/bin/bash

if [[ -z "$1" || -z "$2" || ! -d "$1" || ! -d "$2" ]]; then
    echo "USAGE: $0 <directory of CAR files> <directory of proxy XML files>"
    exit 0
fi

CAR_FILES_DIR=$1
PROXY_SERVICES_DIR=$2

SCRIPT_PATH=$(dirname $(realpath -s $0))
INCLUDES=$SCRIPT_PATH/includes
TMP=$SCRIPT_PATH/.tmp
UNPACKED_CARS_DIR=$TMP/unpacked-cars
NORMALIZED_PROXY_SERVICES_DIR=$TMP/normalized-proxy-services/

# Initial prep and cleanup
rm -rf $TMP
mkdir -p $UNPACKED_CARS_DIR
mkdir -p $NORMALIZED_PROXY_SERVICES_DIR

# Unpack the car files
echo "Unpacking CAR files from $CAR_FILES_DIR to $UNPACKED_CARS_DIR..."
for car in $CAR_FILES_DIR/*.car; do
    unzip -q -o -d $UNPACKED_CARS_DIR $car
done

# Normalize the proxy files for analysis
echo "Copying/normalizing proxies from $PROXY_SERVICES_DIR into $NORMALIZED_PROXY_SERVICES_DIR for analysis..."
find $PROXY_SERVICES_DIR -name *.xml -exec cp {} $NORMALIZED_PROXY_SERVICES_DIR \;
find $NORMALIZED_PROXY_SERVICES_DIR -name *.xml -exec xsltproc -o {} $INCLUDES/formatXML.xslt {} \;

# Produce kill-list (all in one, but slow)
echo "Doing analysis..."
for file in $(find $UNPACKED_CARS_DIR -name *.xml); do
    NAME=$(grep '<proxy.*name=' $file | grep -Po '(?<=name=")[^"]*')
    grep -rl "<proxy.*name=\"$NAME\"" $NORMALIZED_PROXY_SERVICES_DIR | # Get list of files with conflicting names...
        grep -v $(basename $file) |                                    # which are not related to the CAR file itself...
        grep -o "[^/]*.xml" >> $TMP/kill-list                          # and stick them all in the kill-list file
done

# Sort the kill-list and display it
echo "Analysis complete."
echo "----------------"
cat $TMP/kill-list | sort
