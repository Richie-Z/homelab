def call(Map config = [:]) {
  def authFile = config.authFile ?: '/auth/.dockerconfigjson'
  def registryHost = config.registryHost ?: 'harbor.dreadwrym.my.id'
  def registryProject = config.registryProject ?: 'apps'
  def dockerFilePath = config.dockerFilePath ?: error('buildImage: dockerFilePath is required')
  def imageName = config.imageName ?: error('buildImage: imageName is required')
  def tag = config.tag ?: error('buildImage: tag is required')
  def context = config.context ?: new File(dockerFilePath).getParent()
  def forceRebuild = (config.forceRebuild ?: false).toBoolean()

  def imageRepo = "$registryHost/$registryProject/$imageName"
  def cacheRepo = "$registryHost/$registryProject/${imageName}-cache"
  def image = "$imageRepo:$tag"

  withEnv([
      "AUTHFILE=${authFile}",
      "DOCKERFILE_PATH=${dockerFilePath}",
      "CONTEXT=${context}",
      "CACHE_REPO=${cacheRepo}",
      "IMAGE=${image}",
  ]) {
      if (forceRebuild) {
          echo "Force rebuild requested for ${env.IMAGE}"
      } else {
          def hasImage = sh(
            returnStatus: true,
            script: '''
              buildah --storage-driver=vfs pull \
                  --quiet \
                  --authfile "$AUTHFILE" \
                  "docker://$IMAGE" >/dev/null 2>&1
            '''
          )

          if (hasImage == 0) {
              echo "Image already in Harbor: ${env.IMAGE}"
              return
          }
          echo "Will build ${env.IMAGE}"
      }

      def buildStatus = sh(
        returnStatus: true,
        script: '''
          set -eu

          REGCONF="$(mktemp)"
          trap 'rm -f "$REGCONF"' EXIT
          printf 'unqualified-search-registries = ["docker.io"]\\n' > "$REGCONF"
          export CONTAINERS_REGISTRIES_CONF="$REGCONF"

          buildah build \
              --storage-driver=vfs \
              --isolation=chroot \
              --layers \
              --cache-from "$CACHE_REPO" \
              --cache-to "$CACHE_REPO" \
              --authfile "$AUTHFILE" \
              --file "$DOCKERFILE_PATH" \
              --tag "$IMAGE" \
              "$CONTEXT"
        '''
      )

      if (buildStatus != 0) {
          error("buildImage: build failed for ${env.IMAGE} (exit ${buildStatus})")
      }
      echo "Will push ${env.IMAGE}"

      def pushStatus = sh(
        returnStatus: true,
        script: '''
          buildah --storage-driver=vfs push \
              --authfile "$AUTHFILE" \
              "$IMAGE" "docker://$IMAGE"
        '''
      )

      if (pushStatus != 0) {
          error("buildImage: push failed for ${env.IMAGE} (exit ${pushStatus})")
      }
      echo "Pushed ${env.IMAGE}"
  }
}
