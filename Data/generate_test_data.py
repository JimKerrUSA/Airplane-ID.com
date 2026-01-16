#!/usr/bin/env python3
"""
Generate test data for Airplane-ID iOS app.

Combines FAA registration data with manufacturer reference and ICAO codes
to create a realistic test dataset with GPS coordinates and timestamps.

Usage:
    python3 generate_test_data.py [--count 2000]
"""

import csv
import random
from datetime import datetime, timedelta
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
FAA_AIRCRAFT = SCRIPT_DIR / "FAA-Registered-Aircraft.csv"
FAA_MANUFACTURER = SCRIPT_DIR / "FAA-Manufacturer-Reference.csv"
ICAO_MASTER = Path.home() / "dev/projects/PlaneFinder/Aircraft/faa/MasterAircraftList.csv"
OUTPUT_FILE = SCRIPT_DIR / "AirplaneID-TestData.csv"

# Major US airports with coordinates (for realistic GPS data)
US_AIRPORTS = [
    # Code, Name, Latitude, Longitude
    ("KATL", "Atlanta Hartsfield", 33.6407, -84.4277),
    ("KORD", "Chicago O'Hare", 41.9742, -87.9073),
    ("KDFW", "Dallas/Fort Worth", 32.8998, -97.0403),
    ("KDEN", "Denver International", 39.8561, -104.6737),
    ("KLAX", "Los Angeles International", 33.9416, -118.4085),
    ("KJFK", "New York JFK", 40.6413, -73.7781),
    ("KSFO", "San Francisco", 37.6213, -122.3790),
    ("KSEA", "Seattle-Tacoma", 47.4502, -122.3088),
    ("KMCO", "Orlando", 28.4312, -81.3081),
    ("KLAS", "Las Vegas McCarran", 36.0840, -115.1537),
    ("KMIA", "Miami International", 25.7959, -80.2870),
    ("KPHX", "Phoenix Sky Harbor", 33.4373, -112.0078),
    ("KIAH", "Houston Bush", 29.9902, -95.3368),
    ("KMSP", "Minneapolis-St Paul", 44.8848, -93.2223),
    ("KDTW", "Detroit Metro", 42.2162, -83.3554),
    ("KBOS", "Boston Logan", 42.3656, -71.0096),
    ("KFLL", "Fort Lauderdale", 26.0742, -80.1506),
    ("KEWR", "Newark Liberty", 40.6895, -74.1745),
    ("KSLC", "Salt Lake City", 40.7899, -111.9791),
    ("KSAN", "San Diego", 32.7338, -117.1933),
    # Smaller regional airports for variety
    ("KOSH", "Oshkosh Wittman", 43.9844, -88.5570),
    ("KAPA", "Denver Centennial", 39.5701, -104.8493),
    ("KVNY", "Van Nuys", 34.2098, -118.4897),
    ("KTEB", "Teterboro", 40.8501, -74.0608),
    ("KPDK", "Atlanta DeKalb-Peachtree", 33.8756, -84.3020),
    ("KFRG", "Farmingdale Republic", 40.7288, -73.4134),
    ("KSDL", "Scottsdale", 33.6229, -111.9107),
    ("KADS", "Dallas Addison", 32.9686, -96.8364),
    ("KHPN", "White Plains Westchester", 41.0670, -73.7076),
    ("KPWK", "Chicago Executive", 42.1142, -87.9015),
]


