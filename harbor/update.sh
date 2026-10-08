#!/bin/bash
set -eu

LATEST_TAG=$(curl -fsSL https://api.github.com/repos/goharbor/harbor-helm/releases/latest | jq '.tag_name')

is_new=false

if [[ ! -f version ]]; then
	echo $LATEST_TAG >version
	is_new=true
fi

PREVIOUS_TAG=$(cat version)

if [[ $LATEST_TAG != $PREVIOUS_TAG || $is_new ]]; then
	echo $LATEST_TAG >version

	if [[ $is_new == false ]]; then
		mv default-values.yaml "${PREVIOUS_TAG//\"/}-default-values.yaml"
	fi

	curl -sSLo default-values.yaml https://raw.githubusercontent.com/goharbor/harbor-helm/refs/heads/main/values.yaml
fi
