_name=gcc
name=gcc-bootstrap
ver=12.2.0
rev=1
desc=''
arch=x86_64
platform=mingw-w64

license=
url=https://ftp.gnu.org/gnu/$_name

# Tools only needed to build the package, not run it.
buildenv=('mingw-w64-x86_64-gmp-6.2.1' 'mingw-w64-x86_64-mpfr-4.1.0' 'mingw-w64-x86_64-isl-0.24' 'mingw-w64-x86_64-mpc-1.2.1')
# Environment/Tools needed to run+build the tool
runenv=()

conflicts=()

srcs=("$url/$_name-$ver/$_name-$ver.tar.xz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $_name-$ver/
    ./configure \
        --prefix=$PKGDST \
        --enable-static \
        --disable-shared \
        --with-mpfr=$ENVDIR \
        --with-gmp=$ENVDIR \
        --with-isl=$ENVDIR \
        --with-static-standard-libraries
}

build(){
    cd $_name-$ver/
    make -j `nproc`
}

package(){
    cd $_name-$ver/
    make -j `nproc` install
}