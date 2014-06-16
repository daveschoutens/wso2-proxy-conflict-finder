#!/bin/bash
CAR_FILES_DIR=~/stuff/copilot/wso2esb/car-deployments/int-esb/test-esb
PROXY_SERVICES_DIR=../proxy-services
OUTPUT=output.txt

INCLUDES=./includes
TMP=./.tmp
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

# Sort the kill-list and 'publish' it
echo "Analysis complete.  List of conflicts saved to file: $OUTPUT."
cat $TMP/kill-list | sort > $OUTPUT

echo "Outputting list:"
echo "----------------"
cat $OUTPUT
