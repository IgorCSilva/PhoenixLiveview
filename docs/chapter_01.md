# Get To Know LiveView

- Create project:
`mix phx.new pento --live`

- Create docker-compose file in pento/docker-compose.yaml:
```yaml
version: '3.5'
services:
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
    container_name: pento
    env_file:
      - .env
    volumes:
      - .:/app
    ports:
      - "4000:4000"
    depends_on:
      - db
    networks:
      - pento_network

  db:
    image: postgres
    container_name: pento_database
    environment:
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_DATABASE}
    restart: always
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - pento_network

volumes:
  pgdata:

networks:
  pento_network:
```

- Create .env file in pento/.env:
```
#General Configuration
SECRET_KEY_BASE=O77V2l/qes1eO5flhQOAZ8wl3ldLEWj3Re67iGSDNYJPRndUVGDK895BhPfiRFyv #mix phx.gen.secret

#DB Configuration
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_HOSTNAME=db
DB_PORT=5432
DB_DATABASE=pento_dev
DB_DATABASE_TEST=pento_test
```

- Create the Dockerfile in pento/Dockerfile:
```dockerfile
FROM elixir:1.11.2-alpine AS build

# Set environment variables for building the application
ENV MIX_ENV=prod \
    TEST=1 \
    LANG=C.UTF-8

# install build dependencies
# RUN apk add --no-cache build-base npm git python
RUN apk add --no-cache build-base
RUN apk add --no-cache git
RUN apk add --no-cache postgresql-client
RUN apk add --no-cache bash

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create the application build directory
RUN mkdir /app
WORKDIR /app

# Copy over all the necessary application files and directories
COPY config ./config
COPY doc ./doc
COPY lib ./lib
COPY priv ./priv
COPY mix.exs .
COPY mix.lock .

# Fetch the application dependencies and build the application
RUN mix deps.get
RUN mix deps.compile
RUN mix phx.digest
RUN mix release

# ---- Application Stage ----
FROM alpine:3.9 AS app

ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Install openssl
RUN apk add --update openssl ncurses-libs bash postgresql-client && \
    rm -rf /var/cache/apk/*

# Copy over the build artifact from the previous step and create a non root user
RUN adduser -D -h /home/app app
WORKDIR /home/app
COPY --from=build /app/_build .
RUN chown -R app: ./prod
USER app

COPY entrypoint.sh .

# Run the Phoenix app
CMD ["./entrypoint.sh"]
```

- Create dockerfile in pento/docker/Dockerfile:
```dockerfile
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
```

- Create entrypoint file in pento/entrypoint.sh:
```sh
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
```

- in pento/config/dev.exs:
```elixir
# Configure your database
config :pento, Pento.Repo,
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_DATABASE"),
  hostname: System.get_env("DB_HOSTNAME"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

  ...

config :pento, PentoWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  ...
```

- in :
```elixir
config :pento, Pento.Repo,
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_DATABASE_TEST"),
  hostname: System.get_env("DB_HOSTNAME"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

  ...
```

Executar:
`sudo chmod +x ./entrypoint.sh`

Para inicializar o projeto executar: `docker-compose up --build`
Se ocorrer algum problema de network executar `docker network prune`

## The LiveView Livecycle
### Hold State in LiveView Sockets
Live views are about state, and LiveView manages state in structs called sockets.

Run `iex -S mix`.
Then `iex> h Phoenix.LiveView.Socket`. You will see some description about LiveView.Socket.
Run `iex> Phoenix.LiveView.Socket.__struct__`.

You will see:
```elixir
#Phoenix.LiveView.Socket<
  id: nil,
  endpoint: nil,
  view: nil,
  parent_pid: nil,
  root_pid: nil,
  router: nil,
  assigns: %{__changed__: %{}},
  transport_pid: nil,
  ...
>
```

The most important key, and the one you’ll interact with most frequently in your live views, is assigns.
Every running live view keeps data describing state in a socket. You’ll establish and update that state by interacting with the socket struct’s :assigns key.

## Build a Simple Live View

### Define the Route
- in pento/lib/pento_web/router.ex:
```elixir
  scope "/", PentoWeb do
    pipe_through :browser

    ...
    live "/guess", WrongLive
  end
```

### Render the Live View
- in pento/lib/pento_web/live/wrong_live.ex:
```elixir
defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(
        socket,
        score: 0,
        message: "Guess a number."
      )
    }
  end

  def render(assigns) do
    ~L"""
    <h1>Your score: <%= @score %></h1>
    <h2>
      <%= @message %>
    </h2>
    <h2>
      <%= for n <- 1..10 do %>
        <a href="#" phx-click="guess" phx-value-number="<%= n %>"><%= n %></a>
      <% end %>
    </h2>
    """
  end


  def handle_event("guess", %{"number" => guess} = data, socket) do
    IO.inspect(data)
    message = "Your guess: #{guess}. Wrong. Guess again. "
    score = socket.assigns.score - 1

    {
      :noreply,
      assign(
        socket,
        message: message,
        score: score
      )
    }
  end
end
```

## LiveView Transfers Data Efficiently.
### Send Network Diffs

- in pento/lib/pento_web/live/wrong_live.ex:
```elixir
  def render(assigns) do
    ~L"""
    <h1>Your score: <%= @score %></h1>
    <h2>
      <%= @message %>
      It's <%= time() %>
    </h2>
    <h2>
      <%= for n <- 1..10 do %>
        <a href="#" phx-click="guess" phx-value-number="<%= n %>"><%= n %></a>
      <% end %>
    </h2>
    """
  end

  def time() do
    DateTime.utc_now() |> to_string()
  end
```

Accessing the page and making a guess, the time keep the same. The problem is that we didn’t give LiveView any way to determine that the value should change and be re-rendered.

