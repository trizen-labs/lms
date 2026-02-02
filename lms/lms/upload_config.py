"""
Configuration for large file uploads in Frappe LMS
"""

import frappe
from frappe import _
import os

def get_max_file_size():
    """Get maximum file size allowed for uploads"""
    # Return 1GB in bytes by default
    return frappe.get_site_config().get("max_file_size", 1024 * 1024 * 1024)

def validate_file_size(file_size):
    """Validate file size against maximum allowed"""
    max_size = get_max_file_size()
    if file_size > max_size:
        frappe.throw(
            _("File size ({0}) exceeds maximum allowed size ({1})").format(
                frappe.utils.file_size(file_size), 
                frappe.utils.file_size(max_size)
            )
        )

@frappe.whitelist()
def get_upload_limits():
    """Get upload limits for frontend"""
    return {
        "max_file_size": get_max_file_size(),
        "max_file_size_mb": get_max_file_size() // (1024 * 1024),
        "allowed_video_formats": ["mp4", "webm", "ogg", "mov", "avi", "mkv"],
        "allowed_audio_formats": ["mp3", "wav", "ogg", "m4a", "flac", "aac"],
        "allowed_document_formats": ["pdf", "doc", "docx", "ppt", "pptx", "txt"]
    }