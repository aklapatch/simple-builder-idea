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

## recipe format
```bash
#!/bin/bash
pkgname="src_name"
pkgver="0.1.1"
pkgrev='1'
pkgdesc='An example package'
# put platform here, such as Linux, mingw-etc
pkgplatform=('platform1' 'platform2')
license='None'
url='https://example-url'

# Pipes aren't common in Unix file paths, so use them as a separator
needs=("file|dep-0.2.tar.gz" "git|git-url" "regular-src-0.3.3")

# optional
buildneeds=()

# sha checksums, leave blank to skip
needsums=('' '' '')

pre_fetch(){
    # do stuff before fetching data
}

prep(){
    # patch sources if necessary
}

configure(){
    # configure package before building
}

build(){
    # run the build command
}

package(){
    # install the package into the binary cache dir.
}
```