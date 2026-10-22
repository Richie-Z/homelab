#!/bin/bash
set -eu

cd "$(dirname "$0")"

# dir|helm repo/chart
charts=(
	'cert-manager|cert-manager/cert-manager'
	'harbor|harbor/harbor'
	'jenkins|jenkinsci/jenkins'
	'node-exporter|prometheus-community/prometheus-node-exporter'
	'kube-state-metrics|prometheus-community/kube-state-metrics'
	'prometheus|prometheus-community/prometheus'
)

for entry in "${charts[@]}"; do
	IFS='|' read -r dir repo <<<"$entry"
	dir="infra/$dir"

	tag=$(helm show chart "$repo" | yq ".version")

	if [[ -z "$tag" ]]; then
		echo "$dir: no tag found" >&2
		exit 1
	fi

	if [[ ! -f "$dir/version" ]]; then
		printf '%s\n' "$tag" >"$dir/version"
		helm show values "$repo" >"$dir/default-values.yaml"
		echo "$dir: $tag (new)"
		continue
	fi

	previous=$(cat "$dir/version")

	if [[ "$previous" == "$tag" || "$previous" == "\"$tag\"" ]]; then
		echo "$dir: $tag (unchanged)"
		continue
	fi

	archive=${previous//\"/}
	archive=${archive//\//-}
	mv "$dir/default-values.yaml" "$dir/$archive-default-values.yaml"

	# Keep the version file's existing quoting style.
	if [[ "$previous" == \"* ]]; then
		printf '"%s"\n' "$tag" >"$dir/version"
	else
		printf '%s\n' "$tag" >"$dir/version"
	fi

	helm show values "$repo" >"$dir/default-values.yaml"
	echo "$dir: $previous -> $tag"
done
