#!/usr/bin/env python3
"""
Scrape airline ICAO/IATA codes from airlinecodes.info

Extracts airline codes from multiple pages (A-Z, 0-9) and saves to CSV.
Uses only built-in Python libraries (no pip install required).

Usage:
    python3 scrape_airline_codes.py
"""

import csv
import time
import re
import urllib.request
import urllib.error
from html.parser import HTMLParser
from pathlib import Path

# Configuration
BASE_URL = "https://www.airlinecodes.info/icao"
OUTPUT_FILE = Path(__file__).parent / "AirlineCodes.csv"

# Pages to scrape: A-Z and 0-9
PAGES = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ") + list("0123456789")


class TableParser(HTMLParser):
    """Parse HTML table to extract airline data."""

    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.current_row = []
        self.current_cell = ""
        self.rows = []

    def handle_starttag(self, tag, attrs):
        if tag == "table":
            self.in_table = True
        elif tag == "tr" and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag == "td" and self.in_row:
            self.in_cell = True
            self.current_cell = ""

    def handle_endtag(self, tag):
        if tag == "table":
            self.in_table = False
        elif tag == "tr" and self.in_row:
            self.in_row = False
            if self.current_row:
                self.rows.append(self.current_row)
        elif tag == "td" and self.in_cell:
            self.in_cell = False
            self.current_row.append(self.current_cell.strip())

    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data


def scrape_page(letter: str) -> list[dict]:
    """Scrape a single page of airline codes."""
    url = f"{BASE_URL}/{letter}"
    print(f"  Fetching {url}...")

    try:
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
            }
        )
        with urllib.request.urlopen(req, timeout=30) as response:
            html = response.read().decode("utf-8")
    except urllib.error.URLError as e:
        print(f"    Error fetching {url}: {e}")
        return []

    # Parse HTML table
    parser = TableParser()
    parser.feed(html)

    airlines = []
    for row in parser.rows:
        if len(row) >= 3:
            icao = row[0]
            iata = row[1]
            airline = row[2]

            # Skip header row
            if icao and icao.upper() != "ICAO":
                airlines.append({
                    "icao": icao,
                    "iata": iata if iata and iata != "-" else "",
                    "airline": airline
                })

    print(f"    Found {len(airlines)} airlines")
    return airlines


def main():
    """Main function to scrape all pages and save to CSV."""
    print("Scraping airline codes from airlinecodes.info...")
    print(f"Output file: {OUTPUT_FILE}")
    print()

    all_airlines = []

    for letter in PAGES:
        airlines = scrape_page(letter)
        all_airlines.extend(airlines)

        # Be polite - wait between requests
        time.sleep(0.5)

    print()
    print(f"Total airlines scraped: {len(all_airlines)}")

    # Remove duplicates based on ICAO code
    seen_icao = set()
    unique_airlines = []
    for airline in all_airlines:
        if airline["icao"] not in seen_icao:
            seen_icao.add(airline["icao"])
            unique_airlines.append(airline)

    print(f"Unique airlines (by ICAO): {len(unique_airlines)}")

    # Sort by ICAO code
    unique_airlines.sort(key=lambda x: x["icao"])

    # Write to CSV
    print(f"\nWriting to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["icao", "iata", "airline"])
        writer.writeheader()
        writer.writerows(unique_airlines)

    print("Done!")

    # Show sample
    print("\nSample records:")
    for airline in unique_airlines[:5]:
        print(f"  {airline['icao']}: {airline['iata'] or '(no IATA)'} - {airline['airline']}")


if __name__ == "__main__":
    main()
