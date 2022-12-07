name=mpfr
_ver=4.1.0
ver=$_ver-tcc
rev=1
desc=''
arch=x86_64
platform=mingw-w64

license=
url=https://ftp.gnu.org/gnu/$name

# Environment/Tools needed to run+build the tool
env=()
# Tools only needed to build the package, not run it.
buildenv=(mingw-w64-x86_64-tcc-0.9.27)

conflicts=()

srcs=("$url/$name-$_ver.tar.xz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$_ver/
    export CC=$ENVDIR/tcc
    ./configure --enable-static --disable-shared --prefix=$PKGDST
}

build(){
    cd $name-$_ver/
    make -j `nproc`
}

check(){
    cd $name-$_ver/
    make -j `nproc` test
}

package(){
    cd $name-$_ver/
    make -j `nproc` install
}