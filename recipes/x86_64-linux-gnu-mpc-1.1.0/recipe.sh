name=mpc
ver=1.1.0
rev=1
desc=''
arch=x86_64
platform=linux-gnu

license=
url=https://ftp.gnu.org/gnu/$name

# Environment/Tools needed to run+build the tool
runenv=($arch-$platform-gmp-5.0.1  $arch-$platform-mpfr-4.0.0)
# Tools only needed to build the package, not run it.
buildenv=()

conflicts=()

srcs=("$url/$name-$ver.tar.gz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/
    ./configure --enable-static --disable-shared --prefix=$PKGDST --with-gmp=$ENVDIR --with-mpfr=$ENVDIR
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $name-$ver/
    make -j `nproc` install
}