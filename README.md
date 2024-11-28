# Docker Container Scheduler

A lightweight, secure Docker container that automates the scheduling of Docker container restarts based on labels. Built on Alpine Linux and uses [supercronic](https://github.com/aptible/supercronic) for reliable cron job execution.

## Features

- Schedule container restarts using Docker labels
- Support for hourly, daily, weekly, and monthly restart schedules
- Use API calls instead of Docker CLI for reduced image size
- Automatic log rotation
- Minimal Alpine-based image
- Runs as non-root user
- Secure by default with no-new-privileges
- Timezone support

## Host Architecture

- [x] linux/amd64
- [x] linux/arm64
- [ ] macos/arm64

## To-do / Roadmap

- [x] Ensure workflow only runs on version releases
- [x] Multi-stage build for smaller images
- [x] Script execution as non-root user
  - [x] Verify Linux
  - [ ] Verify MacOS
    - [ ] Requires [alpine/socat](https://forums.docker.com/t/mounting-using-var-run-docker-sock-in-a-container-not-running-as-root/34390/8)
- [x] Implement no-new-privileges
- [x] Change from restart to stop-start
- [ ] Provide configuration for schedules
- [ ] Add webhook functionality for notifications

## Quick Start

```bash
docker run -d \
  --name container-scheduler \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e HOST_DOCKER_GID=your-gid-here \
  -e TZ=Australia/Melbourne \
  --security-opt no-new-privileges=true \
  ghcr.io/tanakrit-d/container-scheduler:latest
```

Note: You can get your docker GID with `getent group docker | cut -d: -f3`

## Using Docker Compose

Linux:

```yaml
services:
  container-scheduler:
    image: ghcr.io/tanakrit-d/container-scheduler:latest
    container_name: container-scheduler
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /path/to/your/logs:/var/log
    environment:
      - HOST_DOCKER_GID=your-gid-here
      - TZ=Australia/Melbourne
    security_opt:
      - no-new-privileges:true
```

MacOS (untested):

```yaml
services:
  socat:
    image: alpine/socat
    command: tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
    user: root
    volumes:
      - type: bind
        source: /var/run/docker.sock
        target: /var/run/docker.sock

  container-scheduler:
    image: ghcr.io/tanakrit-d/container-scheduler:latest
    container_name: container-scheduler
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /path/to/your/logs:/var/log
    environment:
      - DOCKER_HOST=localhost:2375
      - HOST_DOCKER_GID=your-gid-here
      - TZ=Australia/Melbourne
    security_opt:
      - no-new-privileges:true
```

## Scheduling Container Restarts

To schedule a container for automatic restarts, simply add a label to your container definition:

```yaml
services:
  cool-service:
    image: cool-service-image
    labels:
      - "restart-group=hourly"  # Options: hourly, daily, weekly, monthly
```

### Available Schedule Groups

- `hourly`: Restarts every hour at minute 0
- `daily`: Restarts daily at midnight
- `weekly`: Restarts weekly on Sunday at midnight
- `monthly`: Restarts monthly on first day at midnight

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| HOST_DOCKER_GID | Docker Group ID | None |
| TZ | Container timezone | UTC |

### Volumes

| Path | Description | Required |
|------|-------------|----------|
| `/var/run/docker.sock` | Docker socket for container management | Yes |
| `/var/log` | Log directory | No |

## Building from Source

1. Clone the repository:

    ```bash
    git clone https://github.com/tanakrit-d/container-scheduler.git
    cd container-scheduler
    ```

2. Build the image:

    ```bash
    #linux/amd64
    docker build --build-arg TARGETARCH=amd64 -t container-scheduler .
    #linux/arm64
    docker build --build-arg TARGETARCH=arm64 -t container-scheduler .
    ```

## Log Files

Logs are written to `/var/log/cron.log` and are automatically rotated every 28 days. You can access the logs by mounting the `/var/log` directory or by using `docker logs`:

```bash
docker logs container-scheduler
```

Example: `cron.log`

```log
[2024-11-28 18:00:00] Restarting hourly containers: alpine
[2024-11-28 18:00:00] Successfully restarted containers: alpine
```

## Security Considerations

This container:

- Executes the script as a non-root user
- Uses no-new-privileges security option
- Requires minimal permissions through Docker socket

## Contributing

Contributions or feedback is welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any issues or have questions, please file an issue on the GitHub repository.
