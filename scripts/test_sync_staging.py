"""Verify runtime-pointer selection through the actual curl subprocess boundary."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import sync_staging as sync


class RuntimePointerTransportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.fixture = self.directory / "responses.json"
        self.calls = self.directory / "calls.jsonl"
        curl = self.directory / "curl"
        curl.write_text('''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

arguments = sys.argv[1:]
url = arguments[-1]
path = url.split(".com/", 1)[1]
with Path(os.environ["CURL_TEST_CALLS"]).open("a") as stream:
    stream.write(json.dumps(path) + "\\n")
response = json.loads(Path(os.environ["CURL_TEST_RESPONSES"]).read_text())[path]
if "transport_exit" in response:
    sys.stdout.write(response.get("status", "000"))
    sys.exit(response["transport_exit"])
status = response.get("status", 200)
Path(arguments[arguments.index("--output") + 1]).write_bytes(response.get("body", "").encode())
sys.stdout.write(str(status))
sys.exit(22 if status >= 400 else 0)
''')
        curl.chmod(0o755)
        environment = {
            "PATH": str(self.directory) + os.pathsep + os.environ["PATH"],
            "CURL_TEST_RESPONSES": str(self.fixture),
            "CURL_TEST_CALLS": str(self.calls),
        }
        self.environment = patch.dict(os.environ, environment)
        self.environment.start()
        self.addCleanup(self.environment.stop)
        self.candidate = "0.6.0-staging.123.2.aaaaaaaaaaaa"
        self.base = f"packages/candidates/{self.candidate}"
        pointer = {
            "candidate": self.candidate,
            "version": "0.6.0",
            "channel": "staging",
            "manifest": f"{self.base}/release-manifest.json",
        }
        catalog = dict(pointer, schema=1, source_sha="a" * 40)
        catalog_bytes = json.dumps(catalog)
        checksums = {
            "release-manifest.json": hashlib.sha256(catalog_bytes.encode()).hexdigest(),
            "dockpipe-core-0.6.0.tar.gz": "b" * 64,
        }
        for architecture in ("amd64", "arm64"):
            checksums[f"dockpipe_0.6.0_darwin_{architecture}.tar.gz"] = "c" * 64
            checksums[f"dockpipe-desktop_0.6.0_darwin_{architecture}.zip"] = "d" * 64
        checksum_body = "".join(f"{digest}  {name}\n" for name, digest in checksums.items())
        self.responses = {
            "packages/runtime/latest.json": {"body": json.dumps(pointer)},
            "packages/latest.json": {"body": "Marketplace metadata is independent"},
            f"{self.base}/release-manifest.json": {"body": catalog_bytes},
            f"{self.base}/SHA256SUMS.txt": {"body": checksum_body},
        }
        self.run = {
            "id": 123,
            "run_attempt": 2,
            "head_sha": "a" * 40,
            "head_branch": "staging",
            "event": "push",
            "path": ".github/workflows/ci.yml",
            "repository": {"full_name": sync.SOURCE},
            "status": "completed",
            "conclusion": "success",
        }

    def release(self):
        self.fixture.write_text(json.dumps(self.responses))
        with patch.object(sync, "github", return_value=self.run):
            return sync.latest_release()

    def requested_paths(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def test_runtime_pointer_does_not_read_marketplace_pointer(self):
        candidate, contents = self.release()
        self.assertEqual(candidate, self.candidate)
        self.assertEqual(set(contents), {sync.FORMULA, sync.CASK})
        self.assertNotIn("packages/latest.json", self.requested_paths())

    def test_real_curl_http_404_admits_legacy_fallback(self):
        self.responses["packages/latest.json"] = self.responses["packages/runtime/latest.json"]
        self.responses["packages/runtime/latest.json"] = {"status": 404}
        self.assertEqual(self.release()[0], self.candidate)
        self.assertEqual(self.requested_paths()[:2], [
            "packages/runtime/latest.json", "packages/latest.json",
        ])

    def test_http_errors_do_not_admit_fallback(self):
        for status in (403, 429, 500, 503):
            with self.subTest(status=status):
                self.calls.unlink(missing_ok=True)
                self.responses["packages/runtime/latest.json"] = {"status": status}
                with self.assertRaises(subprocess.CalledProcessError) as failure:
                    self.release()
                self.assertEqual(failure.exception.returncode, 22)
                self.assertEqual(self.requested_paths(), ["packages/runtime/latest.json"])

    def test_transport_failure_does_not_admit_fallback(self):
        self.responses["packages/runtime/latest.json"] = {"transport_exit": 28, "status": "404"}
        with self.assertRaises(subprocess.CalledProcessError) as failure:
            self.release()
        self.assertEqual(failure.exception.returncode, 28)
        self.assertEqual(self.requested_paths(), ["packages/runtime/latest.json"])

    def test_invalid_runtime_json_does_not_admit_fallback(self):
        self.responses["packages/runtime/latest.json"] = {"body": "invalid JSON"}
        with self.assertRaises(ValueError):
            self.release()
        self.assertEqual(self.requested_paths(), ["packages/runtime/latest.json"])

    def test_invalid_runtime_identity_does_not_admit_fallback(self):
        self.responses["packages/runtime/latest.json"] = {"body": '{"candidate":"invalid"}'}
        with self.assertRaises(ValueError):
            self.release()
        self.assertEqual(self.requested_paths(), ["packages/runtime/latest.json"])

    def test_download_preserves_response_body_bytes(self):
        body = "payload\n200\nUnicode: λ\n"
        self.responses["body"] = {"body": body}
        self.fixture.write_text(json.dumps(self.responses))
        self.assertEqual(sync.download("body"), body.encode())

    def test_failed_source_run_cannot_prepare_candidate(self):
        self.run["conclusion"] = "failure"
        self.assertIsNone(self.release())
        self.assertEqual(self.requested_paths(), [
            "packages/runtime/latest.json", f"{self.base}/release-manifest.json",
        ])

    def test_release_checksum_mismatch_fails_closed(self):
        self.responses[f"{self.base}/release-manifest.json"]["body"] += " "
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            self.release()


if __name__ == "__main__":
    unittest.main()
