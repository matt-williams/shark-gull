#!/bin/sh
[ "$1" != "" ] || { echo "Usage: $0 <pcap file>" ; exit 1 ; }
tshark -T pdml -r $1 | xsltproc pdml2seagull.xsl - > $(basename $1).seagull.xml
