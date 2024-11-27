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

- linux/amd64  
- linux/arm46  

## To-do / Roadmap

- [x] Ensure workflow only runs on version releases
- [x] Multi-stage build for smaller images
- [ ] Provide configuration for schedules
- [x] Migrate to non-root user
  - [x] Linux implementation
  - [ ] MacOS implementation
    - [ ] Add [apline/socat](https://forums.docker.com/t/mounting-using-var-run-docker-sock-in-a-container-not-running-as-root/34390/8)
    - [ ] Update docker-compose example to utilise this
- [ ] Implement no-new-privileges
- [ ] Change from restart to stop-start
- [ ] Add webhook functionality for notifications

## Quick Start

```bash
docker run -d \
  --name container-scheduler \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e TZ=Australia/Melbourne \
  --security-opt no-new-privileges=true \
  ghcr.io/tanakrit-d/container-scheduler:latest
```

## Using Docker Compose

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

Logs are written to `/var/log/cron.log` and are automatically rotated every 7 days. You can access the logs by mounting the `/var/log` directory or by using `docker logs`:

```bash
docker logs container-scheduler
```

## Security Considerations

This container:

- Runs as a non-root user
- Uses no-new-privileges security option
- Requires minimal permissions through Docker socket

## Contributing

Contributions or feedback is welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any issues or have questions, please file an issue on the GitHub repository.
