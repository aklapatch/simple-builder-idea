#!/bin/bash
set -euo pipefail

# TODO: add m4 as a need for gmp 5.0.1
# TODO: add m4 and autotools and make for this project

# Make the binary cache/src dir and the store dir
src_cache_dir=$HOME/.sbi/src-cache/
bin_store_dir=$HOME/.sbi/bin-store/
# When a build finishes, put a symlink in here to indicate that it's a ready to use package
pkg_link_dir=$HOME/.sbi/bin-store/pkg-link-dir
recipe_dir=$HOME/.sbi/recipes/
build_dir=$HOME/.sbi/builds/
config_file=$HOME/.sbi/sbi_cfg.sh

# TODO: change the design to have a pkg folder where a symlink will get added when a build finishes
# The install dir will probably still be the bin_store_dir

mkdir -p $src_cache_dir
mkdir -p $bin_store_dir
mkdir -p $pkg_link_dir
mkdir -p $recipe_dir
mkdir -p $build_dir

clean_builds(){
    echo "Cleaning builds from $build_dir"
    rm -rf $build_dir
    echo "Finished cleaning builds"
}

# TODO: implement dependency checking + removal
drop_pkg(){
    local delete_me=$pkg_link_dir/${1?Please provide a package to drop!}
    if [ -d $delete_me ]; then
        echo "Removing $1"
        # remove the source and dest of the symlink
        rm -rf `realpath $delete_me` $delete_me
        echo "Removed $1"
    else
        echo "$1 Not installed!"
        exit 1
    fi
}

print_added(){
    # Print everything in the bin-store
    cd $pkg_link_dir
    find . -maxdepth 1 -print
}

import_recipe(){
    # Source the recipe, and add it to the built-in recipe dir
    local recipe="${1?Please provide a recipe path to import}"
    if ! [ -f $recipe ]; then
        echo "ERROR: $recipe is not a file we can copy"
        exit 1
    fi

    # Get the recipe name and make a folder for it.
    source $recipe
    local recipe_name="$arch-$platform-$name-$ver"

    # Ask if we should replace a detected recipe
    local old_recipe=$recipe_dir/$recipe_name/recipe.sh
    if [ -f $old_recipe ]; then
        while true 
        do
            read -p "Found old package version at $old_recipe. Replace? (y/n): " -n 1 replace_answer
            echo
            case "$replace_answer" in 
                n|no)
                    bold_echo Halting
                    # Just stop
                    exit 0;;
                y|yes)
                    break;;
                *)
                    echo "Please input y/n/yes/no"
            esac
        done
    fi

    # TODO: add local file sources from recipe to this dir too
    # TODO: delete all files in the old recipe dir
    install -D $recipe $old_recipe
    bold_echo "Copied recipe"
}

# Dump command as a script, then run it.
log_run_script(){
    local log=${1?Please provide a log name}
    local script=${2?Please provide a script name}
    local cmd=${3?Please provide a command}

    dump_script $script "$cmd"

    # Run the script we just dumped
    log_run $log "$script"
}

# dump the function/command to a script
dump_script(){
    local script_file=${1?Please provide a script filename}
    local cmd=${2?Please provide a command to log}
    # TODO: add CC, CXX and other environment variables.
    local script_str='#!/bin/bash\nset -euo pipefail\ncd $(realpath $(dirname $0))/..'

    script_str+="\n$cmd"
    
    echo -e "$script_str" > $script_file
}

# Log the command, and dump the command to a script file to replicate it later.
log_dump_run(){
    local base=${1?Please provide a log/script base name}
    local log_file=$base.txt
    local cmd_str="${2?Please provide a command}"
    local script_str='#!/bin/bash\nset -euo pipefail\ncd $(realpath $(dirname $0))/..'
    echo -e "$script_str\n$cmd_str"  > $base.sh
    echo "$2" > $log_file
    eval "$2" | tee -a $log_file
}

# log the command and run it
log_run(){
    # 1 is log file 2 is cmd
    local log_file=${1?Please provide a log name}
    echo "${2?Please provide a command}" > "$log_file"
    bash "$2" | tee -a $log_file
}

