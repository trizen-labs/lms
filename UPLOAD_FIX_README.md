# Fix for 413 Request Entity Too Large Error

## Overview

This document outlines the fixes implemented to resolve the 413 REQUEST ENTITY TOO LARGE error when uploading large video and audio files to the LMS system.

## Changes Made

### 1. Added Nginx Configuration (`docker/nginx.conf`)

- Set `client_max_body_size` to 1GB (1024m)
- Increased timeout values for large file uploads
- Added special handling for upload endpoints
- Configured efficient static file serving for media files

### 2. Updated Docker Compose (`docker/docker-compose.yml`)

- Added nginx service as reverse proxy
- Configured MariaDB with `max_allowed_packet=1073741824` (1GB)
- Exposed Frappe ports internally and used nginx as the entry point

### 3. Enhanced Frappe Configuration (`docker/init.sh`)

- Set `max_file_size` to 1GB (1073741824 bytes)
- Configured `post_data_size` and upload timeout limits
- Added socket.io timeout configurations

### 4. Frontend Validation Updates (`frontend/src/utils/index.js`)

- Enhanced `validateFile` function to check file size against server limits
- Added dynamic file size validation based on server configuration
- Improved error messages for file size violations

### 5. Backend Upload Configuration (`lms/lms/upload_config.py`)

- Created centralized upload configuration module
- Added whitelisted API endpoints for frontend to fetch limits
- Defined supported file formats for different media types

## How to Apply the Fix

1. **Rebuild Docker containers:**

   ```bash
   docker-compose down
   docker-compose up --build
   ```

2. **Access the application:**
   - The application will now be available at `http://localhost` (port 80)
   - Nginx will handle the reverse proxy to the Frappe application

3. **Test large file uploads:**
   - Users should now be able to upload files up to 1GB in size
   - The system supports various video formats (mp4, webm, ogg, mov, avi, mkv)
   - Audio formats include mp3, wav, ogg, m4a, flac, aac

## Configuration Details

### File Size Limits

- **Maximum file size:** 1GB (1,073,741,824 bytes)
- **Upload timeout:** 600 seconds (10 minutes)
- **Buffer sizes:** Optimized for large file handling

### Supported Formats

- **Video:** mp4, webm, ogg, mov, avi, mkv
- **Audio:** mp3, wav, ogg, m4a, flac, aac  
- **Documents:** pdf, doc, docx, ppt, pptx, txt

### Performance Optimizations

- Disabled proxy buffering for large uploads
- Set appropriate cache headers for static files
- Configured gzip compression for text-based files

## Troubleshooting

If you still encounter upload issues:

1. **Check container logs:**

   ```bash
   docker-compose logs nginx
   docker-compose logs frappe
   ```

2. **Verify site configuration:**

   ```bash
   docker-compose exec frappe bench --site lms.localhost show-config
   ```

3. **Monitor upload progress in browser developer tools**

4. **For very large files (>1GB), consider:**
   - Increasing the limits further in the configuration files
   - Implementing chunked upload for better user experience
   - Using cloud storage services for extremely large files

## Security Considerations

- File type validation is maintained
- SVG files are scanned for malicious content
- Upload size limits prevent abuse
- Only authenticated users can upload files (based on existing LMS permissions)
