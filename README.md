# Bagger 

Docker image for [Islandora Bagger](https://github.com/mjordan/islandora_bagger).

Produces archival information packages, [Bags](https://en.wikipedia.org/wiki/BagIt), for object using Islandora's REST interface. For more information see [Islandora Bagger]

## Dependencies

Requires `islandora/nginx` docker image to build. Please refer to the
[Nginx Image README](../nginx/README.md) for additional information including
additional settings, volumes, ports, etc.

## Settings

| Environment Variable                   | Confd Key | Default                                               | Description                                                                                                      |
|:---------------------------------------|:----------|:------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------|
| BAGGER_APP_ENV                         |           | dev                                                   | PHP Symphony app environment (dev, prod, test)                                                                   |
| BAGGER_QUEUE_PATH                      |           | '%kernel.project_dir%/var/islandora_bagger.queue'     | Location of the queue                                                                                            |
| BAGGER_LOCATION_LOG_PATH               |           | '%kernel.project_dir%/var/islandora_bagger.locations' | Location of the bag log path                                                                                     |
| BAGGER_APP_SECRET                      |           | 123                                                   | PHP Symphony app secret                                                                                          |
| BAGGER_CROND_ENABLE_SERVICE            |           | false                                                 | Enable scheduled job managed by cron to process the queue                                                        |
| BAGGER_CROND_SCHEDULE                  |           | 1 2 * * *                                             | Define the schedule of the queue processor                                                                       |
| BAGGER_BAG_DOWNLOAD_PREFIX             |           | https://islandora.traefik.me/bags/                    | The hostname/path to where users can download serialized bags. From config/services.yaml app.bag.download.prefix |
| BAGGER_DRUPAL_URL                      |           | https://drupal                                        | URL of the Drupal app                                                                                            |
| BAGGER_DRUPAL_DEFAULT_ACCOUNT_NAME     |           | admin                                                 | Drupal user account                                                                                              |
| BAGGER_DRUPAL_DEFAULT_ACCOUNT_PASSWORD |           | password                                              | Drupal user password                                                                                             |
| BAGGER_LOG_LEVEL                       |           | info                                                  | Log level. Possible Values: debug, info, notice, warning, error, critical, alert, emergency, none                |
| BAGGER_CROND_LOG_LEVEL                 |           | info                                                  | Log level. Possible Values: debug, info, notice, warning, error, critical, alert, emergency, none                |


## Test

ToDo: revise

* test: cron queue processing, requests from Drupal Context to preserve 
* adjust logs toml: one for prod and dev conf.d (having log in root of package does not work)
* permissions wrong (if APP_ENV set to prod)
* Add application wide config option config/service.yml (instead of per bag config)
  * bag location (temp_dir, output_dir) and queue location (not bagger/var) to a persistent volume 
  * add Drupal username/password to service file (see readme option) so don't have to add to the per bag configuration and store on Drupal site as per Bagger integration readme
* test if per bag config can override location in the per config/services.yml. Also set in the crontab to override any overrides in the per bag
* addMedia fix (https://github.com/mjordan/islandora_bagger/pull/89)
* turn on ability to log preservation event in Drupal
* toml to create sample per bag config (point to volume)
* Add Drupal Context to automate creation
* post-bag plugin attach to OLRC

Setup Bagger Container (temp)
```
docker compose cp custom/secrets/sample.config.yaml bagger:/var/www/sample.config.yaml`
```

Setup Drupal - Delete Me:
```
composer require 'drupal/getjwtonlogin:^2.0'
cd web/modules/contrib/
git clone https://github.com/mjordan/islandora_bagger_integration.git
drush en -y getjwtonlogin
drush en -y islandora_bagger_integration
composer install
drush cache-rebuild
```



Test:
```
curl  -H "Accept: application/json" 'https://cc-130.cwrc.ca/user/login?_format=xml'

Create Bag:
```
./bin/console app:islandora_bagger:create_bag -vvv --settings=../sample.config.yaml --node=47
```

Queue item:
```
curl -v -X POST -H "Islandora-Node-ID: 48" --data-binary "@/var/www/sample.config.yaml" http://12
7.0.0.1:8000/api/createbag
```



[Islandora Bagger]: https://github.com/mjordan/islandora_bagger
