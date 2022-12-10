name=gcc
ver=6.5.0
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
        --with-mpfr=$ENVDIR \
        --with-mpc=$ENVDIR \
        --with-gmp=$ENVDIR \
        --with-isl=$ENVDIR \
        --host=x86_64-linux --build=x86_64-linux --target=x86_64-linux \
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $_name-$ver/
    make -j `nproc` install
}