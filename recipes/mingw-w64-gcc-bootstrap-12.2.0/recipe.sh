name=gcc
ver=12.2.0
rev=1
desc=''
arch=x86_64
platform=mingw-w64

license=
url=https://ftp.gnu.org/gnu/$name

# Tools only needed to build the package, not run it.
buildenv=('mingw-w64-x86_64-gmp-6.2.1')
# Environment/Tools needed to run+build the tool
runenv=()

conflicts=()

srcs=("$url/$name-$ver/$name-$ver.tar.xz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/
    ./configure --prefix=$PKGDST --enable-static --disable-shared
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $name-$ver/
    make -j `nproc` install
}