#!/usr/bin/env python3
"""
Script to verify ICAO codes in MasterAircraftList.csv against the official ICAO database.
Queries the ICAO Doc 8643 database.

NOTE: The ICAO database API (www4.icao.int) may be periodically unavailable for maintenance.
      Check https://www.icao.int/publications/DOC8643/Pages/Search.aspx manually if needed.

Usage:
    cd Aircraft/faa/ICAO
    python3 verify_icao.py
"""
import csv
import requests
import time
import json
import sys

def lookup_icao(type_code):
    """Query the ICAO Doc 8643 database for an aircraft type code."""
    url = 'https://www4.icao.int/doc8643/External/AircraftTypes'
    params = {'searchParam': type_code}

    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept': 'application/json',
    }

    try:
        response = requests.get(url, params=params, headers=headers, timeout=15)
        if response.status_code == 200:
            # Check if we got HTML (maintenance page) or JSON
            content = response.text.strip()
            if content.startswith('<'):
                # HTML response - likely maintenance page
                return None
            if not content:
                return []
            try:
                data = response.json()
                # Filter for exact type code match
                exact_matches = [r for r in data if r.get('Designator', '').upper() == type_code.upper()]
                return exact_matches if exact_matches else data
            except json.JSONDecodeError:
                return None
        else:
            return None
    except Exception as e:
        return None

def check_api_status():
    """Check if the ICAO API is available."""
    print("Checking ICAO API status...")
    url = 'https://www4.icao.int/doc8643/External/AircraftTypes'
    params = {'searchParam': 'A320'}  # Test with common code

    try:
        response = requests.get(url, params=params, timeout=15)
        if response.status_code == 200:
            content = response.text.strip()
            if content.startswith('<'):
                # HTML response - check for maintenance message
                if 'maintenance' in content.lower():
                    print("\n*** ICAO DATABASE IS CURRENTLY IN MAINTENANCE ***")
                    print("Please try again later or check manually at:")
                    print("https://www.icao.int/publications/DOC8643/Pages/Search.aspx")
                    return False
            else:
                try:
                    data = response.json()
                    if data:
                        print("API is available and responding.")
                        return True
                except:
                    pass
        print("API returned unexpected response.")
        return False
    except Exception as e:
        print(f"API connection error: {e}")
        return False

