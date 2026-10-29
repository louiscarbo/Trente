# Usage: python3 -I post-uploads.py <captures dir> <uploads.json>
# uploads.json: [{"file": "en/iphone-dashboard-light.png", "url": "<submitUrl from upload_assets>"}, ...]
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

captures, uploads_path = sys.argv[1], sys.argv[2]
uploads = json.load(open(uploads_path))


def post(upload):
    result = subprocess.run(
        ["curl", "-s", "-w", "\n%{http_code}", "-X", "POST", "-F", f"file=@{captures}/{upload['file']};type=image/png", upload["url"]],
        capture_output=True,
        text=True,
    )
    return upload["file"], result.stdout.strip().splitlines()[-1]


with ThreadPoolExecutor(6) as pool:
    results = list(pool.map(post, uploads))
failed = [result for result in results if result[1] != "200"]
print(f"{len(results)} posted, {len(failed)} failed", failed)
sys.exit(1 if failed else 0)
