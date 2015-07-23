#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  Copyright (c) 2014 unfoldingWord
#  http://creativecommons.org/licenses/MIT/
#  See LICENSE file for details.
#
#  Contributors:
#  Jesse Griffin <jesse@distantshores.org>
#  Caleb Maclennan <caleb@alerque.com>
#-----------------------------------------------------------------------------
# Help message
help() {
    echo
    echo "Creates a PDF for specified language code."
    echo
    echo "Usage:"
    echo "   $PROGNAME -l <LangCode> -v <version>"
    echo "   $PROGNAME --help"
    echo
    exit 1
}

#-----------------------------------------------------------------------------
# Parse the command-line
if [ $# -lt 1 ]; then
    help
fi
while test -n "$1"; do
    case "$1" in
        --help|-h)
            help
            ;;
        --lang|-l)
            LANG="$2"
            shift
            ;;
        --ver|-v)
            VER="$2"
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            help
            ;;
    esac
    shift
done

[[ -z "$LANG" ]] && echo "Please specify language code." && exit 1

#-----------------------------------------------------------------------------
# Certain variables and paths
MAILTO="publishing@unfoldingword.org"
TOOLS="/var/www/vhosts/door43.org/tools"
API="/var/www/vhosts/api.unfoldingword.org/httpdocs/obs/txt/1/$LANG"
FILENAME="OBS-$LANG-v$VER"

#-----------------------------------------------------------------------------
# Link the httpdocs folder in /tmp
myhost=$(uname -n)
[[ $myhost == test.door43.org ]] && ln -sf /var/www/vhosts/door43.org/httpdocs /tmp/httpdocs
BACK_FOLDER=$(pwd)
PARENT_FOLDER=$(dirname $BACK_FOLDER)
HISTORY_TMP_FOLDER=/tmp/obs_publish_PDF
for folder in httpdocs includes
do
    ln -sf $PARENT_FOLDER/$folder /tmp/$folder
done
    
#-----------------------------------------------------------------------------
# Run python (export.py) to generate the .tex file from template .tex files
cd /tmp
$TOOLS/obs/export.py -l $LANG -f tex -o /tmp/$FILENAME.tex 2>&1 | tee /tmp/$FILENAME.py-stderr
RC=$?
echo RC=$?, \$ context $$.$FILENAME.tex 1>&2
echo $(pwd)/$$.$FILENAME.tex 1>&2
[[ $RC -gt 0 ]] && exit $RC

#-----------------------------------------------------------------------------
# Run ConTeXt (context) to generate stories from .tex file output by python
mkdir -p $HISTORY_TMP_FOLDER
cd /tmp
. /opt/context/tex/setuptex
context $FILENAME.tex
RC=$?
echo RC=$?, \$ context $$.$FILENAME.tex 1>&2
echo $(pwd)/$$.$FILENAME.tex 1>&2
[[ $RC -gt 0 ]] && exit $RC

#-----------------------------------------------------------------------------
# Install the files into /tmp and make readable by all (666)
mkdir -p $API
cp -pf /tmp/$$.$FILENAME.pdf $API/$FILENAME.pdf
{
    cp -p /tmp/$FILENAME.tex /tmp/$$.$FILENAME.tex
    cp -p /tmp/$FILENAME.log /tmp/$$.$FILENAME.log
    cp -pf /tmp/$FILENAME.pdf /tmp/$$.$FILENAME.pdf
    chmod 666 /tmp/$$.* /tmp/$FILENAME.*
    chown dboerschlein /tmp/$$.* /tmp/$FILENAME.*
    zipF=/tmp/dboerschlein.$LANG.$(date +%Y%m%d.%H%M).zip
    zip -9rj $zipF /tmp/$FILENAME.* 
    chmod 666 $zipF 
    chown dboerschlein $zipF
    ls -ltd $zipF
}

#-----------------------------------------------------------------------------
#rm -f /tmp/$$.*

URL="https://api.unfoldingword.org/obs/txt/1/$LANG/$FILENAME.pdf"
#echo "A PDF for $LANG at version $VER has been created.  " \
    #"Please download it from $URL." \
    #| mail -s "PDF Generated for $LANG" "$MAILTO"
