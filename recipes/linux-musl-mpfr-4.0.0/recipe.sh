name=mpfr
ver=4.0.0
rev=1
desc=''
arch=x86_64
platform=linux-musl

license=
url=https://ftp.gnu.org/gnu/$name

# Environment/Tools needed to run+build the tool
runenv=(x86_64-linux-musl-1.2.3 x86_64-linux-musl-gmp-5.0.1)
# Tools only needed to build the package, not run it.
buildenv=()

conflicts=()

srcs=("$url/$name-$ver.tar.gz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/
    export CC=$ENVDIR/bin/musl-gcc
    export CFLAGS=" -static "
    ./configure --enable-static --disable-shared --prefix=$PKGDST --with-gmp=$ENVDIR
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $name-$ver/
    make -j `nproc` install
}