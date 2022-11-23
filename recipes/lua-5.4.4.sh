pkgname=lua
pkgver=5.4.4
pkgrev=1
pkgdesc='The Lua interpreter'

license=MIT
url=https://www.lua.org/ftp/lua-5.4.4.tar.gz

# Pipes aren't common in Unix file paths, so use them as a separator
needs=()

srcs=("lua.tar.gz|$url")

# optional
buildneeds=()

# sha checksums, leave blank to skip
needsums=('') 

build(){
    cd lua-$pkgver/
    make mingw
}

package(){
    cd lua-$pkgver/
    make \
        TO_BIN="lua.exe luac.exe lua*.dll" \
        TO_LIB="liblua.a" \
        INSTALL_DATA='cp -d' \
        INSTALL_TOP=${PKGDST} \
        INSTALL_INC=${PKGDST}/include/lua5.1 \
        INSTALL_MAN=${PKGDST}/share/man/man1 \
        install
}