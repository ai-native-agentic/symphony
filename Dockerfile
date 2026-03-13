FROM elixir:1.19 AS builder

WORKDIR /app

# Copy mix files from elixir/ subdirectory
COPY elixir/mix.exs elixir/mix.lock ./

# Get dependencies (prod only)
RUN mix deps.get --only prod

# Copy source code
COPY elixir/lib lib
COPY elixir/config config
COPY elixir/priv priv

# Build release
RUN MIX_ENV=prod mix release

# Runtime stage
FROM ubuntu:jammy

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/symphony_elixir /app

WORKDIR /app

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

CMD ["bin/symphony_elixir", "start"]
