require 'mongo'
require 'optparse'


# users belong to apps
# this is for querying users in batch, app_id is the key
# app and user have one-to-many relationship
NUM_APPS = 20

def get_args
  options = {}
  OptionParser.new do |opt|
    opt.on('--access-type seed|read|write|batchread|batchwrite', "access type of the commands sent to MongoDB") { |o| options[:access_type] = o }

    options[:sleep] = 0
    opt.on('--sleep seconds', Float, "sleep between requests, can use float, default to 0") { |o| options[:sleep] = o }

    options[:min_id] = 1
    opt.on('--min-id MIN_USERID', Integer, "lower bound of the id range of the seeded users") { |o| options[:min_id] = o }

    options[:max_id] = 100000
    opt.on('--max-id MAX_USERID', Integer, "upper bound of the id range of the seeded users") { |o| options[:max_id] = o }

    options[:num_requests] = 1000
    opt.on('--num-requests NUMBER_OF_REQUESTS', Integer, "total number of requests that will be fired") { |o| options[:num_requests] = o }

    options[:mongo_hostport] = '127.0.0.1:27017'
    opt.on('--mongo-hostport MONGO_HOST_AND_PORT', "mongodb host and port") { |o| options[:mongo_hostport] = o }

    options[:replica_set] = 'rs0'
    opt.on('--replica-set REPLICASET', "replica set name") { |o| options[:replica_set] = o }

    options[:db_name] = 'mongo-perf-test'
    opt.on('--db-name DBNAME', "database to access for this test script") { |o| options[:db_name] = o }

  end.parse!

  raise OptionParser::MissingArgument.new("Missing access_type") if options[:access_type].nil?

  options
end


def generate_user(user_id)
  {
    :anonymous => false,
    :role => 'user_role',
    :email => "test_#{user_id}@example.com",
    :user_id => "user#{user_id}",
    :app_id => rand(NUM_APPS),
    :name => "Test User #{user_id}",
    :custom_data => {
      :is_paying => false,
      :visit_from => 'europe'
    },
    :company_ids => [2000, 2001, 2002],
  }
end


def main
  args = get_args

  client = Mongo::Client.new([args[:mongo_hostport]],  #TODO support replicaset with multiple hosts
                             database: args[:db_name],
                             replica_set: args[:replica_set])

  case args[:access_type]
  when "seed"
    client[:users].drop
    client[:users].indexes.create_many([
      { key: { 'app_id' => 1 } },
      { key: { 'user_id' => 1 }, unique: true }
    ])
    for user_id in args[:min_id]..args[:max_id]
      client[:users].insert_one(generate_user(user_id))
    end
  when "write"
    args[:num_requests].times do
      client[:users].update_one(
        { 'user_id' => rand(args[:min_id]..args[:max_id]) },
        { '$set' => { 'company_ids' => [5000] } }
      )
      sleep(args[:sleep])
    end
  when "read"
    args[:num_requests].times do
      client[:users].find( { 'user_id' => rand(args[:min_id]..args[:max_id]) } ).to_a
      sleep(args[:sleep])
    end
  when "batchwrite"
    args[:num_requests].times do
      client[:users].update_many(
        { 'app_id' => rand(NUM_APPS)},
        { '$set' => { 'company_ids' => [3000, 3001, 3002, 3003] } }
      )
      sleep(args[:sleep])
    end
  when "batchread"
    args[:num_requests].times do
      client[:users].find( { 'app_id' => rand(NUM_APPS) } ).to_a
      sleep(args[:sleep])
    end
  end

end

main
