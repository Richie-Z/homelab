def call(Map config = [:]) {
  def authFile = config.authFile ?: '/auth/.dockerconfigjson'
  def registryHost = config.registryHost ?:'harbor.dreadwrym.my.id'
  def registryProject = config.registryProject ?: 'apps'
  def tag = config.tag ?: error('buildImage: tag is required')
  def dockerFilePath = config.dockerFile ?: error('buildImage: dockerFilePath is required')
  def imageName = config.imageName ?: error('buildImage: image is required')

  def cacheName = "$imageName-cache"
  def imageRepo = "$registryHost/$registryProject/$imageName"
  def cacheRepo = "$registryHost/$registryProject/$cacheRepo"
  def image = "$imageRepo:$tag"

  withEnv([
      "AUTHFILE=${authFile}",
      "DOCKERFILE_PATH=${dockerFile}",
      "CACHE_REPO"=${cacheRepo},
      "IMAGE=${image}",
  ]) {
      def hasImage = sh(
        returnStatus: true,
        script: '''
          set -eu

          buildah --storage-driver=vfs pull \
          --quiet \
          --authfile "$AUTHFILE" \
          "docker://$IMAGE" >/tmp/pull.log 2>&1
          rc=$?

          if [ "$rc" -ne 0 ]; then tail -n 5 /tmp/pull.log; fi

          exit "$rc"
        '''
      )

      if (hasImage == 0) {
          echo "Image already in Harbor: ${env.IMAGE}"
          return 0;
      } else {
          echo "Will build ${env.IMAGE}"
      }

      def imageCreate = sh(
        returnStatus: true, 
        script: '''
          set -eu

          REGCONF="$(mktemp)"
          printf 'unqualified-search-registries = ["docker.io"]\\n' > "$REGCONF"
          export CONTAINERS_REGISTRIES_CONF="$REGCONF" 

          CONTEXT="$(dirname "$DOCKERFILE_PATH")" 

          buildah build \
              --storage-driver=vfs \
              --isolation=chroot \
              --layers \
              --cache-from "$CACHE_REPO" \
              --cache-to "$CACHE_REPO" \
              --authfile "$AUTHFILE" \
              --file $DOCKERFILE_PATH\
              --tag "$IMAGE" \
              "$CONTEXT"

          return 1
        '''
      )

      if (imageCreate != 0) {
          echo "Fail build Image ${env.IMAGE}"
          return 0;
      } else {
          echo "Will push ${env.IMAGE}"
      }

      def imagePush = sh(
        returnStatus: true,
        script: '''
          set -eu

          buildah --storage-driver=vfs push \
              --authfile "$AUTHFILE" \
              "$IMAGE" "docker://$IMAGE"

          return 1
        '''
      )
  }
}
