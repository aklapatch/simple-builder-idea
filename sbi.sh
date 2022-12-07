#!/bin/bash
set -euo pipefail

# Make the binary cache/src dir and the store dir
src_cache_dir=$HOME/.sbi/src-cache/
bin_store_dir=$HOME/.sbi/bin-store/
recipe_dir=$HOME/.sbi/recipes/
build_dir=$HOME/.sbi/builds/
config_file=$HOME/.sbi/sbi_cfg.sh

mkdir -p $src_cache_dir
mkdir -p $bin_store_dir
mkdir -p $recipe_dir
mkdir -p $build_dir

if [[ "$1" == "--clean-builds" ]]; then
    echo "Cleaning builds from $build_dir"
    rm -rf $build_dir
    echo "Done"
    exit
elif [[ "$1" == "--drop" ]]; then
    # Delete the next argument from the bin-store
    # TODO: implement dependency checking + removal
    local delete_me=$bin_store_dir/${2?Please provide a package to drop!}
    if [ -d $delete_me ]; then
        echo "Removing $2"
        rm -rf  $delete_me
        exit
    else
        echo "$2 Not installed!"
        exit 1
    fi
elif [[ "$1" == "--see-added" ]]; then
    # print added packages
    # Print everything in the bin-store
    cd $bin_store_dir
    find . -maxdepth 1 -type d -print
    exit
elif [[ "$1" == "--add-recipe" ]]; then
    # Source the recipe, and add it to the built-in recipe dir
    local recipe="${2?Please provide a recipe path to import}"
    if ! [ -f $recipe ]; then
        echo "ERROR: $recipe is not a file we can copy"
        exit 1
    fi

    # Get the recipe name and make a folder for it.
    source $recipe
    local recipe_name="$platform-$arch-$name-$ver"

    # Ask if we should replace a detected recipe
    local old_PKGDST=$bin_store_dir/$recipe_name
    if [ -d $old_PKGDST ]; then
        while true 
        do
            read -p "Found old package version at $old_PKGDST. Replace? (y/n): " -n 1 replace_answer
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

    mkdir -p $old_PKGDST/
    local recipe_dst="$old_PKGDST/recipe.sh"
    echo "Copying $recipe to $recipe_dst"
    cp $recipe $recipe_dst
    bold_echo Done
    exit 0
fi

# parse the recipe to build. This should be a file path, if not, then search the recipe dir
recipe=${1?Please provide a recipe path to build}
recipe=`realpath $recipe`

if ! [ -f $recipe ]; then
    echo "ERROR: $recipe is not a file"
    exit 1
fi
#TODO: Search the recipe dir for recipes based on the name given.


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
    eval "$2" | tee -a $log_file
}

bold_echo(){
    echo -e "\033[1m${1}\033[0m"
}

build_recipe(){
    local recipe_to_build="${1?This function needs a recipe to build}"
    local return_if_built="${2}"

    # Check if this is a folder in the bin-store, if it is, then don't do a bunch of things
    if [[ -n "$return_if_built" ]] && [ -d $bin_store_dir/$recipe_to_build ]; then
        echo "$recipe_to_build is built"
        return
        # TODO: search for recipes to build them
    elif ! [ -f $recipe_to_build ]; then
        echo "ERROR: $recipe_to_build is not a file"
        exit 1
    fi
    recipe_to_build=`realpath $recipe_to_build`

    source $recipe_to_build
    local recipe_name="$platform-$arch-$name-$ver"
    local build_name="$recipe_name-$rev"

    # Ask if we should replace a detected recipe
    old_PKGDST=$bin_store_dir/$recipe_name
    if [ -d $old_PKGDST ]; then
        while true 
        do
            read -p "Found old package version at $old_PKGDST. Replace? (y/n): " -n 1 replace_answer
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

    # check if the needs and build needs are satisfied. If not build them
    for need in ${runenv[@]}; do
        echo "Building $need"
        (build_recipe $need true)
    done

    # build the build needs too
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
        local srcdir=$bin_store_dir/$need
        local env_files=(`cd $srcdir && find . -type f ! -name "*pkg-info.txt" -print`)
        for env_file in ${env_files[@]}; do
            # link the files
            local destfile=$ENVDIR/$env_file
            local srcfile=$srcdir/$env_file
            mkdir -p `dirname $destfile`
            ln -f $srcfile $destfile
        done
    done

    for need in ${runenv[@]}; do
        echo "Adding $need to env"
        local srcdir=$bin_store_dir/$need
        local env_files=(`cd $srcdir && find . -type f ! -name "*pkg-info.txt" -print`)
        for env_file in ${env_files[@]}; do
            # link the files
            local destfile=$ENVDIR/$env_file
            local srcfile=$srcdir/$env_file
            mkdir -p `dirname $destfile`
            ln -f $srcfile $destfile
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
    PKGDST=$BUILDDIR/"$recipe_name-pkgdst"
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

    local cfg_sum=`xxhsum -H128 $recipe_to_build`
    cfg_sum=${cfg_sum/ */}

    echo "Getting file hashes"
    local file_hash_list=`cd $PKGDST && find . -type f -exec xxhsum -H128 {} \\;`
    local bin_hash=`echo "$file_hash_list" | xxhsum -H128 -`
    bin_hash=${bin_hash/ */}
    local info_str="name=$build_name\ndate='`date -u -Ins`'\ncfg_sum=$cfg_sum\nbin_sum=$bin_hash\nfile_sums='${file_hash_list[@]}'"

    echo -e "$info_str" > $info_file

    # delete the pkgdst for the old package if there was one
    tmp_PKGDST=${old_PKGDST}-old
    if [ -d $old_PKGDST ]; then
        # Keep the old one around in case moving goes wrong
        echo "Moving bin dir $old_PKGDST to dest $tmp_PKGDST"
        mv -f $old_PKGDST $tmp_PKGDST
    fi
    echo "Moving bin dir $PKGDST to dest $old_PKGDST"
    mv -f $PKGDST $old_PKGDST
    # We've moved, so delete the old one
    rm -rf $tmp_PKGDST

    echo "Deleting build dir ($BUILDDIR)"
    rm -rf $BUILDDIR
}

build_recipe $recipe ""