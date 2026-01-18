#!/usr/bin/env python3
"""
Add Copyright Metadata to SVG Files

Adds copyright notices, legal warnings, and unique tracking hashes
to SVG files for Passion Highway, Inc. / Airplane-ID project.

Usage: python add_copyright.py <svg_file_or_directory>
"""

import os
import sys
import hashlib
import re
from datetime import datetime

# Copyright configuration
COPYRIGHT_YEAR = "2026"
COMPANY_NAME = "Passion Highway, Inc."
CONTACT_EMAIL = "jim@passionhighway.com"
PROJECT_PREFIX = "PHI-AID"  # Passion Highway Inc - Airplane ID

COPYRIGHT_COMMENT = f"""
  Copyright (c) {COPYRIGHT_YEAR} {COMPANY_NAME}. All Rights Reserved.

  This image is digitally signed and the hash recorded.
  Unauthorized reproduction, distribution, or use of this
  image is strictly prohibited and constitutes copyright
  infringement under 17 U.S.C. Section 106.

  Violators may be subject to civil liability including
  statutory damages up to $150,000 per work (17 U.S.C. Section 504)
  and criminal prosecution with fines and imprisonment
  (17 U.S.C. Section 506).

  Contact: {CONTACT_EMAIL}
  Asset ID: {{asset_id}}
  Hash: {{file_hash}}
"""

METADATA_TEMPLATE = f'''<metadata>
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
             xmlns:dc="http://purl.org/dc/elements/1.1/"
             xmlns:cc="http://creativecommons.org/ns#">
      <rdf:Description>
        <dc:title>{{title}}</dc:title>
        <dc:creator>{COMPANY_NAME}</dc:creator>
        <dc:rights>Copyright (c) {COPYRIGHT_YEAR} {COMPANY_NAME}. All Rights Reserved. Unauthorized use prohibited under 17 U.S.C. 106, 504, 506.</dc:rights>
        <dc:publisher>{COMPANY_NAME}</dc:publisher>
        <dc:identifier>{{asset_id}}</dc:identifier>
        <dc:source>Airplane-ID.com</dc:source>
        <cc:license rdf:resource="https://airplane-id.com/terms"/>
      </rdf:Description>
    </rdf:RDF>
  </metadata>
'''


def generate_asset_id(filename):
    """Generate a unique asset ID from filename."""
    base = os.path.splitext(os.path.basename(filename))[0]
    # Clean up the name
    clean_name = re.sub(r'[^a-zA-Z0-9]', '', base).upper()
    # Create a short hash from filename + timestamp seed
    hash_input = f"{filename}-{COPYRIGHT_YEAR}-{COMPANY_NAME}"
    short_hash = hashlib.md5(hash_input.encode()).hexdigest()[:8]
    return f"{PROJECT_PREFIX}-{clean_name}-{short_hash}"


def generate_file_hash(content):
    """Generate SHA256 hash of the SVG content (paths only)."""
    # Hash just the path data to create a content fingerprint
    paths = re.findall(r'd="([^"]+)"', content)
    path_content = ''.join(paths)
    return hashlib.sha256(path_content.encode()).hexdigest()[:16]


def get_title_from_filename(filename):
    """Generate a title from the filename."""
    base = os.path.splitext(os.path.basename(filename))[0]
    # Convert icao-C172 to "C172 Aircraft Silhouette"
    if base.startswith('icao-'):
        code = base.replace('icao-', '')
        return f"{code} Aircraft Silhouette"
    elif base.startswith('icon-'):
        name = base.replace('icon-', '').replace('-', ' ').title()
        return f"{name} Icon"
    else:
        return f"{base} Aircraft Silhouette"


def add_copyright_to_svg(filepath):
    """Add copyright metadata to an SVG file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check if already has our copyright
    if PROJECT_PREFIX in content or "Passion Highway" in content:
        print(f"  Skipping (already has copyright): {filepath}")
        return False

    # Generate IDs and hashes
    asset_id = generate_asset_id(filepath)
    file_hash = generate_file_hash(content)
    title = get_title_from_filename(filepath)

    # Prepare the copyright comment
    comment = COPYRIGHT_COMMENT.format(asset_id=asset_id, file_hash=file_hash)

    # Prepare the metadata
    metadata = METADATA_TEMPLATE.format(asset_id=asset_id, title=title)

    # Build the new SVG content
    # Remove any existing XML declaration
    content = re.sub(r'<\?xml[^?]*\?>\s*', '', content)

    # Remove any existing comments at the start
    content = re.sub(r'^<!--[\s\S]*?-->\s*', '', content.strip())

    # Find the opening svg tag
    svg_match = re.search(r'(<svg[^>]*>)', content)
    if not svg_match:
        print(f"  Error: No <svg> tag found in {filepath}")
        return False

    svg_tag = svg_match.group(1)
    svg_content_after_tag = content[svg_match.end():]

    # Build new file
    new_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<!--{comment}-->
{svg_tag}
  {metadata}
{svg_content_after_tag}'''

    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"  Added copyright: {os.path.basename(filepath)} [{asset_id}]")
    return True


def process_directory(directory):
    """Process all SVG files in a directory recursively."""
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.svg'):
                filepath = os.path.join(root, file)
                if add_copyright_to_svg(filepath):
                    count += 1
    return count


def main():
    if len(sys.argv) < 2:
        print("Usage: python add_copyright.py <svg_file_or_directory>")
        print("\nAdds copyright metadata to SVG files.")
        print(f"Company: {COMPANY_NAME}")
        print(f"Contact: {CONTACT_EMAIL}")
        sys.exit(1)

    target = sys.argv[1]

    print(f"\nAdding copyright metadata for {COMPANY_NAME}")
    print(f"=" * 50)

    if os.path.isfile(target):
        if add_copyright_to_svg(target):
            print("\n1 file updated.")
        else:
            print("\nNo files updated.")
    elif os.path.isdir(target):
        count = process_directory(target)
        print(f"\n{count} files updated.")
    else:
        print(f"Error: {target} not found")
        sys.exit(1)


if __name__ == '__main__':
    main()
