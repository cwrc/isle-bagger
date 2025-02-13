variable "ISLE_BUILDKIT_REGISTRY" {
    default = "docker.io/islandora"
    }
variable "ISLE_BUILDKIT_VERSION" {
    default = "3.5.3"
    }

###############################################################################
# Common target properties.
###############################################################################
target "common" {
  args = {
    # Required for reproduciable builds.
    # Requires Buildkit 0.11+
    # See: https://reproducible-builds.org/docs/source-date-epoch/
    # SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}",
  }
}

# https://github.com/docker/metadata-action?tab=readme-ov-file#bake-definition
# bake definition file that can be used with the Docker Bake action. You just
# have to declare an empty target named docker-metadata-action and inherit from it.
target "docker-metadata-action" {}


###############################################################################
# Groups
###############################################################################

group "default" {
  targets = ["isle-bagger"]
}

###############################################################################
# Target.
###############################################################################
# The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
# It will be the digest printed when you do: docker pull alpine:3.17.1
# Not the one displayed on DockerHub.

target "isle-bagger" {
  inherits = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile"
  contexts = {
    isle_buildkit = "docker-image://${ISLE_BUILDKIT_REGISTRY}/nginx:${ISLE_BUILDKIT_VERSION}"
  } 
}
