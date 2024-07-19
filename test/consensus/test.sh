#!/bin/bash

# Fail on error
set -e

haxe test-cpp.hxml
./bin/cpp/TestMain-debug.exe

#haxe test-hl.hxml
#hl ./bin/hl/TestMain