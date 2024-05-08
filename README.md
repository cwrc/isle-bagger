# Bagger

Docker image for [Islandora Bagger](https://github.com/mjordan/islandora_bagger).

Produces archival information packages, [Bags](https://en.wikipedia.org/wiki/BagIt), for objects using Islandora's REST interface. For more information see [Islandora Bagger]

## Dependencies

Requires Docker v24+ and `islandora/nginx` Isle Buildkit image to build. Please refer to the
[Nginx Image README](https://github.com/Islandora-DevOps/Isle-Buildkit/tree/main/nginx) for additional information including
additional settings, volumes, ports, etc.

## Settings

| Environment Variable                                | Confd Key | Default                                               | Description                                                                                                      |
|:----------------------------------------------------|:----------|:------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------|
| BAGGER_APP_ENV                                      |           | dev                                                   | PHP Symphony app environment (dev, prod, test)                                                                   |
| BAGGER_QUEUE_PATH                                   |           | '%kernel.project_dir%/var/islandora_bagger.queue'     | Location of the queue                                                                                            |
| BAGGER_LOCATION_LOG_PATH                            |           | '%kernel.project_dir%/var/islandora_bagger.locations' | Location of the bag log path                                                                                     |
| BAGGER_APP_SECRET                                   |           | 123                                                   | PHP Symphony app secret                                                                                          |
| BAGGER_CROND_LOG_LEVEL |           | 0                                                 | crond log level                                                        |
| BAGGER_CROND_ENABLE_SERVICE                         |           | false                                                 | Enable scheduled job managed by cron to process the queue                                                        |
| BAGGER_CROND_SCHEDULE                               |           | 1 2 * * *                                             | Define the schedule of the queue processor                                                                       |
| BAGGER_BAG_DOWNLOAD_PREFIX                          |           | https://islandora.traefik.me/bags/                    | The hostname/path to where users can download serialized bags. From config/services.yaml app.bag.download.prefix |
| BAGGER_DRUPAL_URL                                   |           | https://drupal                                        | URL of the Drupal app                                                                                            |
| BAGGER_DRUPAL_DEFAULT_ACCOUNT_NAME                  |           | admin                                                 | Drupal user account                                                                                              |
| BAGGER_DRUPAL_DEFAULT_ACCOUNT_PASSWORD              |           | password                                              | Drupal user password                                                                                             |
| BAGGER_LOG_LEVEL                                    |           | info                                                  | Log level. Possible Values: debug, info, notice, warning, error, critical, alert, emergency, none                |
| BAGGER_CROND_LOG_LEVEL                              |           | info                                                  | Log level. Possible Values: debug, info, notice, warning, error, critical, alert, emergency, none                |
| BAGGER_OUTPUT_DIR                                   |           | "%kernel.project_dir%/var/output"                     | Path to store generated archival information packages (bags)|
| BAGGER_QUEUE_PATH                                   |           | "%kernel.project_dir%/var/islandora_bagger.queue"     | Path to the queue file |
| BAGGER_TEMP_DIR                                     |           | "%kernel.project_dir%/var/tmp"                        | Path to the temp directory |
| BAGGER_DEFAULT_PER_BAG_REGISTER_BAGS_WITH_ISLANDORA |           | false                                                 | Register creation of this Bag with Islandora Bagger Integration |
| BAGGER_DEFAULT_PER_BAG_NAME                         |           | "nid"                                                 | How to name the Bag directory (or file if serialized). One of 'nid' or 'uuid'|
| BAGGER_DEFAULT_PER_BAG_NAME_TEMPLATE                |           | "aip_%"                                               | Template for the Bag name. The % is replaced by the nid or uuid (depending on the value of "bag_name")|
| BAGGER_DEFAULT_PER_BAG_SERIALIZE                    |           | "zip"                                                 | Whether or not to zip up the Bag. One of 'false', 'zip', or 'tgz' |
| BAGGER_DEFAULT_PER_BAG_CONTACT_NAME                 |           | "Contact"                                             | Bag-info: contact name |
| BAGGER_DEFAULT_PER_BAG_CONTACT_EMAIL                |           | "Contact email"                                       | Bag-info: contact email |
| BAGGER_DEFAULT_PER_BAG_SOURCE_ORGANIZATION          |           | "Source organization"                                 | Bag-info: source organization |
| BAGGER_DEFAULT_PER_BAG_HTTP_TIMEOUT                 |           | 120                                                   | Timeout (sec) when downloading the components that comprise a Bag |
| BAGGER_DEFAULT_PER_BAG_DELETE_SETTINGS_FILE         |           | "false"                                               | Per Bag settings file: delete after use |
| BAGGER_DEFAULT_PER_BAG_LOG_BAG_CREATION             |           | "true"                                                | Log the serialized Bag's creation |
| BAGGER_DEFAULT_PER_BAG_LOG_BAG_LOCATION             |           | "false"                                               | Log the serialized Bag's location to allow retrieval of the Bag's download URL (if applicable) |

----

## Notes

This container makes several opinionated assumptions about how one installs and interacts with the wide range of options available with [Islandora Bagger]. Some of the opinionated options are mentioned in this section, see [Dockerfile](./Dockerfile), [conf.d templates](./rootfs/etc/confd/),

* During container startup, a default per bag config (`var/sample_per_bag_config.yaml`) is created to work with the generated `config/services.yaml` for use with testing the command-line `create_bag`.
* An application config, `config/service.yml` is generated during startup to reduce the need for a per-bag config
  * Set the bag location (temp_dir, output_dir) and queue location (not bagger/var) to a persistent volume
  * Add Drupal username/password to service file (see readme option) so don't have to add to the per-bag configuration and store on Drupal site as per Bagger integration readme
* Logging configuration templates to output to stdout/stderr: one for prod and dev conf.d (having the log in the root of packages directory does not work)
* Optional queue processing via cron (via environment variables: BAGGER_CROND_*)
* Doesn't enable the "REST API to get a serialized Bag's location for download"
* Defaults to add media to the Bags, see the addMedia fix (https://github.com/mjordan/islandora_bagger/pull/89)
* Turn on the ability to register preservation bag creation with Drupal/Islandora (https://github.com/mjordan/islandora_bagger_integration/pull/31) via `BAGGER_DEFAULT_PER_BAG_REGISTER_BAGS_WITH_ISLANDORA`
* Make no assumptions about setup infrastructure: assume a proxy or edge router (see warnings about setup in [Islandora Bagger])

## Test

ToDo: revise

* permissions wrong (if `APP_ENV` is set to prod)
* automate the build of a list of resources to preserve and pass to islandora_bagger (rough idea: gather Drupal resources by their modified date and compare against the modified dates (or hash?) in the islandora_bagger_integration bag log and if differ then add to a list to preserve  )
* post-bag plugin to upload archival packages to OLRC
* automate OCI image generation and upload to an image repository

ToDo: Test further

* Test: Drupal Context that sends requests to the Bagger REST API to queue a preservation request
* test if per bag config can override location in the per config/services.yml. Also set in the crontab to override any overrides in the per bag
* convert yaml_path to an env (where the per bag configuration is stored on web requests for preservation - https://github.com/mjordan/islandora_bagger/blob/1b4973023d0ace40633c79340077980b3be7c947/src/Controller/IslandoraBaggerController.php#L26)
* `delete_settings_file`: problems arise if the resource is added to the queue multiple times before being preserved.  The resource is added to the preservation queue multiple times but the settings file is only stored on the filesystem once thus the first preservation will delete the settings file and subsequent queued items may cause a missing settings file error.

## Setup Drupal

See [Islandora Bagger] for the Drupal setup requirements. `getjwtonlogin` and `islandora_bagger_integration` are required. A quick way to add (note: should use composer, this is a temporary kluge):

``` bash
composer require 'drupal/getjwtonlogin:^2.0'
cd web/modules/contrib/
git clone https://github.com/mjordan/islandora_bagger_integration.git
cd /var/www/drupal
drush en -y getjwtonlogin
drush en -y islandora_bagger_integration
composer install
drush cache-rebuild
```

See the following README files for additional setup within Drupal, especially if the register bag option is enabled

* [Islandora Bagger Integration Bag Log](https://github.com/mjordan/islandora_bagger_integration#the-bag-log)
* [Islandora Bagger](https://github.com/mjordan/islandora_bagger)

## run a local instance via Docker Compose

* Create a local config for Docker Compose: `.env.sample` to `.env`
* Update the .env with the Drupal/Islandora site domain and Drupal user
* Add secret: Drupal account password (see docker-compose.yml) for location
* Add other environment variables described in the `docker-compose.yml` to the `.env` file
* `docker compose build` - build
* `docker compose up -d` - assumes a proxy or edge router (see warnings about setup in [Islandora Bagger])

## Setup Bagger Container (temp)

This step may be automated but in case you want a custom config:

``` bash
docker compose cp custom/secrets/sample.config.yaml bagger:/var/www/sample.config.yaml`
```

Test setup of Drupal (login):

``` bash
# Execute locally to a remote site
curl  -H "Accept: application/json" 'https://islandora.dev/user/login?_format=xml'
# Execute locally to a local/dev site with mkcert SSL
curl --cacert build/certs/rootCA.pem  -Headers "Accept: application/json" https://islandora.dev/user/login?_format=xml
```

Create Bag:

``` bash
./bin/console app:islandora_bagger:create_bag -vvv --settings=var/sample_per_bag_config.yaml --node=47
```

Queue item:

``` bash
# Within isle-bagger container
curl -v -X POST -H "Islandora-Node-ID: 48" --data-binary "@${BAGGER_APP_DIR}/var/sample_per_bag_config.yaml" http://127.0.0.1:8000/api/createbag

cd ${BAGGER_APP_DIR} && ./bin/console app:islandora_bagger:process_queue --queue=${BAGGER_QUEUE_PATH}
```

## Recipe to include the Isle-Bagger container with an existing Isle site

The following is a recipe to include the isle-bagger with an existing Isle site of the form:

* [Isle-site-template](https://github.com/Islandora-Devops/isle-site-template)
* [Isle-DC](https://github.com/Islandora-Devops/isle-dc)

The Steps:

* Update Drupal composer.json / composer.lock
  * See [Islandora Bagger] for the Drupal setup requirements
    * The Drupal modules `getjwtonlogin` and `islandora_bagger_integration` are required.
* Copy the sample docker-compose.bagger.yml into the Isle site directory
* Include the `COMPOSE_FILE` property in the `.env` file
  * to chain multiple docker-compose.yml files together (i.e., reduce the need to change the default docker-compose.yml)

``` config
# Chain docker-compose.yml files
COMPOSE_PATH_SEPARATOR=:
COMPOSE_FILE=docker-compose.yml:docker-compose.bagger.yml

# Environment for the Islandora Bagger container
BAGGER_REPOSITORY=ghcr.io/cwrc
BAGGER_TAG=latest
BAGGER_DEFAULT_PER_BAG_REGISTER_BAGS_WITH_ISLANDORA=true
```

## References

[Islandora Bagger]: https://github.com/mjordan/islandora_bagger
