name=musl
_ver=1.2.3
ver=$_ver-tcc
rev=1
desc=''
arch=x86_64
platform=win64

license=
url=https://musl.libc.org/releases/

# Tools only needed to build the package, not run it.
buildenv=(win64-x86_64-tcc-bin-0.9.27)
# Environment/Tools needed to run+build the tool
runenv=()

conflicts=()

srcs=("$url/$name-$_ver.tar.gz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$_ver/
    export CC=$ENVDIR/i386-win32-tcc
    export CFLAGS="-m32"
    ./configure --prefix=$PKGDST --enable-static --target=x86_64
}

build(){
    cd $name-$_ver/
    make -j `nproc`
}

package(){
    cd $name-$_ver/
    make -j `nproc` install
}