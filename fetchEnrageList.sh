#!/bin/bash
# Get the list of spell IDs with dispel type "Enrage" from db.mmo-champion.com
curl -s http://db.mmo-champion.com/spells/?dispel_type=9 | perl -ne '/.id.: (\d+)/ and print "$1,\n";' | sort -nu | indent -nhnl

