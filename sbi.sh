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

# parse the recipe to build. This should be a file path, if not, then search the recipe dir
recipe=${1?Please provide a recipe path to build}
recipe=`realpath $recipe`

if ! [ -f $recipe ]; then
    echo "ERROR: $recipe is not a file"
    exit 1
fi
#TODO: Search the recipe dir for recipes based on the name given.

# Copy the recipe to the recipes dir to save it for later
if [[ *"$recipe_dir"* != $recipe  ]]; then
    echo "Copying $recipe to $recipe_dir"
    cp $recipe $recipe_dir/
    recipe=$recipe_dir/`basename $recipe`
fi

# log the command and run it
log_run(){
    # 1 is log file 2 is cmd
    local log_file=${1?Please provide a log name}
    echo "${2?Please provide a command}" > "$log_file"
    eval "$2" | tee -a $log_file
}

build_recipe(){
    local build_recipe=${1?This function needs a recipe to build}

    if ! [ -f $build_recipe ]; then
        echo "ERROR: $build_recipe is not a file"
        exit 1
    fi

    source $build_recipe

    # check if the needs and build needs are satisfied. If not build them
    for need in ${needs[@]}; do
        if [[ "$need" != 'system-cc' ]]; then
            build_recipe $need
        fi
    done

    local build_name=`basename $build_recipe`
    build_name=${build_name/.sh/}
    local recipe_build_dir=$build_dir/build-$build_name
    mkdir -p $recipe_build_dir
    cd $recipe_build_dir

    local build_log_dir=$recipe_build_dir/logs
    mkdir -p $build_log_dir

    echo "Building in $recipe_build_dir"

    # fetch sources
    for src in ${srcs[@]}; do
        # split by | to get the url and the dest file
        if [[ "$src" != *"|"* ]]; then
            echo "ERROR: bad format for src: '$src'"
            exit 1
        fi

        # wget the source
        # TODO: add option/test for wget vs curl
        src_file=${src/|*/}
        src_file_out=$src_cache_dir/$src_file
        src_url=${src/*|/}
        if [ -f $src_file_out ]; then
            echo "Source file $src_file_out exists, skipping download"
        else
            echo "Downloading $src_file_out from $src_url"
            log_run "fetch-$src_file.txt" "wget -O $src_file_out $src_url"
        fi

        # Extract the file to the build directory 
        echo "Extracting $src_file_out to $recipe_build_dir"
        tar -x -f $src_file_out

        #define variables that the recipe functions will use
        PKGDST=$bin_store_dir/$build_name
        BUILDDIR=$recipe_build_dir
        LOGDIR=$build_log_dir

    done

    # run the prep function if it was defined
    echo "Running prep()"
    declare -F prep > /dev/null && log_run logs/prep-log.txt prep

    # run the configure function
    echo "Running configure()"
    declare -F configure && log_run logs/config-log.txt configure

    # build the package
    echo "Running build()"
    declare -F build && log_run logs/build-log.txt build

    echo "Running check()"
    declare -F check && log_run logs/check-log.txt check

    # package the build
    echo "Running package()"
    declare -F package && log_run logs/package-log.txt package

    # Write metadata for the build to the dir
    local info_file=$PKGDST/pkg-info.txt
    echo "name=$build_name" > $info_file
    echo "date=`date -u`" >> $info_file

    local cfg_sum=`xxhsum -H128 $build_recipe`
    cfg_sum=${cfg_sum/ */}
    echo "cfg_sum=$cfg_sum" >> $info_file

    local folder_sum=`cd $PKGDST && tar -c -f - . | xxhsum - -H128`
    folder_sum=${folder_sum/ */}
    echo "bin_sum=$folder_sum" >> $info_file
}

build_recipe $recipe