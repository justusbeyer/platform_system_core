# Copyright © 2010, 2011
#	Thorsten Glaser <t.glaser@tarent.de>
# This file is provided under the same terms as mksh.
#-
# Helper script to let src/Build.sh generate Makefrag.inc
# which we in turn use in the manual creation of Android.mk
#
# This script is supposed to be run from/inside AOSP by the
# porter of mksh to Android (and only manually).

if test x"$1" = x"-t"; then
	# test compilation
	args=-r
	mkmfmode=1
else
	# prepare for AOSP
	args=-M
	mkmfmode=0
fi

cd "$(dirname "$0")"
srcdir=$(pwd)
rm -rf tmp
mkdir tmp
cd ../../..
aospdir=$(pwd)
cd $srcdir/tmp

addvar() {
	_vn=$1; shift

	eval $_vn=\"\$$_vn '$*"'
}

CFLAGS=
CPPFLAGS=
LDFLAGS=
LIBS=

# The definitions below were generated by examining the
# output of the following command:
# make showcommands out/target/product/generic/system/bin/mksh 2>&1 | tee log
#
# They are only used to let Build.sh find the compiler, header
# files, linker and libraries to generate Makefrag.inc (similar
# to what GNU autotools’ configure scripts do), and never used
# during the real build process. We need this to port mksh to
# the Android platform and it is crucial these are as close as
# possible to the values used later. (You also must example the
# results gathered from Makefrag.inc to see they are the same
# across all Android platforms, or add appropriate ifdefs.)
# Since we no longer use the NDK, the AOSP has to have been
# built before using this script (targetting generic/emulator).

CC=$aospdir/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/arm-eabi-gcc
addvar CPPFLAGS -I$aospdir/system/core/include \
    -I$aospdir/hardware/libhardware/include \
    -I$aospdir/hardware/libhardware_legacy/include \
    -I$aospdir/hardware/ril/include \
    -I$aospdir/dalvik/libnativehelper/include \
    -I$aospdir/frameworks/base/include \
    -I$aospdir/frameworks/base/opengl/include \
    -I$aospdir/frameworks/base/native/include \
    -I$aospdir/external/skia/include \
    -I$aospdir/out/target/product/generic/obj/include \
    -I$aospdir/bionic/libc/arch-arm/include \
    -I$aospdir/bionic/libc/include \
    -I$aospdir/bionic/libstdc++/include \
    -I$aospdir/bionic/libc/kernel/common \
    -I$aospdir/bionic/libc/kernel/arch-arm \
    -I$aospdir/bionic/libm/include \
    -I$aospdir/bionic/libm/include/arch/arm \
    -I$aospdir/bionic/libthread_db/include \
    -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__ \
    -include $aospdir/system/core/include/arch/linux-arm/AndroidConfig.h \
    -I$aospdir/system/core/include/arch/linux-arm/ \
    -DANDROID -DNDEBUG -UDEBUG
addvar CFLAGS -fno-exceptions -Wno-multichar -msoft-float -fpic \
    -ffunction-sections -funwind-tables -fstack-protector -Wa,--noexecstack \
    -Werror=format-security -fno-short-enums -march=armv5te -mtune=xscale \
    -Wno-psabi -mthumb-interwork -fmessage-length=0 -W -Wall -Wno-unused \
    -Winit-self -Wpointer-arith -Werror=return-type -Werror=non-virtual-dtor \
    -Werror=address -Werror=sequence-point -Wstrict-aliasing=2 \
    -finline-functions -fno-inline-functions-called-once -fgcse-after-reload \
    -frerun-cse-after-loop -frename-registers -mthumb -Os \
    -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64
addvar LDFLAGS -nostdlib -Bdynamic -Wl,-T,$aospdir/build/core/armelf.x \
    -Wl,-dynamic-linker,/system/bin/linker -Wl,--gc-sections \
    -Wl,-z,nocopyreloc -Wl,-z,noexecstack -Wl,--no-undefined \
    $aospdir/out/target/product/generic/obj/lib/crtbegin_dynamic.o
addvar LIBS -L$aospdir/out/target/product/generic/obj/lib \
    -Wl,-rpath-link=$aospdir/out/target/product/generic/obj/lib -lc \
    $aospdir/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/../lib/gcc/arm-eabi/4.4.0/interwork/libgcc.a \
    $aospdir/out/target/product/generic/obj/lib/crtend_android.o


### Flags used by test builds
if test $mkmfmode = 1; then
	addvar CPPFLAGS '-DMKSH_DEFAULT_EXECSHELL=\"/system/bin/sh\"'
	addvar CPPFLAGS '-DMKSH_DEFAULT_TMPDIR=\"/sqlite_stmt_journals\"'
	addvar CPPFLAGS '-DMKSHRC_PATH=\"/system/etc/mkshrc\"'
fi


### Override flags
# We don’t even *support* UTF-8 by default ☹
addvar CPPFLAGS -DMKSH_ASSUME_UTF8=0
# No getpwnam() calls (affects "cd ~username/" only)
addvar CPPFLAGS -DMKSH_NOPWNAM
# Compile an extra small mksh (optional)
#addvar CPPFLAGS -DMKSH_SMALL
# Leave out the ulimit builtin
#addvar CPPFLAGS -DMKSH_NO_LIMITS

# Set target platform
TARGET_OS=Android
# Building with -std=c99 or -std=gnu99 clashes with Bionic headers
HAVE_CAN_STDG99=0
HAVE_CAN_STDC99=0
export HAVE_CAN_STDG99 HAVE_CAN_STDC99

# Android-x86 does not have helper functions for ProPolice SSP
# and AOSP adds the flags by itself (same for warning flags)
HAVE_CAN_FNOSTRICTALIASING=0
HAVE_CAN_FSTACKPROTECTORALL=0
HAVE_CAN_WALL=0
export HAVE_CAN_FNOSTRICTALIASING HAVE_CAN_FSTACKPROTECTORALL HAVE_CAN_WALL

# even the idea of persistent history on a phone is funny
HAVE_PERSISTENT_HISTORY=0; export HAVE_PERSISTENT_HISTORY

# ... and run it!
export CC CPPFLAGS CFLAGS LDFLAGS LIBS TARGET_OS
sh ../src/Build.sh $args
rv=$?
test x"$args" = x"-r" && exit $rv
test x0 = x"$rv" && mv -f Makefrag.inc ../
cd ..
rm -rf tmp
exit $rv