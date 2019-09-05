#!/bin/bash

WORKING_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" > /dev/null 2>&1 && pwd -P )"
cd $WORKING_DIR;

./scripts/generate_pac.py
./scripts/generate_surge.py
./scripts/generate_clash.py
