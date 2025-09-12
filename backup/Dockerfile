# Use a lightweight base image, e.g., Debian slim
FROM debian:bullseye-slim

# Define a build argument for the default schedule. This can be overridden at build time.
ARG DEFAULT_CRON_SCHEDULE="0 0 * * *"
ARG DEFAULT_ROLLING_BACKUP_OPTIONS="-d /backups -k 20"
ARG DEFAULT_LOGFILE="/backups/backup.log"

# Set the default schedule as an environment variable in the image.
# This variable's value can be overridden at runtime via a docker-compose.yml.
ENV CRON_SCHEDULE=${DEFAULT_CRON_SCHEDULE}
ENV ROLLING_BACKUP_OPTIONS=${DEFAULT_ROLLING_BACKUP_OPTIONS}
ENV LOGFILE=${DEFAULT_LOGFILE}

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
COPY bin/backup /app/backup
COPY bin/backup-checksum /app/backup-checksum
COPY bin/rolling-backup /app/rolling-backup

# Make the scripts executable
RUN chmod +x /app/backup /app/backup-checksum /app/rolling-backup

# Set up a log file
#RUN mkdir -p $(dirname ${LOGFILE}) && touch ${LOGFILE}

# Update the crontab using argument CRON_SCHEDULE, ROLLING_BACKUP_OPTIONS and LOGFILE when starting the container, 
# and then run cron in the background and follow the log file to keep the container running and show output
CMD mkdir -p $(dirname ${LOGFILE}) && touch ${LOGFILE} && printf "INSIDE_DOCKER_CTR=true\nMYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}\nMYSQL_DATABASE=${MYSQL_DATABASE}\n$CRON_SCHEDULE /app/rolling-backup $ROLLING_BACKUP_OPTIONS >> $LOGFILE 2>&1\n" | crontab - && cron && tail -f $LOGFILE


