# Changelog

## v0.1.4

We're back to being secure!

- Implemented non-root user for script execution
  - Now requires docker group GID
  - MacOS would require forwarding of docker.sock from another container (such as alpine/socat)
- Changed to stop-start instead of restart for containers
- Ensured compatibility with no-new-privileges
- Now logs container_name instead of container_id for better readability

## v0.1.3

This container was encountering issues when attempting to call the docker endpoint.
In a future release I would like to re-implement this user with a solution in mind for being able to access docker.sock

- Resolved permissions issues
- Removed scheduler user

## v0.1.2

- Add linux/amd64 support
- Migrate to multi-stage build
- Simplify logging output
- Add healthcheck
- Add OCI annotations
