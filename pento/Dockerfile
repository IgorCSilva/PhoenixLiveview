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