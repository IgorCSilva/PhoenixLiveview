#!/bin/bash

if [ $MIX_ENV = "prod" ];
then
  ./prod/rel/pento/bin/pento eval Pento.Release.migrate
  ./prod/rel/pento/bin/pento start
else
  # Fetch the application dependencies
  mix deps.get

  # Wait until Postgres is ready
  while ! pg_isready -q -h $DB_HOSTNAME -p $DB_PORT -U $DB_USERNAME
  do
    echo "$(date) - waiting for database to start"
    sleep 2
  done

  # Migrate and seed database.
  mix ecto.migrate
  # mix run priv/repo/seeds.exs
  echo "Database $DB_DATABASE done."

  exec mix phx.server
fi