def load_manufacturer_reference():
    """Load FAA manufacturer reference into a dict keyed by MFR-CODE."""
    manufacturers = {}
    with open(FAA_MANUFACTURER, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            code = row.get('MFR-CODE', '').strip()
            if code:
                manufacturers[code] = {
                    'manufacturer': row.get('MANUFACTURER', '').strip(),
                    'model': row.get('MODEL', '').strip(),
                    'type_acft': row.get('TYPE-ACFT', '').strip(),
                    'type_eng': row.get('TYPE-ENG', '').strip(),
                    'no_eng': row.get('NO-ENG', '').strip(),
                    'no_seats': row.get('NO-SEATS', '').strip(),
                    'ac_weight': row.get('AC-WEIGHT', '').strip(),
                }
    return manufacturers


def load_icao_mapping():
    """Load ICAO code mapping from MasterAircraftList.csv."""
    icao_map = {}  # Key: (manufacturer_upper, model_keywords) -> ICAO
    icao_by_model = {}  # Simpler: model keyword -> ICAO

    if not ICAO_MASTER.exists():
        print(f"Warning: ICAO master list not found at {ICAO_MASTER}")
        return icao_map, icao_by_model

    with open(ICAO_MASTER, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            icao = row.get('ICAO', '').strip()
            mfr = row.get('Manufacturer', '').strip().upper()
            model = row.get('Model', '').strip()

            if icao and icao != 'XXXX':
                # Store by manufacturer + model
                key = (mfr, model.upper())
                icao_map[key] = icao

                # Also store by model keywords for fuzzy matching
                model_words = model.upper().split()
                for word in model_words:
                    if len(word) > 2 and word not in ['THE', 'AND', 'FOR']:
                        if word not in icao_by_model:
                            icao_by_model[word] = icao

    return icao_map, icao_by_model


def find_icao(manufacturer, model, icao_map, icao_by_model):
    """Try to find ICAO code for an aircraft."""
    mfr_upper = manufacturer.upper().strip()
    model_upper = model.upper().strip()

    # Direct match
    key = (mfr_upper, model_upper)
    if key in icao_map:
        return icao_map[key]

    # Try partial manufacturer match
    for (map_mfr, map_model), icao in icao_map.items():
        if map_mfr in mfr_upper or mfr_upper in map_mfr:
            if map_model in model_upper or model_upper in map_model:
                return icao

    # Try model keyword match
    model_words = model_upper.split()
    for word in model_words:
        if word in icao_by_model:
            return icao_by_model[word]

    # Common manufacturer prefixes to ICAO mapping
    mfr_icao_hints = {
        'CESSNA': {'172': 'C172', '182': 'C182', '152': 'C152', '206': 'C206', '210': 'C210',
                   '310': 'C310', '414': 'C414', '421': 'C421', '525': 'C525', '560': 'C560',
                   '680': 'C680', '208': 'C208', '150': 'C150', '177': 'C177', '185': 'C185'},
        'PIPER': {'28': 'PA28', '32': 'PA32', '34': 'PA34', '46': 'PA46', '18': 'PA18',
                  '24': 'PA24', '30': 'PA30', '31': 'PA31', '44': 'PA44', '23': 'PA23'},
        'BEECH': {'33': 'BE33', '35': 'BE35', '36': 'BE36', '58': 'BE58', '90': 'BE9L',
                  '200': 'BE20', '350': 'BE30', '99': 'BE99', '55': 'BE55', '76': 'BE76'},
        'CIRRUS': {'SR22': 'SR22', 'SR20': 'SR20', 'SF50': 'SF50'},
        'MOONEY': {'M20': 'M20P'},
        'BOEING': {'737': 'B738', '747': 'B744', '757': 'B752', '767': 'B763', '777': 'B77W', '787': 'B788'},
        'AIRBUS': {'A320': 'A320', 'A319': 'A319', 'A321': 'A321', 'A330': 'A333', 'A350': 'A359', 'A380': 'A388'},
        'EMBRAER': {'175': 'E175', '190': 'E190', '195': 'E195', 'PHENOM': 'E50P'},
        'BOMBARDIER': {'CRJ': 'CRJ9', 'CHALLENGER': 'CL35', 'GLOBAL': 'GLEX'},
        'GULFSTREAM': {'G550': 'GLF5', 'G650': 'GLF6', 'G450': 'GLF4', 'GIV': 'GLF4', 'GV': 'GLF5'},
        'PILATUS': {'PC-12': 'PC12', 'PC12': 'PC12', 'PC-24': 'PC24'},
        'ROBINSON': {'R22': 'R22', 'R44': 'R44', 'R66': 'R66'},
        'BELL': {'206': 'B206', '407': 'B407', '412': 'B412', '429': 'B429'},
        'DIAMOND': {'DA40': 'DA40', 'DA42': 'DA42', 'DA62': 'DA62'},
    }

    for mfr_key, model_codes in mfr_icao_hints.items():
        if mfr_key in mfr_upper:
            for model_key, icao in model_codes.items():
                if model_key in model_upper:
                    return icao

    return None


def get_engine_type(type_eng_code):
    """Convert FAA engine type code to readable string."""
    engine_types = {
        '0': 'None',
        '1': 'Piston',
        '2': 'Turboprop',
        '3': 'Turboshaft',
        '4': 'Jet',
        '5': 'Turbofan',
        '6': 'Ramjet',
        '7': 'Rocket',
        '8': '2-Cycle',
        '9': '4-Cycle',
        '10': 'Electric',
        '11': 'Rotary',
    }
    return engine_types.get(str(type_eng_code).strip(), 'Unknown')


def random_gps_near_airport():
    """Generate random GPS coordinates near a random US airport."""
    airport = random.choice(US_AIRPORTS)
    # Random offset within ~10 miles (0.15 degrees)
    lat_offset = random.uniform(-0.15, 0.15)
    lon_offset = random.uniform(-0.15, 0.15)
    return (
        round(airport[2] + lat_offset, 6),
        round(airport[3] + lon_offset, 6),
        airport[0]  # Airport code for reference
    )


def random_date_last_year():
    """Generate random date within the last year, weighted toward recent."""
    now = datetime.now()
    # Weight more toward recent dates
    days_ago = int(random.triangular(0, 365, 30))  # Mode at 30 days ago
    date = now - timedelta(days=days_ago)
    # Add random time
    date = date.replace(
        hour=random.randint(6, 22),
        minute=random.randint(0, 59),
        second=random.randint(0, 59)
    )
    return date


def generate_test_data(count=2000):
    """Generate test data by combining FAA data with ICAO codes."""
    print(f"Loading manufacturer reference data...")
    manufacturers = load_manufacturer_reference()
    print(f"  Loaded {len(manufacturers)} manufacturer codes")

    print(f"Loading ICAO mapping...")
    icao_map, icao_by_model = load_icao_mapping()
    print(f"  Loaded {len(icao_map)} ICAO mappings")

    print(f"Loading FAA aircraft registrations...")
    aircraft_with_icao = []

    with open(FAA_AIRCRAFT, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        total_read = 0
        matched = 0

        for row in reader:
            total_read += 1
            reg = row.get('REGISTRATION', '').strip()
            mfr_code = row.get('MFR-CODE', '').strip()
            city = row.get('CITY', '').strip()
            state = row.get('STATE', '').strip()

            # Skip if no manufacturer code
            if not mfr_code or mfr_code not in manufacturers:
                continue

            mfr_data = manufacturers[mfr_code]
            manufacturer = mfr_data['manufacturer']
            model = mfr_data['model']
            engine_type = get_engine_type(mfr_data['type_eng'])
            num_engines = mfr_data['no_eng'] or '1'

            # Try to find ICAO code
            icao = find_icao(manufacturer, model, icao_map, icao_by_model)
            if icao:
                matched += 1
                aircraft_with_icao.append({
                    'registration': f"N{reg}" if not reg.startswith('N') else reg,
                    'icao': icao,
                    'manufacturer': manufacturer.title(),
                    'model': model.strip(),
                    'engine_type': engine_type,
                    'num_engines': num_engines,
                    'city': city.title(),
                    'state': state,
                })

            # Progress indicator
            if total_read % 50000 == 0:
                print(f"  Processed {total_read:,} aircraft, matched {matched:,} with ICAO codes...")

            # Stop if we have enough
            if len(aircraft_with_icao) >= count * 3:
                break

    print(f"  Total processed: {total_read:,}")
    print(f"  Matched with ICAO: {len(aircraft_with_icao):,}")

    # Randomly select the requested count
    if len(aircraft_with_icao) < count:
        print(f"  Warning: Only {len(aircraft_with_icao)} aircraft matched, less than requested {count}")
        selected = aircraft_with_icao
    else:
        selected = random.sample(aircraft_with_icao, count)

    print(f"\nGenerating {len(selected)} test records with GPS and timestamps...")

    # Add GPS and timestamps
    output_records = []
    for i, aircraft in enumerate(selected):
        lat, lon, airport = random_gps_near_airport()
        capture_date = random_date_last_year()

        output_records.append({
            'icao': aircraft['icao'],
            'manufacturer': aircraft['manufacturer'],
            'model': aircraft['model'],
            'registration': aircraft['registration'],
            'engine_type': aircraft['engine_type'],
            'num_engines': aircraft['num_engines'],
            'latitude': lat,
            'longitude': lon,
            'capture_date': capture_date.strftime('%Y-%m-%d'),
            'capture_time': capture_date.strftime('%H:%M:%S'),
            'year': capture_date.year,
            'month': capture_date.month,
            'day': capture_date.day,
            'near_airport': airport,
        })

    # Sort by capture date (oldest first, newest last)
    output_records.sort(key=lambda x: (x['capture_date'], x['capture_time']))

    # Update the last record to be "now"
    now = datetime.now()
    output_records[-1]['capture_date'] = now.strftime('%Y-%m-%d')
    output_records[-1]['capture_time'] = now.strftime('%H:%M:%S')
    output_records[-1]['year'] = now.year
    output_records[-1]['month'] = now.month
    output_records[-1]['day'] = now.day

    # Write output CSV
    print(f"\nWriting to {OUTPUT_FILE}...")
    fieldnames = ['icao', 'manufacturer', 'model', 'registration', 'engine_type',
                  'num_engines', 'latitude', 'longitude', 'capture_date', 'capture_time',
                  'year', 'month', 'day', 'near_airport']

    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_records)

    print(f"\nDone! Generated {len(output_records)} test records.")
    print(f"Output file: {OUTPUT_FILE}")

    # Show sample
    print("\nSample records:")
    for record in output_records[:5]:
        print(f"  {record['registration']}: {record['manufacturer']} {record['model']} ({record['icao']})")
        print(f"    Location: {record['latitude']}, {record['longitude']} near {record['near_airport']}")
        print(f"    Date: {record['capture_date']} {record['capture_time']}")


if __name__ == '__main__':
    import sys
    count = 2000
    if len(sys.argv) > 2 and sys.argv[1] == '--count':
        count = int(sys.argv[2])
    generate_test_data(count)
