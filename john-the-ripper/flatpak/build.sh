#!/bin/bash

# Required defines
TEST=';full;extra;' # Controls how the test will happen
arch=$(uname -m)
JTR_BIN='/app/bin/john'
JTR_CL="$JTR_BIN"

# Build options (system wide, disable checks, etc.)
SYSTEM_WIDE='--with-systemwide'
X86_REGULAR="--disable-native-tests $SYSTEM_WIDE"
X86_NO_OPENMP="--disable-native-tests $SYSTEM_WIDE --disable-openmp"

OTHER_REGULAR="$SYSTEM_WIDE"
OTHER_NO_OPENMP="$SYSTEM_WIDE --disable-openmp"

# Show environmen information
source ../show_info.sh

# Build helper
source ../run_build.sh

if [[ -z "$TASK" ]]; then
    # Set package version
    git rev-parse --short HEAD 2>/dev/null > My_VERSION.TXT

    # The script that computes the package version
    source ../package_version.sh

    echo ""
    echo "---------------------------- BUILDING -----------------------------"

    if [[ "$arch" == "x86_64" ]]; then
        # CPU (OMP and extensions fallback)
        ./configure $X86_NO_OPENMP CPPFLAGS="-D_BOXED" && do_build ../run/john-sse2-non-omp
        ./configure $X86_REGULAR   CPPFLAGS="-D_BOXED -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-sse2-non-omp\\\"\"" && do_build ../run/john-sse2
        ./configure $X86_NO_OPENMP CPPFLAGS="-D_BOXED -msse4.1" && do_build ../run/john-sse4-non-omp
        ./configure $X86_REGULAR   CPPFLAGS="-D_BOXED -msse4.1 -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-sse4-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-sse2\\\"\"" && do_build ../run/john-sse4
        ./configure $X86_NO_OPENMP CPPFLAGS="-D_BOXED -mavx" && do_build ../run/john-avx-non-omp
        ./configure $X86_REGULAR   CPPFLAGS="-D_BOXED -mavx -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-avx-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-sse4\\\"\"" && do_build ../run/john-avx
        ./configure $X86_NO_OPENMP CPPFLAGS="-D_BOXED -mxop" && do_build ../run/john-xop-non-omp
        ./configure $X86_REGULAR   CPPFLAGS="-D_BOXED -mxop -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-xop-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-avx\\\"\"" && do_build ../run/john-xop
        ./configure $X86_NO_OPENMP CPPFLAGS="-D_BOXED -mavx2" && do_build ../run/john-non-omp
        ./configure $X86_REGULAR   CPPFLAGS="-D_BOXED -mavx2 -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-xop\\\"\"" && do_build

        # Install OpenCL kernel code
        make kernel-copy

    else
        # Non X86 CPU
        ./configure $OTHER_NO_OPENMP CPPFLAGS="-D_BOXED" && do_build ../run/john-non-omp
        ./configure $OTHER_REGULAR   CPPFLAGS="-D_BOXED -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-non-omp\\\"\"" && do_build
    fi

elif [[ "$TASK" == "test" ]]; then
    # "---------------------------- TESTING -----------------------------"

    # Adjust the testing environment, import and run some testing
    source ../disable_formats.sh

    source ../run_tests.sh
fi
source ../clean_package.sh
