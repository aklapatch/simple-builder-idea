name=gcc
ver=6.5.0
rev=1
desc=''
arch=x86_64
platform=linux-gnu

license=
base_url=https://ftp.gnu.org/gnu/
url=$base_url/$name

# Tools only needed to build the package, not run it.
buildenv=($arch-$platform-binutils-2.37)
# Environment/Tools needed to run+build the tool
runenv=()

conflicts=()

# Get mpfr, mpc and gmp too
srcs=("$url/$name-$ver/$name-$ver.tar.gz" "$base_url/gmp/gmp-6.1.1.tar.bz2" "$base_url/mpfr/mpfr-3.1.4.tar.gz" "$base_url/mpc/mpc-1.0.3.tar.gz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    # move the libs into the gcc dir
    mv -v mpfr-3.1.4 $name-$ver/mpfr
    mv -v gmp-6.1.1 $name-$ver/gmp
    mv -v mpc-1.0.3 $name-$ver/mpc

    mkdir -v gcc-build
    cd gcc-build
    ../$name-$ver/configure \
        CFLAGS="-fPIC -pipe" \
        --prefix=$PKGDST \
        --disable-nls \
        --disable-shared \
        --without-headers \
        --with-newlib \
        --disable-decimal-float \
        --disable-libgomp \
        --disable-libmudflap \
        --disable-libssp \
        --disable-libatomic \
        --disable-libquadmath \
        --disable-threads \
        --enable-languages=c \
        --disable-multilib \
        --host=x86_64-linux-gnu \
        --build=x86_64-linux-gnu \
        --target=x86_64-linux-gnu
}

build(){
    cd gcc-build
    make all-gcc all-target-libgcc
}

package(){
    cd gcc-build
    make -j 2 install-gcc install-target-libgcc
}