#!/bin/bash
# Get the list of spell IDs with dispel type "Enrage" from db.mmo-champion.com

PAGE=1
while curl -s 'http://www.wowdb.com/spells?filter-dispel-type=9&page='$PAGE >enrage.$PAGE.html && grep -F 'rel="next"' enrage.$PAGE.html >/dev/null
do
    PAGE=$[$PAGE + 1]
done

cat enrage.*.html | perl -ne 'm@http://www.wowdb.com/spells/(\d+)\-@ and print "$1,\n";' | sort -nu

rm enrage.*.html
