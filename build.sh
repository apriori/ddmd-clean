#!/bin/sh
# I only compile for unittesting. Main doesn't do anything yet anyway.
# You can see how primitive this buildscript is!

rdmd --main -unittest -m32 ./dmd/Token
