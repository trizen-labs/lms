#!/bin/bash

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd frappe-bench
    
    # Configure large file upload settings
    echo "Configuring large file upload settings..."
    bench --site lms.localhost set-config max_file_size 1073741824
    bench --site lms.localhost set-config limits '{"post_data_size": 1073741824, "file_size": 1073741824}'
    bench --site lms.localhost set-config upload_timeout 600
    bench --site lms.localhost set-config socketio_ping_timeout 600000
    bench --site lms.localhost set-config socketio_ping_interval 25000
    
    bench start
else
    echo "Creating new bench..."
fi

export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin/:${PATH}"

bench init --skip-redis-config-generation frappe-bench

cd frappe-bench

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Remove redis, watch from Procfile
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

bench get-app lms

bench new-site lms.localhost \
--force \
--mariadb-root-password 123 \
--admin-password admin \
--no-mariadb-socket

bench --site lms.localhost install-app lms

# Configure large file upload settings for new site
echo "Configuring large file upload settings for new site..."
bench --site lms.localhost set-config max_file_size 1073741824
bench --site lms.localhost set-config limits '{"post_data_size": 1073741824, "file_size": 1073741824}'
bench --site lms.localhost set-config upload_timeout 600
bench --site lms.localhost set-config socketio_ping_timeout 600000
bench --site lms.localhost set-config socketio_ping_interval 25000

bench --site lms.localhost set-config developer_mode 1
bench --site lms.localhost clear-cache
bench use lms.localhost

bench start
