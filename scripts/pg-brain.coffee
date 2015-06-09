# Description:
#   Stores the brain in Postgres
#
# Configuration:
#   DATABASE_URL
#
# Notes:
#   Run the following SQL to setup the table and column for storage.
#
#   CREATE TABLE brain (
#     key TEXT unique,
#     value JSON default '{}'::json,
#     CONSTRAINT brain_pkey PRIMARY KEY (key)
#   )
#
# Author:
#   Yannick Schutz

Postgres = require 'pg'

# sets up hooks to persist the brain into postgres.
module.exports = (robot) ->

  database_url = process.env.DATABASE_URL

  if !database_url?
    throw new Error('pg-brain requires a DATABASE_URL to be set.')

  client = new Postgres.Client(database_url)
  client.connect()
  robot.logger.debug "pg-brain connected to #{database_url}."

  query = client.query("SELECT storage FROM hubot LIMIT 1")
  query.on 'row', (row) ->
    if row['storage']?
      robot.brain.mergeData JSON.parse(row['storage'].toString())
      robot.logger.debug "pg-brain loaded."

  client.on "error", (err) ->
    robot.logger.error err

  robot.brain.on 'save', (data) ->
    query = client.query("UPDATE hubot SET storage = $1", [JSON.stringify(data)])
    robot.logger.debug "pg-brain saved."

  robot.brain.on 'close', ->
    client.end()

