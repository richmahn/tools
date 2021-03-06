#!/usr/bin/env bash
# -*- coding: utf8 -*-
#
#  Copyright (c) 2016 unfoldingWord
#  http://creativecommons.org/licenses/MIT/
#  See LICENSE file for details.
#
#  Contributors:
#  Richard Mahn <richard_mahn@wyciffeassociates.org>
#
#  Execute export_md_to_pdf.sh to run
#  Set WORKING_DIR, otherwise will be a temp dir
#  Set OUTPUT_DIR, otherwise will be the current dir

set -e # die if errors

: ${DEBUG:=false}

: ${MY_DIR:=$(cd $(dirname "$0") && pwd)} # Tools dir relative to this script
: ${OUTPUT_DIR:=$(pwd)}
: ${TEMPLATE:="$MY_DIR/toc_template.xsl"}
: ${TEMPLATE_ALL:="$MY_DIR/toc_template_all.xsl"}
: ${VERSION:=6}

if [[ -z $WORKING_DIR ]]; then
    WORKING_DIR=$(mktemp -d -t "export_md_to_pdf.XXXXXX")
    $DEBUG || trap 'popd > /dev/null; rm -rf "$WORKING_DIR"' EXIT SIGHUP SIGTERM
elif [[ ! -d $WORKING_DIR ]]; then
    mkdir -p "$WORKING_DIR"
fi

source "$MY_DIR/../general_tools/bible_books.sh"

echo $WORKING_DIR

# Change to own own temp dir but note our current dir so we can get back to it
pushd "$WORKING_DIR" > /dev/null

# If running in DEBUG mode, output information about every command being run
$DEBUG && set -x

repo=en-tq

mkdir -p "$OUTPUT_DIR/html"
cp "$MY_DIR/style.css" "$OUTPUT_DIR/html"
cp "$MY_DIR/header.html" "$OUTPUT_DIR/html"

echo $repo
if [ ! -e "$WORKING_DIR/$repo" ]; then
    cd "$WORKING_DIR"
    git clone "https://git.door43.org/Door43/$repo.git"
    cd "$repo"
else
    cd "$WORKING_DIR/$repo"
fi
git checkout tags/v${VERSION}

book_export () {
    book=$1

    "$MY_DIR/md_to_html_export.py" -i "$WORKING_DIR/$repo" -o "$OUTPUT_DIR/html" -v "$VERSION" -b $book

    headerfile="file://$OUTPUT_DIR/html/header.html"
    coverfile="file://$OUTPUT_DIR/html/cover.html"
    licensefile="file://$OUTPUT_DIR/html/license.html"
    bodyfile="file://$OUTPUT_DIR/html/$book.html"
    if [[ $book != "all" ]]; then
        outfile="$OUTPUT_DIR/pdf/tq-${BOOK_NUMBERS[$book]}-${book^^}-v${VERSION}.pdf"
    else
        outfile="$OUTPUT_DIR/pdf/tq-v${VERSION}.pdf"
    fi
    mkdir -p "$OUTPUT_DIR/pdf"
    echo "GENERATING $outfile"
    wkhtmltopdf --encoding utf-8 --outline-depth 3 -O portrait -L 15 -R 15 -T 15 -B 15  --header-html "$headerfile" --header-spacing 2 --footer-center '[page]' cover "$coverfile" cover "$licensefile" toc --disable-dotted-lines --enable-external-links --xsl-style-sheet "$TEMPLATE" "$bodyfile" "$outfile"
}

if [[ -z $1 ]]; then
  for book in "${!BOOK_NAMES[@]}"
  do
      book_export $book
  done
  book_export 'all'
else
  book_export $1
fi
  

