#!/bin/bash

set -eou pipefail

cd nginx
./build.sh

cd ../webapp
./build.sh

cd ..
