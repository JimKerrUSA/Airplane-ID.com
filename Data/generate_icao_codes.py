#!/usr/bin/env python3
"""
Generate ICAOCodes.csv from the PlaneFinder ICAOList.csv file.

Extracts aircraft type information for use in the Airplane-ID iOS app.
Maps ICAO data to FAA classification codes for consistency.

Usage:
    python3 generate_icao_codes.py

Input:  ~/dev/projects/PlaneFinder/Aircraft/faa/ICAO/ICAOList.csv
Output: ICAOCodes.csv (in same directory as this script)
"""

import csv
from pathlib import Path

# Configuration
INPUT_FILE = Path.home() / "dev/projects/PlaneFinder/Aircraft/faa/ICAO/ICAOList.csv"
OUTPUT_FILE = Path(__file__).parent / "ICAOCodes.csv"


# =============================================================================
# FAA Code Mappings
# =============================================================================

# FAA Engine Type Codes (TYPE-ENG)
# 0=None, 1=Reciprocating, 2=Turbo-prop, 3=Turbo-shaft, 4=Turbo-jet,
# 5=Turbo-fan, 6=Ramjet, 7=2-cycle, 8=4-cycle, 9=Unknown, 10=Electric, 11=Rotary
ENGINE_TYPE_MAP = {
    'piston': 1,              # Reciprocating
    'jet': 4,                 # Turbo-jet
    'turboprop': 2,           # Turbo-prop
    'turboshaft': 3,          # Turbo-shaft
    'turboprop/turboshaft': 3,  # Combined → Turbo-shaft
    'electric': 10,           # Electric
    'rocket': 9,              # Unknown (no FAA equivalent)
    'glider': 0,              # None (no engine)
}

# FAA Aircraft Type Codes (TYPE-ACFT)
# 1=Glider, 2=Balloon, 3=Blimp/Dirigible, 4=Fixed Wing Single-Engine,
# 5=Fixed Wing Multi-Engine, 6=Rotorcraft, 7=Weight-shift-control,
# 8=Powered Parachute, 9=Gyroplane, H=Hybrid Lift, O=Other
AIRCRAFT_TYPE_MAP = {
    'helicopter': '6',    # Rotorcraft
    'gyrocopter': '9',    # Gyroplane
    'tiltrotor': 'H',     # Hybrid Lift
}

# FAA Aircraft Category Codes
# 1=Land, 2=Sea, 3=Amphibian
CATEGORY_MAP = {
    'landplane': 1,
    'seaplane': 2,
    'amphibian': 3,
    'helicopter': 1,      # Land
    'gyrocopter': 1,      # Land
    'tiltrotor': 1,       # Land
}


# =============================================================================
# Parsing Functions
# =============================================================================

def parse_manufacturer_model(combined: str) -> tuple[str, str]:
    """
    Parse 'MANUFACTURER, Model' field into separate values.
    Examples:
        'AIRBUS, A-320' -> ('AIRBUS', 'A-320')
        'AGUSTAWESTLAND, AW-109 Grand' -> ('AGUSTAWESTLAND', 'AW-109 Grand')
    """
    if ',' in combined:
        parts = combined.split(',', 1)
        manufacturer = parts[0].strip()
        model = parts[1].strip() if len(parts) > 1 else ""
        return manufacturer, model
    return combined.strip(), ""


def parse_engine_info(engine_str: str) -> tuple[int, str]:
    """
    Parse 'Number/EngineType' field.
    Returns (engine_count, engine_type_string)
    Examples:
        '2/Jet' -> (2, 'Jet')
        '1/Piston' -> (1, 'Piston')
        '2/Turboprop/Turboshaft' -> (2, 'Turboprop/Turboshaft')
    """
    if '/' in engine_str:
        parts = engine_str.split('/', 1)
        try:
            count = int(parts[0])
        except ValueError:
            count = 0
        engine_type = parts[1].strip() if len(parts) > 1 else ""
        return count, engine_type
    return 0, engine_str.strip()


def normalize_icao_class(class_str: str) -> str:
    """
    Normalize ICAO aircraft class for consistency.
    Fix typos and standardize capitalization.
    """
    cleaned = class_str.strip().lower()

    class_map = {
        'landplane': 'LandPlane',
        'landplne': 'LandPlane',
        'landplance': 'LandPlane',
        'landplace': 'LandPlane',
        'helicopter': 'Helicopter',
        'amphibian': 'Amphibian',
        'gyrocopter': 'Gyrocopter',
        'seaplane': 'SeaPlane',
        'tiltrotor': 'Tiltrotor',
    }

    return class_map.get(cleaned, class_str.strip())


def map_engine_type_to_faa(icao_engine_type: str) -> int:
    """Map ICAO engine type string to FAA engine type code."""
    key = icao_engine_type.strip().lower()
    return ENGINE_TYPE_MAP.get(key, 9)  # Default to 9 (Unknown)


def derive_aircraft_type(icao_class: str, engine_count: int, icao_engine_type: str) -> str:
    """
    Derive FAA aircraft type code from ICAO class and engine count.

    Returns FAA TYPE-ACFT code:
    - "1" = Glider
    - "4" = Fixed Wing Single-Engine
    - "5" = Fixed Wing Multi-Engine
    - "6" = Rotorcraft (Helicopter)
    - "9" = Gyroplane (Gyrocopter)
    - "H" = Hybrid Lift (Tiltrotor)
    """
    class_lower = icao_class.lower()
    engine_lower = icao_engine_type.strip().lower()

    # Check for glider (engine type indicates no engine)
    if engine_lower == 'glider':
        return '1'  # Glider

    # Non-fixed-wing aircraft
    if class_lower in AIRCRAFT_TYPE_MAP:
        return AIRCRAFT_TYPE_MAP[class_lower]

    # Fixed-wing aircraft (LandPlane, SeaPlane, Amphibian)
    if engine_count == 1:
        return '4'  # Fixed Wing Single-Engine
    elif engine_count >= 2:
        return '5'  # Fixed Wing Multi-Engine
    else:
        # 0 engines but not marked as glider - treat as glider
        return '1'


