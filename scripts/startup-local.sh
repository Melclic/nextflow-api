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
for f in ${NXF_PIPELINES}/*.json; do    
    img=$(jq -r '.profiles.singularity.image // empty' "$f") # extract singularity image string
    if [[ -n "$img" ]]; then        
        fname=$(basename "$img" | sed 's/:/_/').sif # create expected filename (replace ":" with "_", add .sif)
        sif="${NXF_SINGULARITY_CACHEDIR}/$fname"
        if [[ ! -f "$sif" ]]; then
            echo "** pulling $img into $sif..."
            singularity pull --arch amd64 "$sif" "$img"
        else
            echo "** skipping $img, already present at $sif"
        fi
    fi
done

# # start server with local mongodb
# if [[ ${BACKEND} == "mongo" ]]; then
#     scripts/db-startup.sh
# fi
# echo "** ${HOME_DIR}/bin/server.py --backend=${BACKEND}"
# ${HOME_DIR}/bin/server.py --backend=${BACKEND}

# start server with remote mongodb
echo "** ${HOME_DIR}/bin/server.py --backend=${BACKEND} --url-mongo=mongodb://${MONGODB_USER}:XXX@${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DB}?authSource=admin"
${HOME_DIR}/bin/server.py --backend=${BACKEND} --url-mongo=mongodb://${MONGODB_USER}:${MONGODB_PWD}@${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DB}?authSource=admin
