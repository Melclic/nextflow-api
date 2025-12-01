#!/bin/bash
# Startup script for local environment.

# home folder
HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)/.."

# parse command-line arguments
if [[ $# == 1 ]]; then
    BACKEND="$1"
else
	echo "usage: $0 <backend>"
	exit -1
fi

# start web server
export NXF_EXECUTOR="local"
export TF_CPP_MIN_LOG_LEVEL="3"

# obtain the singularity images
# reads the pipelines (from $NXF_PIPELINES) and pulls missing '.sif' images (to $NXF_SINGULARITY_CACHEDIR)
# for f in ${NXF_PIPELINES}/*.json; do    
#     img=$(jq -r '.profiles.singularity.image // empty' "$f") # extract singularity image string
#     if [[ -n "$img" ]]; then        
#         fname=$(basename "$img" | sed 's/:/_/').sif # create expected filename (replace ":" with "_", add .sif)
#         sif="${NXF_SINGULARITY_CACHEDIR}/$fname"
#         if [[ ! -f "$sif" ]]; then
#             echo "** pulling $img into $sif..."
#             singularity pull --arch amd64 "$sif" "$img"
#         else
#             echo "** skipping $img, already present at $sif"
#         fi
#     fi
# done

echo "Backend selected: ${BACKEND}"

# file backend
if [[ "${BACKEND}" == "file" ]]; then
    # optional override, default matches server.py default
    URL_FILE="${URL_FILE:-db.pkl}"

    echo "** Starting server with file backend"
    echo "** ${HOME_DIR}/bin/server.py --backend=file --url-file=${URL_FILE}"
    exec "${HOME_DIR}/bin/server.py" \
        --backend=file \
        --url-file="${URL_FILE}"

# mongo backend
elif [[ "${BACKEND}" == "mongo" ]]; then

    # local or remote mongo
    if [[ "${MONGODB_HOST}" == "local" ]]; then
        echo "** Starting local MongoDB instance"
        scripts/db-startup.sh
        MONGO_URL="mongodb://${MONGODB_USER}:${MONGODB_PWD}@localhost:${MONGODB_PORT}/${MONGODB_DB}?authSource=admin"
    else
        MONGO_URL="mongodb://${MONGODB_USER}:${MONGODB_PWD}@${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DB}?authSource=admin"
    fi

    echo "** Starting server with Mongo backend"
    echo "** ${HOME_DIR}/bin/server.py --backend=mongo --url-mongo=${MONGO_URL}"
    exec "${HOME_DIR}/bin/server.py" \
        --backend=mongo \
        --url-mongo="${MONGO_URL}"

# unknown backend
else
    echo "ERROR: Unknown BACKEND value: ${BACKEND} expected file or mongo"
    exit 1
fi