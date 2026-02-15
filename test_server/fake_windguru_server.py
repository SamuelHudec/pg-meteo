#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
from datetime import datetime, timezone
import json

PORT = 8080
JSONL_PATH = "windguru_log.jsonl"

# Polia podľa Windguru Upload API docs (všetko okrem uid je voliteľné)
WG_FIELDS = {
    # measurement meta
    "uid", "unixtime", "datetime", "interval",
    # wind
    "wind_avg", "wind_max", "wind_min", "wind_direction",
    # meteo
    "temperature", "rh", "mslp",
    # precip
    "precip", "precip_interval",
    # auth
    "salt", "hash",
}

# Windguru: "uploads with time older then 2 hours will fail" (tu len simulujeme info do logu)
MAX_AGE_SECONDS = 2 * 60 * 60  # 2h


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_time_payload(q: dict) -> tuple[int | None, str | None]:
    """
    Return (epoch_seconds, source_string) or (None, None)
    Windguru precedence: unixtime over datetime.  [oai_citation:2‡stations.windguru.cz](https://stations.windguru.cz/upload_api.php?utm_source=chatgpt.com)
    """
    # unixtime first
    ut = q.get("unixtime")
    if ut:
        try:
            return int(float(ut)), "unixtime"
        except ValueError:
            return None, "unixtime_invalid"

    dt = q.get("datetime")
    if dt:
        try:
            # ISO 8601 (example in docs).  [oai_citation:3‡stations.windguru.cz](https://stations.windguru.cz/upload_api.php?utm_source=chatgpt.com)
            d = datetime.fromisoformat(dt)
            if d.tzinfo is None:
                # assume UTC if timezone missing
                d = d.replace(tzinfo=timezone.utc)
            return int(d.timestamp()), "datetime"
        except ValueError:
            return None, "datetime_invalid"

    return None, None


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)

        # Simuluj WG endpoint path: /upload/api.php (accept a few aliases too)
        if parsed.path not in ("/upload/api.php", "/upload/api", "/api.php"):
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found")
            return

        qs = parse_qs(parsed.query, keep_blank_values=True)
        # Flatten list values -> first element; keep as strings
        data = {k: (v[0] if isinstance(v, list) and v else "") for k, v in qs.items()}

        # Add metadata
        rec_utc = utc_now_iso()
        data_meta = {
            "_received_utc": rec_utc,
            "_remote_ip": self.client_address[0],
            "_path": parsed.path,
        }

        # Determine if request contains unknown keys (we still accept them)
        keys = set(data.keys())
        unknown = sorted(list(keys - WG_FIELDS))
        missing_known = sorted(list(WG_FIELDS - keys))

        # Time evaluation (purely informational)
        epoch, time_src = parse_time_payload(data)
        age_seconds = None
        too_old = None
        if epoch is not None:
            now_epoch = int(datetime.now(timezone.utc).timestamp())
            age_seconds = now_epoch - epoch
            too_old = age_seconds > MAX_AGE_SECONDS

        # Build one JSONL record
        record = {
            **data_meta,
            "query": data,                       # raw parsed query params
            "known_fields_present": sorted(list(keys & WG_FIELDS)),
            "unknown_fields": unknown,           # keys not in WG docs (still logged)
            "missing_known_fields": missing_known,  # for visibility; not an error
            "time_source": time_src,
            "age_seconds": age_seconds,
            "would_be_rejected_as_too_old": too_old,  # Windguru rejects > ~2h (info only)  [oai_citation:4‡stations.windguru.cz](https://stations.windguru.cz/upload_api.php?utm_source=chatgpt.com)
        }

        # Append JSONL (always)
        with open(JSONL_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")

        # Console summary (short)
        uid = data.get("uid", "")
        print(f"[{rec_utc}] uid={uid or '(missing)'} keys={len(keys)} age={age_seconds} too_old={too_old}")

        # Always OK (tolerant mode)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

    def log_message(self, format, *args):
        # silence default http logs
        return


if __name__ == "__main__":
    print(f"Fake Windguru listening on http://0.0.0.0:{PORT}/upload/api.php")
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
