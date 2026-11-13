def call(Map config = [:]) {
    def repoUrl = config.repoUrl ?: error('bumpGitopsTag: repoUrl is required')
    def branch = config.branch ?: 'master'
    def filePath = config.filePath ?: error('bumpGitopsTag: filePath is required')
    def tag = config.tag ?: error('bumpGitopsTag: tag is required')
    def key = config.key ?: 'tag'
    def credentialsId = config.credentialsId ?: error('bumpGitopsTag: credentialsId is required')
    def userName = config.userName ?: 'jenkins'
    def userEmail = config.userEmail ?: 'jenkins@localhost'
    def scope = config.scope ?: 'gitops'

    if (tag == 'latest') {
        echo "bumpGitopsTag: tag is 'latest', nothing to pin"
        return false
    }

    if (!(tag ==~ /^[A-Za-z0-9._-]+$/)) {
        error("bumpGitopsTag: unsafe tag '${tag}'")
    }

    if (!(key ==~ /^[A-Za-z0-9_-]+$/)) {
        error("bumpGitopsTag: unsafe key '${key}'")
    }

    if (
        filePath.startsWith('-') ||
        filePath.startsWith('/') ||
        filePath.contains('\\') ||
        filePath.split('/').any { it == '..' || it == '.' || it == '' }
    ) {
        error("bumpGitopsTag: unsafe filePath '${filePath}'")
    }

    if (!(branch ==~ /^[A-Za-z0-9._\/-]+$/) ||
        branch.startsWith('-') ||
        branch.contains('..') ||
        branch.endsWith('/') ||
        branch.endsWith('.')) {
        error("bumpGitopsTag: unsafe branch '${branch}'")
    }

    if (!(scope ==~ /^[A-Za-z0-9._-]+$/)) {
        error("bumpGitopsTag: unsafe scope '${scope}'")
    }

    def changed = false

    withEnv([
        "BUMP_REPO=${repoUrl}",
        "BUMP_BRANCH=${branch}",
        "BUMP_FILE=${filePath}",
        "BUMP_TAG=${tag}",
        "BUMP_KEY=${key}",
        "BUMP_NAME=${userName}",
        "BUMP_EMAIL=${userEmail}",
        "BUMP_SCOPE=${scope}"
    ]) {
        withCredentials([
            gitUsernamePassword(credentialsId: credentialsId)
        ]) {
            script {
                def rc = sh(
                    returnStatus: true,
                    script: '''
                        set -eu

                        repo="$(mktemp -d)"
                        trap 'rm -rf "$repo"' EXIT

                        export GIT_TERMINAL_PROMPT=0

                        git clone --depth 1 --branch "$BUMP_BRANCH" \
                            -- "$BUMP_REPO" "$repo"

                        cd "$repo"

                        git config user.name "$BUMP_NAME"
                        git config user.email "$BUMP_EMAIL"

                        [ -f "$BUMP_FILE" ] || {
                            echo "GitOps file does not exist: $BUMP_FILE" >&2
                            exit 1
                        }

                        # Count only keys under the top-level deployment.image block.
                        n="$(sed -nE '/^  image:[[:space:]]*$/,/^  [a-zA-Z]/p' "$BUMP_FILE" \
                            | grep -cE "^[[:space:]]*${BUMP_KEY}:" || true)"

                        [ "$n" -eq 1 ] || {
                            echo "Expected exactly one '${BUMP_KEY}:' under image:, found $n" >&2
                            exit 1
                        }

                        for attempt in 1 2 3; do
                            echo "GitOps update attempt $attempt"

                            # Always start from the latest remote branch.
                            git fetch origin "$BUMP_BRANCH"
                            git reset --hard FETCH_HEAD

                            q='"'
                            sed_arg='s|^([[:space:]]*'"${BUMP_KEY}"':).*|\1 '"${q}${BUMP_TAG}${q}"'|'
                            sed -i -E \
                                -e "/^  image:[[:space:]]*$/,/^  [a-zA-Z]/{" -e "$sed_arg" -e "}" \
                                "$BUMP_FILE"

                            verify_arg='^[[:space:]]*'"${BUMP_KEY}"':[[:space:]]*'"${q}${BUMP_TAG}${q}"'[[:space:]]*$'
                            grep -qE "$verify_arg" "$BUMP_FILE" || {
                                echo "sed did not write ${BUMP_KEY}: ${BUMP_TAG} into $BUMP_FILE" >&2
                                exit 1
                            }

                            if git diff --quiet -- "$BUMP_FILE"; then
                                echo "GitOps already uses $BUMP_TAG"
                                exit 0
                            fi

                            git add "$BUMP_FILE"

                            git commit -m \
                                "chore($BUMP_SCOPE): bump image tag to $BUMP_TAG"

                            if git push origin "HEAD:$BUMP_BRANCH"; then
                                echo "Successfully updated GitOps to $BUMP_TAG"
                                exit 10
                            fi

                            echo "Push failed, retrying..."
                        done

                        echo "Failed to update GitOps after 3 attempts" >&2
                        exit 1
                    '''
                )
                if (rc != 0 && rc != 10) {
                    error("bumpGitopsTag: updating ${filePath} failed with exit code ${rc}")
                }
                changed = (rc == 10)
            }
        }
    }

    return changed
}
