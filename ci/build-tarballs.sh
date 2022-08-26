#!/bin/bash

# A small script used for assembling release tarballs for both the `wizer`
# binary and the C API. This is executed with two arguments, mostly coming from
# the CI matrix.
#
# * The first argument is the name of the platform, used to name the release
# * The second argument is the "target", if present, currently only for
#   cross-compiles
#
# This expects the build to already be done and will assemble release artifacts
# in `dist/`

set -ex

platform=$1
target=$2

rm -rf tmp
mkdir tmp
mkdir -p dist

tag=dev
if [[ $GITHUB_REF == refs/tags/v* ]]; then
  tag=${GITHUB_REF:10}
fi

bin_pkgname=wizer-$tag-$platform

mkdir tmp/$bin_pkgname
cp LICENSE README.md tmp/$bin_pkgname

fmt=tar
if [ "$platform" = "x86_64-windows" ]; then
  cp target/release/wizer.exe tmp/$bin_pkgname
  fmt=zip
elif [ "$platform" = "x86_64-mingw" ]; then
  cp target/x86_64-pc-windows-gnu/release/wizer.exe tmp/$bin_pkgname
  fmt=zip
# elif [ "$platform" = "x86_64-macos" ]; then
#   # Postprocess the macOS dylib a bit to have a more reasonable `LC_ID_DYLIB`
#   # directive than the default one that comes out of the linker when typically
#   # doing `cargo build`. For more info see #984
#   install_name_tool -id "@rpath/libwizer.dylib" target/release/libwizer.dylib
#   cp target/release/wizer tmp/$bin_pkgname
# elif [ "$platform" = "aarch64-macos" ]; then
#   install_name_tool -id "@rpath/libwizer.dylib" target/aarch64-apple-darwin/release/libwizer.dylib
#   cp target/aarch64-apple-darwin/release/wizer tmp/$bin_pkgname
elif [ "$target" = "" ]; then
  cp target/release/wizer tmp/$bin_pkgname
else
  cp target/$target/release/wizer tmp/$bin_pkgname
fi


mktarball() {
  dir=$1
  if [ "$fmt" = "tar" ]; then
    # this is a bit wonky, but the goal is to use `xz` with threaded compression
    # to ideally get better performance with the `-T0` flag.
    tar -cvf - -C tmp $dir | xz -9 -T0 > dist/$dir.tar.xz
  else
    # Note that this runs on Windows, and it looks like GitHub Actions doesn't
    # have a `zip` tool there, so we use something else
    (cd tmp && 7z a ../dist/$dir.zip $dir/)
  fi
}

mktarball $bin_pkgname