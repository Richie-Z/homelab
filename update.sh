#!/bin/bash
set -eu

cd "$(dirname "$0")"

# dir|helm repo/chart
# Each version file lists every version seen, newest first. Old upstream values
# snapshots are not kept: the repo history holds them.
charts=(
	'cert-manager|cert-manager/cert-manager'
	'harbor|harbor/harbor'
	'jenkins|jenkinsci/jenkins'
	'node-exporter|prometheus-community/prometheus-node-exporter'
	'kube-state-metrics|prometheus-community/kube-state-metrics'
	'prometheus|prometheus-community/prometheus'
	'grafana|grafana-community/grafana'
	'prometheus-alertmanager|prometheus-community/alertmanager'
	'loki|grafana-community/loki'
	'alloy|grafana/alloy'
	'cnpg|cloudnative-pg/cloudnative-pg'
)

for entry in "${charts[@]}"; do
	IFS='|' read -r dir repo <<<"$entry"
	dir="infra/$dir"

	tag=$(helm show chart "$repo" | yq '.version' | tr -d '"')

	if [[ -z "$tag" || "$tag" == "null" ]]; then
		echo "$dir: no version found" >&2
		exit 1
	fi

	if [[ ! -f "$dir/version" ]]; then
		mkdir -p "$dir"
		printf '%s\n' "$tag" >"$dir/version"
		helm show values "$repo" >"$dir/default-values.yaml"
		echo "$dir: $tag (new)"
		continue
	fi

	previous=$(head -n 1 "$dir/version")

	if [[ "$previous" == "$tag" ]]; then
		echo "$dir: $tag (unchanged)"
		continue
	fi

	printf '%s\n' "$tag" | cat - "$dir/version" >"$dir/version.new"
	mv "$dir/version.new" "$dir/version"
	helm show values "$repo" >"$dir/default-values.yaml"
	echo "$dir: $previous -> $tag"
done
