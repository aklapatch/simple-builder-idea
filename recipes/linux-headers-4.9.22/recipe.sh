name=linux-headers
ver=4.9.335
rev=1
desc=''
arch=x86_64
platform=linux

license=
url=https://cdn.kernel.org/pub/linux/kernel/v4.x

# Environment/Tools needed to run+build the tool
runenv=()
# Tools only needed to build the package, not run it.
buildenv=()

conflicts=()

srcs=("$url/linux-$ver.tar.xz")

# source sha checksums, leave blank to skip
srcsums=('') 

build(){
    cd linux-$ver/
    make mrproper
    make ARCH=$arch headers_check
}

package(){
    cd linux-$ver/
    make ARCH=$arch INSTALL_HDR_PATH=$PKGDST headers_install
}