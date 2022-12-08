name=musl
ver=1.2.3
rev=1
desc=''
arch=x86_64
platform=mingw-w64

license=
url=https://musl.libc.org/releases/

# Tools only needed to build the package, not run it.
buildenv=()
# Environment/Tools needed to run+build the tool
runenv=()

conflicts=()

srcs=("$url/$name-$ver.tar.gz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/
    ./configure CC=gcc --prefix=$PKGDST --enable-static --target=x86_64
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $name-$ver/
    make -j `nproc` install
}