name=gmp
ver=5.0.1
rev=1
desc=''
arch=x86_64
platform=linux-musl

license=
url=https://ftp.gnu.org/gnu/gmp/

# Environment/Tools needed to run+build the tool
runenv=(x86_64-linux-musl-1.2.3)
# Tools only needed to build the package, not run it.
buildenv=()

conflicts=()

srcs=("$url/gmp-$ver.tar.gz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    export CC="$ENVDIR/bin/musl-gcc -static "
    cd $name-$ver/
    ./configure --enable-static --disable-shared --prefix=$PKGDST
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $name-$ver/
    make -j `nproc` install
}