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


class MergedCandidateReuseTests(unittest.TestCase):
    HEAD = "a" * 40
    MERGE = "b" * 40
    MAIN = "c" * 40
    TREE = "d" * 40
    ADVANCED = "e" * 40
    BRANCH = "staging-candidate/current"

    def setUp(self):
        self.reset_fixture()
        self.api = patch.object(sync, "github", side_effect=self.github)
        self.api.start()
        self.addCleanup(self.api.stop)

    def reset_fixture(self):
        self.current = self.HEAD
        self.main = self.MAIN
        self.mutations = []
        self.pull = {
            "number": 8, "state": "closed", "merged": True, "merged_at": "2026-10-24T08:49:00Z",
            "merge_commit_sha": self.MERGE,
            "head": {"sha": self.HEAD, "ref": self.BRANCH, "repo": {"full_name": sync.TAP}},
            "base": {"ref": "main", "repo": {"full_name": sync.TAP}},
        }
        self.summaries = [self.pull]
        self.tree = self.TREE
        self.merge_tree = self.TREE
        self.old_contents = {sync.FORMULA: b'  version "0.6.27-staging.100.1.aaaaaaaaaaaa"\n',
                             sync.CASK: b'  version "0.6.27-staging.100.1.aaaaaaaaaaaa"\n'}
        self.main_contents = dict(self.old_contents)
        self.contents = dict(self.old_contents)
        self.nonancestor = False
        self.before_candidate = None
        self.before_main = None
        self.after_candidate = None
        self.after_main = None
        self.transport_failure = False
        self.concurrent_update = False
        self.pull_reads = 0
        self.change_pull_on_recheck = False
        self.file_override = None

    def github(self, path, payload=None, allow_missing=False, method=None):
        if payload is not None:
            self.mutations.append((path, payload, method))
        if path.startswith(sync.TAP + "/pulls?state=closed"):
            return self.summaries
        if path.startswith(sync.TAP + "/pulls?state=open"):
            return []
        if path == sync.TAP + "/pulls/8":
            self.pull_reads += 1
            if self.change_pull_on_recheck and self.pull_reads == 2:
                self.pull["merge_commit_sha"] = self.ADVANCED
            return self.pull
        if path == sync.TAP + "/git/ref/heads/main":
            observed = self.before_main or self.main
            if self.mutations and self.after_main:
                observed = self.after_main
            return {"object": {"sha": observed}}
        if path == sync.TAP + "/git/ref/heads/" + self.BRANCH:
            observed = self.before_candidate or self.current
            if self.mutations and self.after_candidate:
                observed = self.after_candidate
            return {"object": {"sha": observed}}
        if path == sync.TAP + "/git/refs/heads/" + self.BRANCH:
            self.assertEqual(method, "PATCH")
            self.assertEqual(payload, {"sha": self.MAIN, "force": False})
            if self.concurrent_update:
                self.current = self.ADVANCED
                raise sync.urllib.error.HTTPError(path, 409, "non-fast-forward", {}, None)
            if self.transport_failure:
                raise OSError("non-force ref update failed")
            self.current = payload["sha"]
            return {"object": {"sha": self.current}}
        if path.startswith(sync.TAP + "/compare/"):
            ancestor, descendant = path.split("/compare/", 1)[1].split("...")
            if self.nonancestor:
                return {"status": "diverged", "merge_base_commit": {"sha": self.TREE}}
            if ancestor == self.MAIN:
                return {"status": "identical" if ancestor == descendant else "ahead",
                        "files": [{"filename": name} for name in self.contents]}
            return {"status": "ahead", "merge_base_commit": {"sha": ancestor}}
        if path == sync.TAP + "/git/commits/" + self.HEAD:
            return {"tree": {"sha": self.tree}}
        if path == sync.TAP + "/git/commits/" + self.MERGE:
            return {"tree": {"sha": self.merge_tree}}
        for name in (sync.FORMULA, sync.CASK):
            endpoint = sync.TAP + "/contents/" + name
            if path.startswith(endpoint + "?ref="):
                ref = path.split("?ref=", 1)[1]
                if ref == "main" or ref == self.MAIN:
                    content = self.main_contents[name]
                elif ref == self.HEAD:
                    content = self.old_contents[name]
                else:
                    content = self.contents[name]
                import base64
                item = {"path": name, "type": "file", "encoding": "base64", "size": len(content),
                        "content": base64.b64encode(content).decode(),
                        "sha": hashlib.sha1(content).hexdigest()}
                if ref == self.HEAD and self.file_override:
                    item.update(self.file_override)
                return item
            if path == endpoint and payload is not None:
                import base64
                self.assertEqual(payload["sha"], hashlib.sha1(self.contents[name]).hexdigest())
                self.contents[name] = base64.b64decode(payload["content"])
                self.current = "f" * 40
                return {}
        if path == sync.TAP + "/pulls" and method == "POST":
            return {"html_url": "https://github.com/" + sync.TAP + "/pull/9"}
        if path.endswith("/runs?head_sha=" + self.current + "&event=workflow_dispatch&per_page=10"):
            return {"workflow_runs": []}
        if path.endswith("/actions/workflows/codeql.yml/dispatches"):
            return {}
        self.fail("Unexpected GitHub request: " + path)

    def reuse(self):
        return sync.reuse_merged_candidate(self.BRANCH, self.HEAD, self.MAIN)

    def test_exact_merged_head_fast_forwards_without_force(self):
        result = self.reuse()
        self.assertEqual(result["object"]["sha"], self.MAIN)
        self.assertEqual(self.current, self.MAIN)
        self.assertEqual(len(self.mutations), 1)

    def test_orphan_unmerged_or_advanced_heads_refuse_without_mutation(self):
        for change in ("orphan", "unmerged", "advanced", "wrong-base", "wrong-repository"):
            with self.subTest(change=change):
                self.reset_fixture()
                if change == "orphan":
                    self.summaries = []
                elif change == "unmerged":
                    self.pull["merged"] = False
                elif change == "advanced":
                    self.pull["head"]["sha"] = self.ADVANCED
                elif change == "wrong-base":
                    self.pull["base"]["ref"] = "production"
                else:
                    self.pull["head"]["repo"]["full_name"] = "other/repository"
                with self.assertRaises(ValueError):
                    self.reuse()
                self.assertEqual(self.mutations, [])

    def test_ambiguous_or_excess_merged_history_refuses(self):
        for summaries in ([self.pull, self.pull], [self.pull] * 100):
            with self.subTest(count=len(summaries)):
                self.summaries = summaries
                with self.assertRaises(ValueError):
                    self.reuse()
                self.assertEqual(self.mutations, [])

    def test_ancestor_and_recorded_tree_are_required(self):
        self.nonancestor = True
        with self.assertRaises(ValueError):
            self.reuse()
        self.assertEqual(self.mutations, [])
        self.nonancestor = False
        self.merge_tree = self.ADVANCED
        with self.assertRaises(ValueError):
            self.reuse()
        self.assertEqual(self.mutations, [])

    def test_main_staging_changes_refuse_but_newer_other_source_is_preserved(self):
        self.main_contents[sync.FORMULA] = b"changed staging formula"
        with self.assertRaises(ValueError):
            self.reuse()
        self.assertEqual(self.mutations, [])
        self.main_contents = dict(self.old_contents)
        # MAIN is deliberately a newer commit than MERGE; only the reviewed
        # merged tree and the two staging records must share their old basis.
        self.assertEqual(self.reuse()["object"]["sha"], self.MAIN)

    def test_pre_update_candidate_main_and_proposal_races_refuse(self):
        for change in ("candidate", "main", "proposal"):
            with self.subTest(change=change):
                self.reset_fixture()
                if change == "candidate":
                    self.before_candidate = self.ADVANCED
                elif change == "main":
                    self.before_main = self.ADVANCED
                else:
                    self.change_pull_on_recheck = True
                with self.assertRaises(ValueError):
                    self.reuse()
                self.assertEqual(self.mutations, [])

    def test_nonforce_transport_failure_is_not_retried(self):
        self.transport_failure = True
        with self.assertRaises(OSError):
            self.reuse()
        self.assertEqual(len(self.mutations), 1)
        self.assertEqual(self.current, self.HEAD)

    def test_nonforce_conflict_preserves_concurrently_advanced_candidate(self):
        self.concurrent_update = True
        with self.assertRaises(sync.urllib.error.HTTPError):
            self.reuse()
        self.assertEqual(self.current, self.ADVANCED)
        self.assertEqual(len(self.mutations), 1)
        self.assertIs(self.mutations[0][1]["force"], False)

    def test_abbreviated_or_revision_targets_refuse_without_mutation(self):
        for head in ("abc123", "main~1", self.HEAD.upper(), None):
            with self.subTest(head=head):
                with self.assertRaises(ValueError):
                    sync.reuse_merged_candidate(self.BRANCH, head, self.MAIN)
                self.assertEqual(self.mutations, [])

    def test_post_update_ref_races_fail_without_file_writes(self):
        for change in ("candidate", "main"):
            with self.subTest(change=change):
                self.reset_fixture()
                if change == "candidate":
                    self.after_candidate = self.ADVANCED
                else:
                    self.after_main = self.ADVANCED
                with self.assertRaises(ValueError):
                    self.reuse()
                self.assertEqual(len(self.mutations), 1)
                self.assertIn("/git/refs/heads/", self.mutations[0][0])

    def test_invalid_staging_metadata_or_content_refuses_before_ref_update(self):
        for override in ({"size": 65537}, {"encoding": "none"}, {"type": "symlink"},
                         {"content": "!!!!"}, {"size": 1}, {"content": "A" * 90001}):
            with self.subTest(override=override):
                self.file_override = override
                with self.assertRaises(ValueError):
                    self.reuse()
                self.assertEqual(self.mutations, [])

    def test_propose_reuses_merged_basis_then_writes_only_two_sha_cas_files(self):
        candidate = "0.6.28-staging.200.1.cccccccccccc"
        prepared = {name: '  version "' + candidate + '"\n' for name in self.contents}
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "candidate.txt").write_text(candidate + "\n")
            for name, content in prepared.items():
                (directory / Path(name).name).write_text(content)
            with patch.dict(os.environ, {"GITHUB_REPOSITORY": sync.TAP, "GITHUB_REF": "refs/heads/main"}), \
                    patch.object(sync, "latest_release", return_value=(candidate, prepared)):
                sync.propose(directory)
        file_writes = [(path, payload) for path, payload, _ in self.mutations if "/contents/" in path]
        self.assertEqual({path for path, _ in file_writes},
                         {sync.TAP + "/contents/" + name for name in (sync.FORMULA, sync.CASK)})
        self.assertTrue(all("sha" in payload for _, payload in file_writes))
        self.assertEqual(self.mutations[0][1], {"sha": self.MAIN, "force": False})
        self.assertEqual(self.contents, {name: content.encode() for name, content in prepared.items()})


if __name__ == "__main__":
    unittest.main()
