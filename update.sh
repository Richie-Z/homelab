#!/bin/bash
set -eu

cd "$(dirname "$0")"

# dir|GitHub releases API|upstream values.yaml|tag prefix (optional)
# Add one line per chart directory. No per-chart script needed.
# Tag prefix: use when one repo releases many charts. The newest matching git tag wins.
charts=(
	'cert-manager|https://api.github.com/repos/cert-manager/cert-manager/releases/latest|https://raw.githubusercontent.com/cert-manager/cert-manager/refs/heads/master/deploy/charts/cert-manager/values.yaml'
	'harbor|https://api.github.com/repos/goharbor/harbor-helm/releases/latest|https://raw.githubusercontent.com/goharbor/harbor-helm/refs/heads/main/values.yaml'
	'jenkins|https://api.github.com/repos/jenkinsci/helm-charts/releases/latest|https://raw.githubusercontent.com/jenkinsci/helm-charts/main/charts/jenkins/values.yaml'
	'node-exporter|https://api.github.com/repos/prometheus-community/helm-charts/releases/latest|https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/prometheus-node-exporter/values.yaml|prometheus-node-exporter-'
	'kube-state-metrics|https://api.github.com/repos/prometheus-community/helm-charts/releases/latest|https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-state-metrics/values.yaml|kube-state-metrics-'
)

for entry in "${charts[@]}"; do
	IFS='|' read -r dir api values prefix <<<"$entry"
	dir="infra/$dir"

	if [[ -n "$prefix" ]]; then
		repo=${api#https://api.github.com/repos/}
		repo=${repo%/releases/latest}.git
		tag=$(git ls-remote --tags --refs "https://github.com/$repo" "refs/tags/$prefix*" | awk -F'refs/tags/' '{print $2}' | sort -V | tail -1)
	else
		tag=$(curl -fsSL "$api" | jq -r '.tag_name')
	fi

	if [[ -z "$tag" ]]; then
		echo "$dir: no tag found" >&2
		exit 1
	fi

	if [[ ! -f "$dir/version" ]]; then
		printf '%s\n' "$tag" >"$dir/version"
		curl -fsSLo "$dir/default-values.yaml" "$values"
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

	curl -fsSLo "$dir/default-values.yaml" "$values"
	echo "$dir: $previous -> $tag"
done
