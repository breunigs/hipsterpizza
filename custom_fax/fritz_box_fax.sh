#!/bin/sh

set -e

HOST="http://…/" # include trailing slash

echo "\n\n\n"
echo "Thank you for ssh-ing into me."

echo "Retrieving fax number…"
fax=$(wget -q -O - "${HOST}?action=getfaxnumber")

# Adjust prefix: this is a precaution so you don’t fax to expensive
# numbers.
prefix=$(echo "$fax" | grep "^01234" || true)
if [ "$prefix" = "" ]; then
  echo "Retrieved fax number does not have expected prefix. Aborting, sorry."
  exit 1
fi

echo "\nRetrieving PDF…"
tmp="$(tempfile).pdf"
trap "rm -f $tmp $tmp.tif" EXIT

wget -q -O "$tmp" "${HOST}?action=genpdf"
size=$(wc -c "$tmp" | cut -f1 -d" ")

if [ "$size" = "0" ]; then
  echo "Retrieved PDF appears to be broken/empty. Aborting, sorry."
  exit 1
fi

echo "About to fax a ${size} bytes document to ${fax}."
echo "Continue? [y/N]"
read answer

echo "\n\n"
echo "Blocking further orders…"
wget -q -O /dev/null "${HOST}?action=marksubmitted"

if [ "$answer" = "y" ]; then
  echo "Faxing now, you should see some output…"
  roger_cli --sendfax --file "${tmp}" --number "${fax}"
  #roger_cli --sendfax --file "${tmp}" --number "${fax}" --debug
else
  echo "okay, aborting."
  exit 1
fi

echo "\n\nWell, it seems it worked. Here’s the latest fax report via pdftotext:\n\n\n"
cd /where/roger_router/stores/fax_reports
pdftotext -layout $(ls -1th | tail -n1) -

exit 0