def main():
    # Check API status first
    if not check_api_status():
        print("\nExiting due to API unavailability.")
        sys.exit(1)

    # Read our aircraft list
    aircraft = []
    with open('../MasterAircraftList.csv', 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        for row in reader:
            if len(row) >= 5:
                aircraft.append({
                    'icao': row[0],
                    'manufacturer': row[1],
                    'model': row[2],
                    'engine_type': row[3],
                    'num_engines': row[4]
                })

    print(f"\nLoaded {len(aircraft)} aircraft from MasterAircraftList.csv")

    # Get unique ICAO codes (skip XXXX)
    icao_codes = set()
    for a in aircraft:
        if a['icao'] != 'XXXX':
            icao_codes.add(a['icao'])

    print(f"Found {len(icao_codes)} unique ICAO codes to verify")

    # Test with a few codes first
    test_codes = ['C182', 'B738', 'A320', 'PA28', 'SR22', 'BE9L']

    print("\n" + "="*60)
    print("TESTING API WITH SAMPLE CODES")
    print("="*60 + "\n")

    api_working = False
    for code in test_codes:
        print(f"Looking up: {code}")
        results = lookup_icao(code)
        if results and len(results) > 0:
            api_working = True
            print(f"  Found {len(results)} result(s)")
            for r in results[:2]:
                mfg = r.get('Manufacturer', r.get('ManufacturerCode', 'N/A'))
                model = r.get('ModelFullName', r.get('Model', 'N/A'))
                eng_count = r.get('EngineCount', 'N/A')
                eng_type = r.get('EngineType', 'N/A')
                print(f"    → {mfg} {model}")
                print(f"      Engines: {eng_count} x {eng_type}")
        elif results is not None:
            print(f"  NOT FOUND in ICAO database")
        else:
            print(f"  ERROR during lookup (API may be unavailable)")
        time.sleep(0.5)

    if not api_working:
        print("\n*** API does not appear to be working. Please try again later. ***")
        sys.exit(1)

    # Verify all codes
    print("\n" + "="*60)
    print(f"VERIFYING ALL {len(icao_codes)} ICAO CODES")
    print(f"Estimated time: {len(icao_codes) * 0.6 / 60:.1f} minutes")
    print("="*60 + "\n")

    valid_codes = []
    invalid_codes = []
    errors = []

    sorted_codes = sorted(icao_codes)
    total = len(sorted_codes)

    for i, code in enumerate(sorted_codes):
        results = lookup_icao(code)

        if results and len(results) > 0:
            valid_codes.append((code, results))
        elif results is not None:
            invalid_codes.append(code)
        else:
            errors.append(code)

        # Progress update
        if (i + 1) % 50 == 0:
            print(f"  Progress: {i+1}/{total} codes checked...")
            print(f"    Valid: {len(valid_codes)}, Invalid: {len(invalid_codes)}, Errors: {len(errors)}")

        # Rate limiting
        time.sleep(0.5)

    # Summary
    print("\n" + "="*60)
    print("VERIFICATION SUMMARY")
    print("="*60)
    print(f"Total unique ICAO codes checked: {total}")
    print(f"Valid codes (found in ICAO DB):  {len(valid_codes)}")
    print(f"Invalid codes (not found):       {len(invalid_codes)}")
    print(f"Errors during lookup:            {len(errors)}")

    if invalid_codes:
        print(f"\nInvalid/Unknown ICAO codes ({len(invalid_codes)}):")
        for code in sorted(invalid_codes)[:30]:
            our_aircraft = [a for a in aircraft if a['icao'] == code]
            if our_aircraft:
                print(f"  {code}: {our_aircraft[0]['manufacturer']} {our_aircraft[0]['model']}")
        if len(invalid_codes) > 30:
            print(f"  ... and {len(invalid_codes) - 30} more")

    # Save detailed results
    with open('icao_verification_results.txt', 'w') as f:
        f.write("ICAO Code Verification Results\n")
        f.write("="*60 + "\n\n")

        f.write(f"Total codes checked: {total}\n")
        f.write(f"Valid codes: {len(valid_codes)}\n")
        f.write(f"Invalid codes: {len(invalid_codes)}\n")
        f.write(f"Errors: {len(errors)}\n\n")

        f.write("INVALID CODES (not in ICAO database):\n")
        f.write("-"*40 + "\n")
        for code in sorted(invalid_codes):
            our_aircraft = [a for a in aircraft if a['icao'] == code]
            if our_aircraft:
                f.write(f"{code}: {our_aircraft[0]['manufacturer']} {our_aircraft[0]['model']}\n")

        f.write("\n\nERROR CODES (lookup failed):\n")
        f.write("-"*40 + "\n")
        for code in sorted(errors):
            our_aircraft = [a for a in aircraft if a['icao'] == code]
            if our_aircraft:
                f.write(f"{code}: {our_aircraft[0]['manufacturer']} {our_aircraft[0]['model']}\n")

        f.write("\n\nVALID CODES - COMPARISON:\n")
        f.write("-"*40 + "\n")
        for code, results in sorted(valid_codes):
            our_aircraft = [a for a in aircraft if a['icao'] == code]
            f.write(f"\n{code}:\n")
            if our_aircraft:
                f.write(f"  OURS: {our_aircraft[0]['manufacturer']} - {our_aircraft[0]['model']}\n")
            for r in results[:2]:
                mfg = r.get('Manufacturer', r.get('ManufacturerCode', 'N/A'))
                model = r.get('ModelFullName', r.get('Model', 'N/A'))
                f.write(f"  ICAO: {mfg} - {model}\n")

    print(f"\nDetailed results saved to icao_verification_results.txt")

if __name__ == '__main__':
    main()
