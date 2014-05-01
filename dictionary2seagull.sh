#!/bin/sh
[ -f wireshark/diameter/dictionary.xml ] || { echo "wireshark/diameter/dictionary.xml not found - try \"git submodule update --init\"?" ; exit 1 ; }
# xsltproc doesn't like Wireshark's Custom.xml file, so strip it out.
mkdir -p build
cp -R wireshark/diameter build/dictionary
egrep -v '<!ENTITY Custom[ \t]*SYSTEM "Custom.xml">' wireshark/diameter/dictionary.xml |
egrep -v '&Custom;' > build/dictionary/dictionary.xml
# Run the XSLT over Wireshark's dictionary
xsltproc --xinclude dictionary2seagull.xsl build/dictionary/dictionary.xml > dictionary.seagull.xml
