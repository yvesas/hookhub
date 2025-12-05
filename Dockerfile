FROM elixir:1.19-alpine

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    postgresql-client

# Create app directory
WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get

# Copy application code
COPY . .

# Compile the application
RUN mix compile

# Expose port
EXPOSE 4000

# Start the application
CMD ["mix", "phx.server"]
