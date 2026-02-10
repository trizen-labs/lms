# Backing up a Frappe Site in Docker
cd portal
bench --site portal.capilingua.com backup

# This will create two backup files and their path

exit

# Check the files are created
docker exec learning_prod_setup-backend-1 ls /home/frappe/frappe-bench/sites/portal.capilingua.com/private/backups

# Copy the two files into the local backup folder
# Replace file paths
docker cp learning_prod_setup-backend-1:/home/frappe/frappe-bench/sites/portal.capilingua.com/private/backups/20260210_071204-portal_capilingua_com-site_config_backup.json ~/backups/
docker cp learning_prod_setup-backend-1:/home/frappe/frappe-bench/sites/portal.capilingua.com/private/backups/20260210_071204-portal_capilingua_com-database.sql.gz ~/backups/


# Upgrading the image to a new version

# Pull the new image
docker pull ghcr.io/trizen-labs/lms:v1.0.1-alpha.3

# Change to portal folder
cd portal

# Update the docker compose setup
python3 easy-install2.py upgrade -n learning_prod_setup -i ghcr.io/trizen-labs/lms -v v1.0.1-alpha.3

# This would override the config back to original. We need to fix the upload size again
# Verify this by uploading a large video file to a course and api fails with 413 Content Too Large
# Open learning_prod_setup-compose.yml (in home directory) file using nano
nano learning_prod_setup-compose.yml

# Change CLIENT_MAX_BODY_SIZE: 50m to 200m (Found under frontend section)
# Save and exit (Ctrl + X, Y, Enter)
# Restart and recreate the docker containers
docker compose -f learning_prod_setup-compose.yml up -d --force-recreate

# Upload a video to test course and verify