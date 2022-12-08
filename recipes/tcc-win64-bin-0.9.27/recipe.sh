_name=tcc
name=$_name-bin
ver=0.9.27
rev=1
desc=''
arch=x86_64
platform=win64

license=
url=http://download.savannah.gnu.org/releases/tinycc/

# Tools only needed to build the package, not run it.
buildenv=()
# Environment/Tools needed to run+build the tool
runenv=()

conflicts=()

srcs=("$url/$_name-$ver-win64-bin.zip")

# source sha checksums, leave blank to skip
srcsums=('') 

package(){
    mv tcc/* $PKGDST
}