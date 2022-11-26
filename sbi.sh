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
fi

# parse the recipe to build. This should be a file path, if not, then search the recipe dir
recipe=${1?Please provide a recipe path to build}
recipe=`realpath $recipe`

if ! [ -f $recipe ]; then
    echo "ERROR: $recipe is not a file"
    exit 1
fi
#TODO: Search the recipe dir for recipes based on the name given.

# Log the command, and dump the command to a script file to replicate it later.
log_dump_run(){
    local base=${1?Please provide a log/script base name}
    local log_file=$base.txt
    printf "#!/bin/bash\n%s" ${2?Please provide a command} > $base.sh
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

build_recipe(){
    local build_recipe=${1?This function needs a recipe to build}

    if ! [ -f $build_recipe ]; then
        echo "ERROR: $build_recipe is not a file"
        exit 1
    fi

    source $build_recipe
    local recipe_name="$pkgname-$pkgver"
    local build_name="$recipe_name-$pkgrev"

    # Copy the recipe to the recipes dir to save it for later
    if [[ *"$recipe_dir"* != $build_recipe  ]]; then
        local subdir=$recipe_dir/$recipe_name

        echo "Copying $recipe to $subdir"
        mkdir -p $subdir
        cp $recipe $subdir/recipe.sh
    fi

    # check if the needs and build needs are satisfied. If not build them
    for need in ${needs[@]}; do
        build_recipe $need
    done


    BUILDDIR=$build_dir/$build_name
    mkdir -p $BUILDDIR
    cd $BUILDDIR

    LOGDIR=$BUILDDIR/logs/

    # clear out the logs and make them again
    rm -rf $LOGDIR
    mkdir $LOGDIR

    echo "Building in $BUILDDIR"

    # fetch sources
    for src in ${srcs[@]}; do
        # split by | to get the url and the dest file
        if [[ "$src" != *"|"* ]]; then

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
            echo "Extracting $src_file_out to $BUILDDIR"
            tar -xf $src_file_out
        else 
            # TODO: add git and package/recipe fetching/building.
            echo "ERROR: Other source formats not supported"
            exit 1
        fi
    done

    #define variables that the recipe functions will use
    PKGDST=`mktemp -d $bin_store_dir/$recipe_name~build^tmp-XXXX`

    local save_dest=$PKGDST.old
    for fn in prep configure build check package; do
        declare -F $fn && echo "Running $fn()" && log_dump_run logs/log-$fn $fn
    done

    # Write metadata for the build to the dir
    local info_file=$PKGDST/pkg-info.txt
    rm -f $info_file

    local cfg_sum=`xxhsum -H128 $build_recipe`
    cfg_sum=${cfg_sum/ */}

    local file_hash_list=`cd $PKGDST && find . -type f -exec xxhsum -H128 {} \\;`
    local bin_hash=`echo "$file_hash_list" | xxhsum -H128 -`
    bin_hash=${bin_hash/ */}
    local info_str="name=$build_name\ndate='`date -u -Ins`'\ncfg_sum=$cfg_sum\nbin_sum=$bin_hash\nfile_sums='${file_hash_list[@]}'"

    echo -e "$info_str" > $info_file

    # delete the pkgdst for the old package if there was one
    old_PKGDST=$bin_store_dir/$recipe_name
    tmp_PKGDST=${old_PKGDST}-old
    if [ -d $old_PKGDST ]; then
        mv -f $old_PKGDST $tmp_PKGDST
    fi
    echo "Moving build dir $PKGDST to dest $old_PKGDST"
    mv -f $PKGDST $old_PKGDST
    rm -rf $tmp_PKGDST
}

build_recipe $recipe