# Use a lightweight base image, e.g., Debian slim
FROM debian:bullseye-slim

# Define build arguments for the image. This can be overridden at build time.
ARG DEFAULT_CONTAINER_TIMEZONE="Europe/Amsterdam"
ARG DEFAULT_MYSQL_HOST="mariadb"
ARG DEFAULT_MYSQL_ROOT_PASSWORD="rootpw"
ARG DEFAULT_MYSQL_DATABASE="domjudge"
ARG DEFAULT_CRON_SCHEDULE="0 0 * * *"
ARG DEFAULT_MAX_NUM_BACKUPS_TO_KEEP="20"
ARG DEFAULT_CREATE_CHECKSUMS="false"
ARG DEFAULT_TABLES_TO_EXCLUDE_IN_CHECKSUM=""
ARG DEFAULT_REMOVE_CHECKSUM_EQUIV_PREVIOUS_BACKUP="false"
ARG DEFAULT_LOGFILE="/backups/backup.log"


# Set the default schedule as an environment variable in the image.
# This variable's value can be overridden at runtime via a docker-compose.yml.
ENV CONTAINER_TIMEZONE="${DEFAULT_CONTAINER_TIMEZONE}"
ENV MYSQL_HOST="${DEFAULT_MYSQL_HOST}"
ENV MYSQL_ROOT_PASSWORD="${DEFAULT_MYSQL_ROOT_PASSWORD}"
ENV MYSQL_DATABASE="${DEFAULT_MYSQL_DATABASE}"
ENV CRON_SCHEDULE="${DEFAULT_CRON_SCHEDULE}"
ENV MAX_NUM_BACKUPS_TO_KEEP="${DEFAULT_MAX_NUM_BACKUPS_TO_KEEP}"
ENV CREATE_CHECKSUMS="${DEFAULT_CREATE_CHECKSUMS}"
ENV TABLES_TO_EXCLUDE_IN_CHECKSUM="${DEFAULT_TABLES_TO_EXCLUDE_IN_CHECKSUM}"
ENV REMOVE_CHECKSUM_EQUIV_PREVIOUS_BACKUP="${DEFAULT_REMOVE_CHECKSUM_EQUIV_PREVIOUS_BACKUP}"
ENV LOGFILE="${DEFAULT_LOGFILE}"


# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

# Install necessary packages: mariadb-client for mariadb-dump and cron
RUN apt-get update && \
    apt-get install -y mariadb-client cron coreutils && \
    rm -rf /var/lib/apt/lists/*

# Copy the backup scripts into the container
# We use /app/ for the scripts to separate them from the standard image.
ENV PATH="/app:${PATH}"
# we use INSIDE_DOCKER_CTR to make backup script to run mariadb-dump directly instead of via docker exec
ENV INSIDE_DOCKER_CTR=true

# copy the scripts into the image
COPY bin/mariadb-backup /app/mariadb-backup
COPY bin/mariadb-restore-backup /app/mariadb-restore-backup
COPY bin/mariadb-backup-checksum /app/mariadb-backup-checksum
COPY bin/mariadb-rolling-backup /app/mariadb-rolling-backup
COPY bin/mariadb-get-maximum-blob-size-in-bytes-in-database /app/mariadb-get-maximum-blob-size-in-bytes-in-database

# install launch script for docker container
# this script sets up the crontab and starts cron in the background
# is uses the environment variables defined above
# and then runs cron in the background and tails the log file to keep the container running
COPY bin/container-start /app/container-start 


# Make the scripts executable
RUN chmod +x /app/mariadb-backup /app/mariadb-restore-backup /app/mariadb-backup-checksum /app/mariadb-rolling-backup /app/container-start /app/mariadb-get-maximum-blob-size-in-bytes-in-database 
CMD ["/app/container-start"]



