name=zlib
ver=1.2.11
rev=1
desc=''
arch=x86_64
platform=linux-gnu

license=
# Borrow from ubuntu servers since I can't find the old versions of some things.
url=http://archive.ubuntu.com/ubuntu/pool/main/z/
# Environment/Tools needed to run+build the tool
runenv=()
# Tools only needed to build the package, not run it.
buildenv=()

conflicts=()

srcs=("$url/$name/${name}_$ver.dfsg.orig.tar.xz")

# source sha checksums, leave blank to skip
srcsums=('') 

configure(){
    cd $name-$ver/
    ./configure --prefix=$PKGDST --static
}

build(){
    cd $name-$ver/
    make -j `nproc`
}

package(){
    cd $name-$ver/
    make -j `nproc` install
}