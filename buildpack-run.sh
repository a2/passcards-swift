#! /usr/bin/env bash

wget http://curl.haxx.se/download/curl-7.54.0.tar.bz2
tar -xvjf curl-7.54.0.tar.bz2
cd curl-7.54.0
./configure  --disable-shared --with-nghttp2 --prefix=/app/.apt/usr
make
