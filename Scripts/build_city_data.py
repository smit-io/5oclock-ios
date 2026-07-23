#!/usr/bin/env python3
"""GeoNames cities15000 -> one compact JSON file per IANA timezone.

Output lands in the FiveOClockKit resource bundle so CityStore can load just the
1-3 zones a tick needs. Run once; the JSON is checked in.

    python3 Scripts/build_city_data.py
"""
import csv, json, os, sys, urllib.request, zipfile, io
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.join(HERE, "_geonames")
OUT = os.path.join(HERE, "..", "FiveOClockKit", "Sources", "FiveOClockKit", "Resources", "cities")
PER_ZONE_CAP = 300  # notable cities per zone; rotating through more is pointless

# GeoNames columns (tab-separated, no header)
ID, NAME, ASCII, ALT, LAT, LNG = 0, 1, 2, 3, 4, 5
FCLASS, FCODE, CC, CC2, ADMIN1 = 6, 7, 8, 9, 10
POP, ELEV, DEM, TZ = 14, 15, 16, 17


def ensure(path, url):
    if os.path.exists(path):
        return
    print(f"downloading {url}")
    data = urllib.request.urlopen(url).read()
    if url.endswith(".zip"):
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            z.extractall(os.path.dirname(path))
    else:
        with open(path, "wb") as f:
            f.write(data)


def load_admin1_names():
    """`US.CA` -> `California` for user-friendly region labels."""
    path = os.path.join(WORK, "admin1CodesASCII.txt")
    ensure(path, "https://download.geonames.org/export/dump/admin1CodesASCII.txt")
    names = {}
    with open(path, encoding="utf-8") as f:
        for row in csv.reader(f, delimiter="\t"):
            if len(row) >= 2:
                names[row[0]] = row[1]
    return names


def main():
    cities_txt = os.path.join(WORK, "cities15000.txt")
    ensure(cities_txt, "https://download.geonames.org/export/dump/cities15000.zip")
    admin1 = load_admin1_names()

    by_zone = defaultdict(list)
    with open(cities_txt, encoding="utf-8") as f:
        for row in csv.reader(f, delimiter="\t"):
            if len(row) < 18 or not row[TZ]:
                continue
            try:
                pop = int(row[POP] or 0)
            except ValueError:
                pop = 0
            region = admin1.get(f"{row[CC]}.{row[ADMIN1]}") if row[ADMIN1] else None
            by_zone[row[TZ]].append({
                "id": int(row[ID]),
                "name": row[NAME],
                "countryCode": row[CC],
                "admin1": region,
                "latitude": float(row[LAT]),
                "longitude": float(row[LNG]),
                "population": pop,
                "timeZoneID": row[TZ],
            })

    os.makedirs(OUT, exist_ok=True)
    for old in os.listdir(OUT):
        os.remove(os.path.join(OUT, old))

    total = 0
    for zone, cities in by_zone.items():
        cities.sort(key=lambda c: c["population"], reverse=True)
        cities = cities[:PER_ZONE_CAP]
        total += len(cities)
        fname = zone.replace("/", "~") + ".json"
        with open(os.path.join(OUT, fname), "w", encoding="utf-8") as f:
            json.dump(cities, f, ensure_ascii=False, separators=(",", ":"))

    print(f"wrote {len(by_zone)} zones, {total} cities to {OUT}")


if __name__ == "__main__":
    sys.exit(main())
