def call(Map config = [:]) {
    def repoUrl = config.repoUrl ?: error('bumpGitopsTag: repoUrl is required')
    def branch = config.branch ?: 'master'
    def filePath = config.filePath ?: error('bumpGitopsTag: filePath is required')
    def tag = config.tag ?: error('bumpGitopsTag: tag is required')
    def key = config.key ?: 'tag'
    def credentialsId = config.credentialsId ?: error('bumpGitopsTag: credentialsId is required')
    def userName = config.userName ?: 'jenkins'
    def userEmail = config.userEmail ?: 'jenkins@localhost'

    if (tag == 'latest') {
        echo "bumpGitopsTag: tag is 'latest', nothing to pin"
        return false
    }

    withCredentials([gitUsernamePassword(credentialsId: credentialsId)]) {
        sh """
            set -eu

            repo="\$(mktemp -d)"
            trap 'rm -rf "\$repo"' EXIT

            git clone --depth 1 --branch '${branch}' '${repoUrl}' "\$repo"
            cd "\$repo"

            git config user.name '${userName}'
            git config user.email '${userEmail}'

            if [ ! -f '${filePath}' ]; then
                echo "bumpGitopsTag: ${filePath} does not exist on ${branch}. Create it by hand, commit it, then rebuild." >&2
                exit 1
            fi

            sed -i -E "s/^([[:space:]]*${key}:).*/\\1 ${tag}/" '${filePath}'

            if ! grep -qE "^[[:space:]]*${key}:[[:space:]]*${tag}[[:space:]]*\$" '${filePath}'; then
                echo "bumpGitopsTag: no '${key}: ${tag}' line in ${filePath}; the file may lack a '${key}:' key." >&2
                exit 1
            fi

            if git diff --quiet -- '${filePath}'; then
                echo "bumpGitopsTag: ${filePath} already at ${tag}"
                exit 0
            fi

            git add '${filePath}'
            git commit -m "chore(${config.scope ?: 'gitops'}): bump image tag to ${tag}"
            git push origin "HEAD:${branch}"
        """
    }

    return true
}
