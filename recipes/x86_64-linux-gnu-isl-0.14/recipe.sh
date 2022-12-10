name=isl
ver=0.14
rev=1
desc=''
arch=x86_64
platform=linux-musl

license=
url=https://isl.gforge.inria.fr/

# Environment/Tools needed to run+build the tool
runenv=($arch-$platform-1.2.3 $arch-$platform-gmp-5.0.1)
# Tools only needed to build the package, not run it.
buildenv=()

conflicts=()

srcs=("https://libisl.sourceforge.io/$name-$ver.tar.xz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/

    export CC="$ENVDIR/bin/musl-gcc -static "
    ./configure --prefix=$PKGDST --with-gmp-prefix=$ENVDIR --enable-static --disable-shared
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $name-$ver/
    make -j `nproc` install
}