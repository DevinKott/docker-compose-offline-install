#!/bin/bash
: '
    A script that helps perform offline-only installations
    of Docker compose scripts.

    SUCCESS EXIT CODES
    0) Script performed intended operation

    FAILURE EXIT CODES
    1) General purpose/catch all
    2) Incorrect program arguments
    3) Invalid operation
    4) The file passed in as an argument could not be found
'

set -e # Enable exit on non-zero codes

: 'Ensure we have the correct number of arguments passed into the program'
if [[ "$#" -ne 2 ]]; then
    echo "Usage: ./script.sh [save | load] <compose file | tarball>"
    exit 2
fi


op=$1
file=$2


: 'Ensure we have a valid operation'
if [[ "${op}" != "save" && "${op}" != "load" ]]; then
    echo "Invalid operation"
    exit 3
fi


: 'Ensure the file actually exists'
if [[ ! -f "$file" ]]; then
    echo "'$file' could not be found"
    exit 4
fi


if [[ "${op}" == "save" ]]; then
    : '
        A little complicated looking, but essentially
        awk will find image names from the file and
        then we loop through them.

        The rest of this command is bash converting
        awk output (\n separated) into an actual list.
    '
    image_tars=()
    set +e # TODO: Why does this command return a non-zero exit code?
    IFS=$'\n' read -r -d '' -a image_list < <(awk -F ': ' '/image/ {print $2}' $file)
    set -e
    for img in "${image_list[@]}"
    do
        base=${img#*/} # Gets everything after the /
        base_mod=${base//:/_} # Converts : to _
        
        : 'Pull the image down locally'
        echo "===== Pulling ${img}..."
        docker pull "${img}" > /dev/null 2>&1

        : 'Save the image into a tar'
        img_tar="${base_mod}.tar.gz"
        echo "===== Saving ${img} as ${img_tar}..."
        docker save "${img}" | gzip > "${img_tar}"

        image_tars+=("${img_tar}")
    done

    : '
        Loop through all of the tars we just downloaded and
        tar that
    '
    echo "===== Compressing image tars into a single tarball..."
    tar -czvf release.tar.gz "${image_tars[@]}"

    echo "===== Removing temporary files..."
    for img_tar in "${image_tars[@]}"
    do
        rm -rf "${img_tar}"
    done
else
    : 'Get a list of files before we unzip'
    image_list=($(tar -tzvf "${file}" | awk '{print $NF}'))

    echo "===== Unzipping archive..."
    : '-x = extract, -z = filter through gzip, -v = verbose, -f = specify filename'
    tar -xzvf "${file}"

    : 'Load in each docker image'
    for img in "${image_list[@]}"
    do
        echo "===== Loading ${img}..."
        docker load --input "${img}"
    done

    : 'Remove the .tar.gz'
    echo "===== Removing temporary files..."
    for img in "${image_list[@]}"
    do
        rm -rf "${img}"
    done

    rm -rf "${file}"
fi

echo "===== Done."
exit 0