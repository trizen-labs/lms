# Backing up a Frappe Site in Docker

## Step 1: Navigate to the Portal Directory
```bash
cd portal
```

## Step 2: Execute into the Docker Container and Run Backup
```bash
python3 easy-install2.py exec -n learning_prod_setup
bench --site portal.capilingua.com backup
```

This will create two backup files and display their paths.

```bash
exit
```

## Step 3: Verify Backup Files
```bash
docker exec learning_prod_setup-backend-1 ls /home/frappe/frappe-bench/sites/portal.capilingua.com/private/backups
```

## Step 4: Copy Backup Files to Local Folder
Replace the file paths with the actual ones from the backup output.

```bash
docker cp learning_prod_setup-backend-1:/home/frappe/frappe-bench/sites/portal.capilingua.com/private/backups/20260210_071204-portal_capilingua_com-site_config_backup.json ~/backups/
docker cp learning_prod_setup-backend-1:/home/frappe/frappe-bench/sites/portal.capilingua.com/private/backups/20260210_071204-portal_capilingua_com-database.sql.gz ~/backups/
```

# Upgrading the Image to a New Version

## Step 1: Pull the New Image
```bash
docker pull ghcr.io/trizen-labs/lms:v1.0.1-alpha.3
```

## Step 2: Navigate to the Portal Directory
```bash
cd portal
```

## Step 3: Update the Docker Compose Setup
```bash
python3 easy-install2.py upgrade -n learning_prod_setup -i ghcr.io/trizen-labs/lms -v v1.0.1-alpha.3
```

Note: This may override the config back to original. We need to fix the upload size again. Verify this by uploading a large video file to a course; the API may fail with "413 Content Too Large".

## Step 4: Edit the Compose File
Open the `learning_prod_setup-compose.yml` file (in the home directory) using nano:

```bash
nano learning_prod_setup-compose.yml
```

Change `CLIENT_MAX_BODY_SIZE: 50m` to `200m` (found under the frontend section). Save and exit (Ctrl + X, Y, Enter).

## Step 5: Restart and Recreate Docker Containers
```bash
docker compose -f learning_prod_setup-compose.yml up -d --force-recreate
```

## Step 6: Test the Upload
Upload a video to a test course and verify that it works.