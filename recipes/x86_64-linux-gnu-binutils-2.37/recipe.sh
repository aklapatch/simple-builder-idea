name=binutils
ver=2.37
rev=1
desc=''
arch=x86_64
platform=linux-gnu
license=
url=https://ftp.gnu.org/gnu/$name

# Environment/Tools needed to run or build the tool
runenv=()
# Tools only needed to build the package, not run it.
buildenv=()

conflicts=()

srcs=("$url/$name-$ver.tar.xz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/
    ./configure --prefix=$PKGDST --host x86_64-linux --build x86_64-linux 
}

check(){
    cd $name-$ver/
    make -j `nproc` check
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $name-$ver/
    make -j `nproc` install
}