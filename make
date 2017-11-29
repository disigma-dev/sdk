#!/bin/bash

if [[ $# == 0 ]]; then
    (${BASH_SOURCE[0]} x86-linux x64-linux arm-android x86-android arm-ios x86-ios x86-macos)
    exit
fi

until [[ $# < 2 ]]; do
    (${BASH_SOURCE[0]} "$1") || exit 1
    shift
done

##############################################################################
#                              variables                                     #
##############################################################################
target="$1"
system=$(uname -s | tr A-Z a-z)
project="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
intermediate="$project/.build/$target"
link="$(readlink "${BASH_SOURCE[0]}")"
[[ "x$link" == "x" ]] && link="${BASH_SOURCE[0]}" || link="$project/$link"
sdk="$(cd "$(dirname "$link")" && pwd)"
sysroot="$sdk/sysroots/$target"
toolchain="$sdk/toolchains/clang-$system"
cctools="$sdk/toolchains/cctools-$system"
binutils="$sdk/toolchains/binutils-$system"
ndk="$sdk/toolchains/$target-ndk-$system"
workspace="$(cd "$sdk/.." && pwd)"
archive="$workspace/archive"
frameworks="$archive/$target"

##############################################################################
#                                custom                                      #
# names=(curl)
# versions=(7.49.0)
# config="--disable-debug --enable-optimize"
# action=autobuild
# separate=yes
# custom_cflags="$CFLAGS -O3"
# custom_cxxflags="$CXXFLAGS -O3"
# custom_ldflags="$LDFLAGS"
# custom_libs="$lIBS"
# prebuild() {
#    [[ "$target" == *"-ios" ]] && libs="$libs -lresolv"
#    [[ "$target" == "arm-ios" ]] && cflags="$cflags -miphoneos-version-min=8.0"
#    [[ "$target" == "x86-ios" ]] && cflags="$cflags -mios-simulator-version-min=8.0"
#    [[ "$target" == "x86-macos" ]] && cflags="$cflags -mmacosx-version-min=10.7"
#    ln -svf $frameworks/z-1.2.8/headers/* . &&
#    ln -svf $frameworks/z-1.2.8/libraries/libz.a &&
#    ln -svf $frameworks/crypto-1.0.2x/headers/* . &&
#    ln -svf $frameworks/crypto-1.0.2x/libraries/libcrypto.a &&
#    ln -svf $frameworks/ssl-1.0.2x/headers/* . &&
#    ln -svf $frameworks/ssl-1.0.2x/libraries/libssl.a
#}
##############################################################################
source "$project/rules.make" || exit 1
eval skip=\${no_${target/-/_}}
[[ "x$skip" == "xyes" ]] && exit 0

mccflags="$ccflags"
mcflags="$cflags"
mcxxflags="$cxxflags"
mcppflags="$cppflags"
masflags="$asflags"
mldflags="$ldflags"
mlibs="$libs"
mconfig="$config"
[[ "x$prefix" == "x" ]] && prefix=targets

##############################################################################
#                              functions                                     #
##############################################################################

hasfunction() {
    declare -f -F $1 > /dev/null
    return $?
}

cmakebuild() {
    [[ "x$sourceroot" != "x" ]] && root="$sourceroot" || root="$project"
    "$sdk/bin/$target-cmakebuild" "$root" $config &&
    if [[ "x$nomake" != "xyes" ]]; then
        make -j8 install
    fi
}

autobuild() {
    [[ "x$sourceroot" != "x" ]] && root="$sourceroot" || root="$project"
    if [[ "x$noreconf" != "xyes" ]]; then
        (cd "$root" && autoreconf -isf) || [[ "x$optconf" == "xyes" ]]
    fi &&
    "$sdk/bin/$target-autobuild" "$root/configure" $config &&
    if [[ "x$nomake" != "xyes" ]]; then
        make -j8 install
    fi
}

onprebuild() {
    rm -rvf "$intermediate/$1" &&
    mkdir -vp "$intermediate/$1" &&
    cd "$intermediate/$1" &&
    if hasfunction prebuild; then
        prebuild $1
    fi
}

oninstall() {
    for (( i=0; i<${#names[@]}; i++ )) ; do
        name=${names[$i]}
        version=${versions[$i]}
        output="$frameworks/$name-$version"
        revision=$(cd "$project" && git rev-parse --short --verify HEAD)
        date=$(date +%Y%m%d)
        rm -rvf "$output" &&
        mkdir -vp "$output/headers" &&
        mkdir -vp "$output/libraries" &&
        if [[ "x$target" == *"os" && "x$separate" == "xyes" ]]; then
            "$sdk/bin/$target-lipo" -create "$prefix/lib/lib${name}.a" "../32/$prefix/lib/lib${name}.a" -output "$prefix/lib/lib${name}.a"
        fi &&
        echo $version.$date$revision > "$output/VERSION" &&
        cp -avf "$project/${name}_dependency" "$output/dependency" &&
        cp -avf "$prefix/include/"* "$output/headers/" &&
        cp -avf "$prefix/lib/lib${name}.a" "$output/libraries/lib${name}_debug.a" &&
        cp -avf "$prefix/lib/lib${name}.a" "$output/libraries/lib${name}.a" &&
        if hasfunction postinstall; then
            postinstall ${names[$i]} ${versions[$i]}
        fi
    done
}

onpostbuild() {
    if hasfunction postbuild; then
        postbuild $1
    fi &&
    if [[ "x$1" != "x32" && "x$noinstall" != "xyes" ]]; then
        oninstall
    fi
}

onbuild() {
    ccflags="$mccflags"
    cflags="$mcflags"
    cxxflags="$mcxxflags"
    cppflags="$mcppflags"
    asflags="$masflags"
    ldflags="$mldflags"
    libs="$mlibs"
    config="$mconfig"
    onprebuild $1 &&
    BITS="$1" NOCC="$nocc" NOCXX="$nocxx" NOCPP="$nocpp" NOCXXCPP="$nocxxcpp" NOAR="$noar" NOLD="$nold" NONM="$nonm" NOAS="$noas" \
    NORANLIB="$noranlib" NOSTRIP="$nostrip" NOOBJCOPY="$noobjcopy" NOSYSROOT="$nosysroot" NOTARGET="$notarget" NOHOST="$nohost" \
    CFLAGS="$cflags $ccflags" CXXFLAGS="$cxxflags $ccflags" CPPFLAGS="$cppflags" ASFLAGS="$asflags" LDFLAGS="$ldflags" LIBS="$libs" $action &&
    onpostbuild $1
}

onprocess() {
    if [[ "x$target" == *"os" && "x$separate" == "xyes" ]]; then
        (onbuild 32) && (onbuild 64)
    else
        (onbuild)
    fi
}

##############################################################################
#                               process                                      #
##############################################################################
case "$target" in
    x86-linux|x64-linux|arm-android|x86-android|arm-ios|x86-ios|x86-macos)
        onprocess || exit 1
        ;;
    *)
        echo "invalid target: $target"
        exit 1
        ;;
esac
