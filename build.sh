#!/bin/bash
set -eux
set echo off
# tarball csproj files, sln files, and NuGet.config
find . \( -name "*.csproj" -o -name "*.sln" -o -name "NuGet.config" \) -print0 | tar -cvf projectfiles.tar --null -T -

docker build --tag efdynamic:7.0.0-dev1239 --build-arg api_key=a10cde9f-36d5-35bc-90d0-d60ba7103f2f --build-arg version="7.0.0-dev1239" .

rm projectfiles.tar