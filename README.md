# Bagger 

Docker image for [Islandora Bagger](https://github.com/mjordan/islandora_bagger).

Produces archival information packages, [Bags](https://en.wikipedia.org/wiki/BagIt), for object using Islandora's REST interface. For more information see [Islandora Bagger]

## Dependencies

Requires `islandora/nginx` Isle Buildkit image to build. Please refer to the
[Nginx Image README](https:w
://github.com/Islandora-DevOps/Isle-Buildkit/tree/main/nginx) for additional information including
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

* During container startup, a sample per bag config (`var/sample_per_bag_config.yaml`) is generated to work with the generated `config/services.yaml` for use with testing the command-line `create_bag`.

## Test

ToDo: revise

* adjust logs toml: one for prod and dev conf.d (having log in root of package does not work)
* permissions wrong (if APP_ENV set to prod)
* automate list generation of resources to preserve and informing islandora_bagger (rough idea: gather modify dates from Drupal resources and compare against modify dates (or hash?) in the islandora_bagger_integration bag log and if differ than add to a list to preserve  )
* post-bag plugin attach to OLRC
* automate image generation
* 

ToDo: Test further
* test: cron queue processing, requests from Drupal Context to preserve 
* Add application wide config option config/service.yml (instead of per bag config)
  * bag location (temp_dir, output_dir) and queue location (not bagger/var) to a persistent volume 
  * add Drupal username/password to service file (see readme option) so don't have to add to the per bag configuration and store on Drupal site as per Bagger integration readme
* test if per bag config can override location in the per config/services.yml. Also set in the crontab to override any overrides in the per bag
* addMedia fix (https://github.com/mjordan/islandora_bagger/pull/89)
* turn on ability to log preservation event in Drupal (https://github.com/mjordan/islandora_bagger_integration/pull/31)
* toml to create sample per bag config (point to volume) - "sample.config.yaml" as a template
* convert yaml_path to an env (where the per bag configuration stored on web requests for preservation - https://github.com/mjordan/islandora_bagger/blob/1b4973023d0ace40633c79340077980b3be7c947/src/Controller/IslandoraBaggerController.php#L26

## Setup Drupal - Delete Me:
```
composer require 'drupal/getjwtonlogin:^2.0'
cd web/modules/contrib/
git clone https://github.com/mjordan/islandora_bagger_integration.git
drush en -y getjwtonlogin
drush en -y islandora_bagger_integration
composer install
drush cache-rebuild
```


## Setup Bagger Container (temp)
```
docker compose cp custom/secrets/sample.config.yaml bagger:/var/www/sample.config.yaml`
```

Test:
```
curl  -H "Accept: application/json" 'https://cc-130.cwrc.ca/user/login?_format=xml'

Create Bag:
```
./bin/console app:islandora_bagger:create_bag -vvv --settings=var/sample_per_bag_config.yaml --node=47
```

Queue item:
``` bash
curl -v -X POST -H "Islandora-Node-ID: 48" --data-binary "@${BAGGER_APP_DIR}/var/sample_per_bag_config.yaml" http://127.0.0.1:8000/api/createbag

cd ${BAGGER_APP_DIR} && ./bin/console app:islandora_bagger:process_queue --queue=${BAGGER_QUEUE_PATH}
```



[Islandora Bagger]: https://github.com/mjordan/islandora_bagger
