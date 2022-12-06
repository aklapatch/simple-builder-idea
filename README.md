# simple-builder-idea
The goal is basically to be a `makepkg`-like package builder for Linux-like systems. The goal is to use bash to define a recipe, then build it and it's dependiencies

## Ideas
- (From yocto): output sets and environment variables as a script that the user can run later
- (From Nix): create a build environment from symlinked packages
- (From Nix): have a binary store where the individual package is stored with dependencies symlinked if necessary.
- (from makepkg): Have bash functions such as 
    - pre_fetch()
    - configure()
    - build()
    - package()
- (from makepkg): have a list of sources and dependencies
- have a local binary cache folder that all the sources are stored in. Allow the user to provide other folders to pull files from
- allow sources to also be files
- Allow configuration (like with ~/.config/sbi/sbi.sh)
- (if necessary) bootstrap a statically linked compiler if necessary

## TODO:
- implement env
    - Add PATH entries
    - bootstrap gcc
        - mingw
            - binutils
            - crt
            - isl
            - zlib
            - zstd
            - autotools
            - mpfr
            - mpc
            - bash?
            - make
- Implement checksum adding through the tool and checksum checking
- add xxhsum.
- Add caching for config/build/package, etc.

## recipe format
```bash
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
```