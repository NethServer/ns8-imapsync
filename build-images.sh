#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Terminate on error
set -e
# Prepare variables for later use
images=()
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/nethserver}"

#Create webtop-webapp container
reponame="imapsync-binary"
container=$(buildah from docker.io/library/alpine:3.21.3)
buildah run "${container}" /bin/sh <<'EOF'
set -e
apk add --no-cache imapsync cronie patch
EOF
buildah add "${container}" imapsync/ /
buildah run "${container}" cp -vp /usr/bin/imapsync{,.orig}
buildah run "${container}" patch -d /usr/bin -p1 < imapsync-sievedelivery2.patch
buildah run "${container}" patch -d /usr/bin -p1 < imapsync-delete1older.patch
# Commit the image
buildah commit --rm "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

# Configure the image name
reponame="imapsync"

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-imapsync container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-imapsync; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-imapsync -v "${PWD}:/usr/src:Z" docker.io/library/node:lts
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-imapsync \
    sh -c "yarn install && yarn build"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Setup the entrypoint, ask to reserve one TCP port with the label and set a rootless container
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=mail@any:mailadm" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.images=${repobase}/imapsync-binary:${IMAGETAG:-latest}" \
    "${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github. 
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    # Just print info for manual push
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
