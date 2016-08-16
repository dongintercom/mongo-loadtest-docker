# Load test tools for MongoDB in docker containers

### Setup runners
``` bash
# install prerequisite for the load test runner
% pip install -r requirements.txt

# install prerequisite for the ruby runner
% cd lib/ruby_agent
% bundle install
```

### Setup Mongodb docker container cluster

You can choose to test either a Mongo2 cluster or a Mongo3 cluster
This will start a Mongodb container and a Graphite container (through which the stats/metrics can be viewed)

#### for Mongo2
``` bash
% cd docker/
% docker-compose -f docker-compose-mongo2.6.11.yml up -d
```

#### for Mongo3
``` bash
% cd docker/
% docker-compose -f docker-compose-mongo3.2.8.yml up -d
```
More docker commands can be found at [`docker/README.md`](https://github.com/dongintercom/mongo-loadtest-docker/blob/master/docker/README.md)

### Write a test plan

Example can be found at `plans/example_plan.yml`:
``` yaml
runner:
  language: ruby
  location: ./lib/ruby_agent/

mongodb:
  host: 192.168.99.101
  port: 27017

seed:
  min_id: 1
  max_id: 1000

load_profile:
  write:
    num_processes: 1
    num_requests: 1000
    sleep: 0
  read:
    num_processes: 1
    num_requests: 1000
    sleep: 0
  batchwrite:
    num_processes: 1
    num_requests: 500
    sleep: 0.5
  batchread:
    num_processes: 1
    num_requests: 1000
    sleep: 0.1
```

### Execute the plan

This will execute data seeding and then spawn multiple processes according to the plan against the Mongodb cluster.

``` bash
% ./load_test_runner.py --plan-file plans/example_plan.yml
```

### View the metrics in Graphite

#### on Mac

Find the ip address for docker
``` bash
% echo $DOCKER_HOST
tcp://192.168.99.101:2376
```
Go to browser: <http://192.168.99.101/dashboard>

#### on Linux

Find the ip address for the graphite container
``` bash
# look for "docker_graphite_1"
% docker network inspect docker_default
```
Go to browser: <http://172.18.0.3/dashboard>
