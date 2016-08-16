## Test cluster for Mongo

#### start a cluster of containers in the background for test

``` bash
  # mongo2
  docker-compose -f docker-compose-mongo2.6.11.yml up -d
  # mongo3
  docker-compose -f docker-compose-mongo3.2.8.yml up -d
```

#### stop and remove containers after test

``` bash
  # mongo2
  docker-compose -f docker-compose-mongo2.6.11.yml stop
  docker-compose -f docker-compose-mongo2.6.11.yml rm -af

  # mongo3
  docker-compose -f docker-compose-mongo3.2.8.yml stop
  docker-compose -f docker-compose-mongo3.2.8.yml rm -af
```
