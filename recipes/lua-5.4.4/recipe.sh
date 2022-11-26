name=lua
ver=5.4.4
rev=1
desc='The Lua interpreter'
arch=x86_64
platform=mingw-w64

license=MIT
url=https://www.lua.org/

needs=()

srcs=("$url/ftp/lua-$ver.tar.gz")

# optional
buildneeds=()

# sha checksums, leave blank to skip
needsums=('') 

build(){
    cd lua-$ver/
    make mingw
}

package(){
    cd lua-$ver/
    make \
        TO_BIN="lua.exe luac.exe lua*.dll" \
        TO_LIB="liblua.a" \
        INSTALL_DATA='cp -d' \
        INSTALL_TOP=${PKGDST} \
        INSTALL_INC=${PKGDST}/include/lua5.1 \
        INSTALL_MAN=${PKGDST}/share/man/man1 \
        install
}