#!/bin/bash

cmake -S . -B build/lin64/gcc/release -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=install

echo Configuration completed


