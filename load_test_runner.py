#!/usr/bin/env python

import yaml
import random
import argparse
import subprocess
import multiprocessing


def get_args():
  parser = argparse.ArgumentParser()
  parser.add_argument('-f', '--plan-file', required=True)
  return parser.parse_args()


def get_config(plan_file):
  return yaml.load(open(plan_file, "r").read())


def run_data_seeding(config):
  return subprocess.Popen(
    'bundle exec ruby runner.rb '
    '--access-type=seed '
    '--min-id=%d '
    '--max-id=%d '
    '--mongo-hostport=%s:%d' %
    (config['seed']['min_id'], config['seed']['max_id'],
     config['mongodb']['host'], config['mongodb']['port']),
    cwd=config['runner']['location'],
    shell=True
  )


def run_loadtest(args):
  access_type, runner_location, min_id, max_id, num_requests, sleep, mongo_host, mongo_port = args
  return subprocess.Popen(
    'bundle exec ruby runner.rb '
    '--access-type=%s '
    '--min-id=%d '
    '--max-id=%d '
    '--num-requests=%d '
    '--sleep=%f '
    '--mongo-hostport=%s:%d ' %
    (access_type, min_id, max_id, num_requests, sleep, mongo_host, mongo_port),
    cwd=runner_location,
    shell=True
  )


def main():
  args = get_args()
  config = get_config(args.plan_file)

  data_seed_proc = run_data_seeding(config)
  data_seed_proc.wait()

  process_pool_size = sum([
    config['load_profile']['read']['num_processes'],
    config['load_profile']['write']['num_processes'],
    config['load_profile']['batchread']['num_processes'],
    config['load_profile']['batchwrite']['num_processes'],
  ])

  pool = multiprocessing.Pool(processes=process_pool_size)

  load_test_argument_list = []
  for access_type in ['read', 'write', 'batchread', 'batchwrite']:
    for _ in xrange(config['load_profile'][access_type]['num_processes']):
      load_test_argument_list.append(
        [access_type,
         config['runner']['location'],
         config['seed']['min_id'],
         config['seed']['max_id'],
         config['load_profile'][access_type]['num_requests'],
         config['load_profile'][access_type]['sleep'],
         config['mongodb']['host'],
         config['mongodb']['port']]
      )

  random.shuffle(load_test_argument_list)

  pool.map(run_loadtest, load_test_argument_list)

if __name__ == "__main__":
  main()
