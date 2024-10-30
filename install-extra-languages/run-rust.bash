#!/bin/bash

DEST="$1"
shift
MEMLIMIT="$1"
shift

# first you need to ./dj_make_chroot -i rustc

mkdir rust_tmp_dir
export TMPDIR=rust_tmp_dir
found_main="false"
for rustfile in "$@"; do
    if grep -q 'fn main' "$rustfile"; then
        rustc -C opt-level=3 -o "$DEST" "$rustfile"
        found_main="true"
        echo "rust file '$rustfile' contains main function"
        break
    fi
done
rmdir rust_tmp_dir
if [[ "$found_main" == "true" ]]; then
    exit 0
else
    echo "no main function found in rust files: $@"
    exit 1
fi
