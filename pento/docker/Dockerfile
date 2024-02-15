# Extend from the official Elixir image
FROM elixir:1.14

RUN apt-get update && \
  apt-get install -y postgresql-client

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY . /app
WORKDIR /app

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force && mix local.rebar --force

# Fetch the application dependencies and build the application
RUN mix deps.compile

RUN chmod -R 777 /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]