#!/bin/bash
# Script to generate po files outside of the normal build process
#  
# Pre-requisite:
# The following tools must be installed on your system and accessible from path
# gawk, find, xgettext, sed, python, msguniq, msgmerge, msgattrib, msgfmt, msginit
#
# Run this script from within the po folder.
#
# Author: Pr2 for OpenPLi Team
# Version: 1.1
#
# Retrieve languages from Makefile.am LANGS variable for backward compatibility
#
localgsed="sed"
findoptions=""

#
# Script only run with gsed but on some distro normal sed is already gsed so checking it.
#
gsed --version 2> /dev/null | grep -q "GNU"
if [ $? -eq 0 ]; then
	localgsed="gsed"
else
	"$localgsed" --version | grep -q "GNU"
	if [ $? -eq 0 ]; then
		printf "GNU sed found: [%s]\n" $localgsed
	fi
fi

#
# On Mac OSX find option are specific
#
if [[ "$OSTYPE" == "darwin"* ]]
	then
		# Mac OSX
		printf "Script running on Mac OSX [%s]\n" "$OSTYPE"
    	findoptions=" -s -X "
fi

printf "Po files update/creation from script starting.\n"
languages=($(gawk ' BEGIN { FS=" " } 
		/^LANGS/ {
			for (i=3; i<=NF; i++)
				printf "%s ", $i
		} ' Makefile.am ))

# If you want to define the language locally in this script uncomment and defined languages
languages=("en" "it")

#
# Arguments to generate the pot and po files are not retrieved from the Makefile.
# So if parameters are changed in Makefile please report the same changes in this script.
#

printf "Creating temporary file enigma2-py.pot\n"
find $findoptions .. -name "*.py" -exec xgettext --no-wrap -L Python --from-code=UTF-8 -kpgettext:1c,2 --add-comments="TRANSLATORS:" -d enigma2 -s -o enigma2-py.pot {} \+
$localgsed --in-place enigma2-py.pot --expression=s/CHARSET/UTF-8/
printf "Creating temporary file enigma2-xml.pot\n"
find $findoptions .. -name "*.xml" -exec python xml2po.py {} \+ > enigma2-xml.pot
printf "Merging pot files to create: enigma2.pot\n"
cat enigma2-py.pot enigma2-xml.pot | msguniq --no-wrap --no-location -o enigma2.pot -
OLDIFS=$IFS
IFS=" "
for lang in "${languages[@]}" ; do
	if [ -f $lang.po ]; then \
		printf "Updating existing translation file %s.po\n" $lang
		msgmerge --backup=none --no-wrap --no-location -s -U $lang.po enigma2.pot && touch $lang.po; \
		msgattrib --no-wrap --no-obsolete $lang.po -o $lang.po; \
		msgfmt -o $lang.mo $lang.po; \
	else \
		printf "New file created: %s.po, please add it to github before commit\n" $lang
		msginit -l $lang.po -o $lang.po -i enigma2.pot --no-translator; \
		msgfmt -o $lang.mo $lang.po; \
	fi
done
rm enigma2-py.pot enigma2-xml.pot enigma2.pot
IFS=$OLDIFS
printf "Po files update/creation from script finished!\n"


