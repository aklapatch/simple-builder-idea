name=gcc
ver=4.7.4
rev=1
desc=''
arch=x86_64
platform=linux-gnu

license=
url=https://ftp.gnu.org/gnu/$name

# Tools only needed to build the package, not run it.
buildenv=($arch-$platform-gmp-5.0.1 $arch-$platform-mpfr-4.0.0 $arch-$platform-mpc-1.1.0 $arch-$platform-zlib-1.2.11 $arch-$platform-isl-0.14 $arch-$platform-binutils-2.37)
# Environment/Tools needed to run+build the tool
runenv=()

conflicts=()

srcs=("$url/$name-$ver/$name-$ver.tar.gz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/
    ./configure \
        --prefix=$PKGDST \
        CFLAGS="-pipe -static" \
        --enable-static \
        --disable-lto \
        --disable-multilib \
        --disable-multiarch \
        --disable-libmudflap \
        --disable-libssp \
        --disable-nls \
        --disable-shared \
        --with-mpfr=$ENVDIR \
        --with-mpc=$ENVDIR \
        --with-gmp=$ENVDIR \
        --with-isl=$ENVDIR \
        --enable-languages=c,c++ \
        --disable-libgomp \
        --disable-build-with-cxx \
        --disable-build-poststage1-with-cxx \
        --host x86_64-linux --build x86_64-linux \
        --disable-host-shared \
        --with-boot-ldflags=-static --with-stage1-ldflags=-static
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $_name-$ver/
    make -j `nproc` install
}