bold_echo(){
    echo -e "\033[1m${1}\033[0m"
}

pkg_is_built(){
    if [ -d $pkg_link_dir/${1?Please provide a package name to check} ]; then
        return 0
    fi
    return 1
}

build_recipe(){
    local recipe_to_build="${1?This function needs a recipe to build}"
    local return_if_built="${2}"

    # Check if this is a folder in the bin-store, if it is, then don't do a bunch of things
    if [[ -n "$return_if_built" ]] && pkg_is_built $recipe_to_build; then
        echo "$recipe_to_build is built"
        return
    elif [ -f $recipe_dir/$recipe_to_build/recipe.sh ]; then
        echo "Using stored recipe"
        recipe_to_build=$recipe_dir/$recipe_to_build/recipe.sh
    elif [ -f $recipe_to_build ]; then
        echo "Using recipe file"
    else
        echo "ERROR: $recipe_to_build is not a file or a stored recipe"
    fi

    recipe_to_build=`realpath $recipe_to_build`

    source $recipe_to_build
    local recipe_name="$arch-$platform-$name-$ver"
    local build_name="$recipe_name-$rev"

    # Ask if we should replace a detected recipe
    local replacing=""
    local pkg_backup_dir=$bin_store_dir/$recipe_name-backup/
    if pkg_is_built $recipe_name; then
        while true 
        do
            read -p "Found old package version at $recipe_name . Replace? (y/n): " -n 1 replace_answer
            echo
            case "$replace_answer" in 
                n|no)
                    bold_echo Halting
                    # Just stop
                    exit 0;;
                y|yes)
                    break;;
                *)
                    echo "Please input y/n/yes/no"
            esac
        done
        replacing=true
        # We need to move the contents somewhere so they can be recovered later. Keep them in their dir through
        mv -f $bin_store_dir/$recipe_name $pkg_backup_dir
        # remove the pkg_link_dir symlink too in case something goes wrong
        rm -rf $pkg_link_dir/$recipe_name

        # TODO: add a trap to revert this if it doesn't work
    fi

    # check if the needs and build needs are satisfied. If not build them
    local test_len=${#runenv[@]}
    for need in ${runenv[@]}; do
        echo "Building $need"
        (build_recipe $need true)
    done

    # build the build needs too
    local test_len=${#buildenv[@]}
    for need in ${buildenv[@]}; do
        echo "Building $need"
        (build_recipe $need true)
    done

    # TODO: add a heuristic that deletes matching build dirs if there's more than 5 of them.
    BUILDDIR="$build_dir/$build_name"
    # Remove the old build dir
    rm -rf $BUILDDIR
    mkdir -p $BUILDDIR
    cd $BUILDDIR

    # symlink the items in both the env and buildenv sections
    ENVDIR=$BUILDDIR/env
    mkdir -p $ENVDIR

    for need in ${buildenv[@]}; do
        echo "Adding $need to env"
        local srcdir=`realpath $pkg_link_dir/$need`
        local env_files=(`cd $srcdir && find . -type f ! -name "*pkg-info.txt" -print`)
        for env_file in ${env_files[@]}; do
            # link the files
            local destfile=$ENVDIR/$env_file
            local srcfile=$srcdir/$env_file
            mkdir -p `dirname $destfile`
            ln -sf $srcfile $destfile
        done
    done

    for need in ${runenv[@]}; do
        echo "Adding $need to env"
        local srcdir=`realpath $pkg_link_dir/$need`
        local env_files=(`cd $srcdir && find . -type f ! -name "*pkg-info.txt" -print`)
        for env_file in ${env_files[@]}; do
            # link the files
            local destfile=$ENVDIR/$env_file
            local srcfile=$srcdir/$env_file
            mkdir -p `dirname $destfile`
            ln -sf $srcfile $destfile
        done
    done

    LOGDIR=$BUILDDIR/logs/
    # clear out the logs and make them again
    rm -rf $LOGDIR
    mkdir -p $LOGDIR

    SCRIPTDIR=$BUILDDIR/scripts/
    rm -rf $SCRIPTDIR
    mkdir -p $SCRIPTDIR

    #define variables that the recipe functions will use
    PKGDST=$bin_store_dir/$recipe_name
    rm -rf $PKGDST
    mkdir -p $PKGDST

    echo "Building in $BUILDDIR"

    # fetch sources
    for src in ${srcs[@]}; do
        # Check if this is a url
        if [[ "$src" == *"://"* ]]; then

            # wget the source
            # TODO: add option/test for wget vs curl
            src_file=`basename $src`
            src_file_out=$src_cache_dir/$src_file
            if [ -f $src_file_out ]; then
                echo "Source file $src_file_out exists, skipping download"
            else
                echo "Downloading $src_file_out from $src"
                log_dump_run $LOGDIR/"fetch-$src_file" "wget -O $src_file_out $src"
            fi

            # Extract the file to the build directory 
            # unzip if this is a zip file
            echo "Extracting $src_file_out to $BUILDDIR"
            if [[ $src_file_out == *".zip" ]]; then
                unzip $src_file_out -d $BUILDDIR
            else
                tar -xf $src_file_out
            fi
        else 
            # TODO: add git and package/recipe fetching/building.
            echo "ERROR: Other source formats not supported"
            exit 1
        fi
    done

    for fn in prep configure build check package; do
        declare -F $fn && bold_echo "Running $fn()" && log_run_script logs/log-$fn.txt scripts/run-$fn.sh "export PKGDST=\"$PKGDST\"
         export BUILDDIR=\"$BUILDDIR\"
         export ENVDIR=\"$ENVDIR\"
         source $recipe_to_build && $fn"
    done

    # Write metadata for the build to the dir
    local info_file=$PKGDST/pkg-info.txt
    rm -f $info_file

    local cfg_sum=`sha256sum $recipe_to_build`
    cfg_sum=${cfg_sum/ */}

    echo "Getting file hashes"
    local file_hash_list=`cd $PKGDST && find . -type f -exec sha256sum {} \\;`
    local bin_hash=`echo "$file_hash_list" | sha256sum -`
    bin_hash=${bin_hash/ */}
    local info_str="name=$build_name\ndate='`date -u -Ins`'\ncfg_sum=$cfg_sum\nbin_sum=$bin_hash\nfile_sums='${file_hash_list[@]}'"

    echo -e "$info_str" > $info_file

    # delete the pkgdst for the old package if there was one
    if [ -d $pkg_backup_dir ]; then
        echo "Deleting backup dir $pkg_backup_dir"
        rm -rf $pkg_backup_dir
    fi

    # Add the symlink to the link dir
    echo "Linking built recipe $PKGDST -> $pkg_link_dir"
    ln -sf $PKGDST $pkg_link_dir/

    echo "Deleting build dir ($BUILDDIR)"
    rm -rf $BUILDDIR
}

usage(){
    local script_name=${1?Please provide a script name}
    echo "Usage: $script_name [OPTION] [ARG]"
    echo "OPTIONS:"
    echo "  --clean-builds"
    echo "      Removes builds from $build_dir"
    echo "  --drop <pkg-name>"
    echo "      Removes <pkg-name> from $bin_store_dir"
    echo "  --see-added"
    echo "      Prints available packages"
    echo "  --import-recipe <recipe-path>    "
    echo "      Imports <recipe-path> into the installed recipes"
    echo "  --add <pkg-name>"
    echo "      Adds <pkg-name> to the build store if the build succeeds"
    echo "  --help"
    echo "      Shows this help"
}

filename=`basename $0`
# Parse args and run stuff.
while [ $# -gt 0 ]; do
    if [[ "$1" == "--clean-builds" ]]; then
        clean_builds
    elif [[ "$1" == "--drop" ]]; then
        # Delete the next argument from the bin-store
        shift
        drop_pkg $1
    elif [[ "$1" == "--see-added" ]]; then
        # print added packages
        print_added
    elif [[ "$1" == "--import-recipe" ]]; then
        shift
        import_recipe $1
    elif [[ "$1" == "--add" ]]; then
        shift
        build_recipe $1 ""
    elif [[ "$1" == "--help" ]]; then
        usage $filename
        exit
    else
        echo "ERROR: Unrecognized arg $1"
        exit 1
    fi
    shift
done
exit