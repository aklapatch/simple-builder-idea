name=tcc
ver=0.9.27
rev=1
desc=''
arch=x86_64
platform=mingw-w64

license=
url=http://download.savannah.gnu.org/releases/tinycc/

# Tools only needed to build the package, not run it.
buildenv=()
# Environment/Tools needed to run+build the tool
runenv=()

conflicts=()

srcs=("$url/$name-$ver.tar.bz2")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/
    ./configure --prefix=$PKGDST --enable-static
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

check(){
    cd $name-$ver/
    #make -j `nproc` test
}


package(){
    cd $name-$ver/
    make -j `nproc` install
}