#!/bin/sh
docker build -t vdemeester-site .
docker run -ti --rm -v $PWD:/usr/src/app -p 4000:4000 vdemeester-site
