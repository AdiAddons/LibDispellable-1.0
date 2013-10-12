#!/bin/bash
# Get the list of spell IDs with dispel type "Enrage" from db.mmo-champion.com
curl -s http://www.wowdb.com/spells?filter-dispel-type=9 | perl -ne 'm@http://www.wowdb.com/spells/(\d+)\-@ and print "$1,\n";' | sort -nu
