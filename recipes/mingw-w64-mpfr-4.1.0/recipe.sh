name=mpfr
ver=4.1.0
rev=1
desc=''
arch=x86_64
platform=mingw-w64

license=
url=https://ftp.gnu.org/gnu/$name

# Environment/Tools needed to run+build the tool
env=()
# Tools only needed to build the package, not run it.
buildenv=()

conflicts=()

srcs=("$url/$name-$ver.tar.xz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
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