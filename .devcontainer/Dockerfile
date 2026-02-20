# debian trixie base with curl and certificate tools
FROM debian:trixie-slim

# install curl and certificate tools
RUN apt-get update && apt-get install -y curl ca-certificates && rm -rf /var/lib/apt/lists/*