def derive_category_code(icao_class: str) -> int:
    """
    Derive FAA aircraft category code from ICAO class.
    1=Land, 2=Sea, 3=Amphibian
    """
    class_lower = icao_class.lower()
    return CATEGORY_MAP.get(class_lower, 1)  # Default to Land


# =============================================================================
# Main Processing
# =============================================================================

def main():
    """Main function to process ICAO codes and generate CSV."""
    print(f"Reading from: {INPUT_FILE}")
    print(f"Output to: {OUTPUT_FILE}")
    print()

    if not INPUT_FILE.exists():
        print(f"ERROR: Input file not found: {INPUT_FILE}")
        return

    records = []
    skipped = 0

    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)  # Skip header
        print(f"Input columns: {header}")

        for row in reader:
            if len(row) < 4:
                skipped += 1
                continue

            icao = row[0].strip()
            icao_class_raw = row[1].strip()
            engine_info = row[2].strip()
            mfg_model = row[3].strip()

            # Skip empty ICAO codes
            if not icao:
                skipped += 1
                continue

            # Parse fields
            manufacturer, model = parse_manufacturer_model(mfg_model)
            engine_count, icao_engine_type = parse_engine_info(engine_info)
            icao_class = normalize_icao_class(icao_class_raw)

            # Map to FAA codes
            engine_type_code = map_engine_type_to_faa(icao_engine_type)
            aircraft_type = derive_aircraft_type(icao_class, engine_count, icao_engine_type)
            category_code = derive_category_code(icao_class)

            records.append({
                'icao': icao,
                'manufacturer': manufacturer,
                'model': model,
                'icaoClass': icao_class,
                'aircraftCategoryCode': category_code,
                'aircraftType': aircraft_type,
                'engineCount': engine_count,
                'engineType': engine_type_code,
            })

    print(f"Parsed {len(records)} aircraft types")
    print(f"Skipped {skipped} invalid rows")

    # Remove duplicates (keep first occurrence)
    seen_icao = set()
    unique_records = []
    duplicates = 0
    for record in records:
        if record['icao'] not in seen_icao:
            seen_icao.add(record['icao'])
            unique_records.append(record)
        else:
            duplicates += 1

    print(f"Removed {duplicates} duplicate ICAO codes")
    print(f"Final count: {len(unique_records)} unique aircraft types")

    # Sort by ICAO code
    unique_records.sort(key=lambda x: x['icao'])

    # Write output CSV
    print(f"\nWriting to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'icao', 'manufacturer', 'model', 'icaoClass',
            'aircraftCategoryCode', 'aircraftType', 'engineCount', 'engineType'
        ])
        writer.writeheader()
        writer.writerows(unique_records)

    print("Done!")

    # Show sample records
    print("\nSample records:")
    print("ICAO | Manufacturer | Model | icaoClass | catCode | acftType | engCnt | engType")
    print("-" * 90)
    for record in unique_records[:15]:
        print(f"{record['icao']:6} | {record['manufacturer'][:12]:12} | {record['model'][:15]:15} | "
              f"{record['icaoClass']:10} | {record['aircraftCategoryCode']:7} | {record['aircraftType']:8} | "
              f"{record['engineCount']:6} | {record['engineType']}")

    # Show distribution stats
    print("\n" + "=" * 60)
    print("DISTRIBUTION STATISTICS")
    print("=" * 60)

    print("\nAircraft Category Code distribution:")
    cat_counts = {}
    cat_names = {1: 'Land', 2: 'Sea', 3: 'Amphibian'}
    for record in unique_records:
        cat = record['aircraftCategoryCode']
        cat_counts[cat] = cat_counts.get(cat, 0) + 1
    for cat, count in sorted(cat_counts.items()):
        print(f"  {cat} ({cat_names.get(cat, 'Unknown')}): {count}")

    print("\nAircraft Type distribution:")
    type_counts = {}
    type_names = {'1': 'Glider', '4': 'FW Single', '5': 'FW Multi',
                  '6': 'Rotorcraft', '9': 'Gyroplane', 'H': 'Hybrid Lift'}
    for record in unique_records:
        t = record['aircraftType']
        type_counts[t] = type_counts.get(t, 0) + 1
    for t, count in sorted(type_counts.items()):
        print(f"  {t} ({type_names.get(t, 'Unknown')}): {count}")

    print("\nEngine Type distribution:")
    eng_counts = {}
    eng_names = {0: 'None', 1: 'Reciprocating', 2: 'Turbo-prop', 3: 'Turbo-shaft',
                 4: 'Turbo-jet', 9: 'Unknown', 10: 'Electric'}
    for record in unique_records:
        e = record['engineType']
        eng_counts[e] = eng_counts.get(e, 0) + 1
    for e, count in sorted(eng_counts.items()):
        print(f"  {e} ({eng_names.get(e, 'Unknown')}): {count}")


if __name__ == "__main__":
    main()
