#!/usr/bin/env python3
"""Prepare or propose a verified staging formula and desktop cask; never execute downloaded code."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import urllib.parse
import urllib.error
import urllib.request

from staging_formula import ORIGIN, candidate_order, candidate_parts, parse_checksums, render, render_cask


SOURCE = "Dockpipe-Industries/dockpipe"
TAP = "Dockpipe-Industries/homebrew-dockpipe"
FORMULA = "Formula/dockpipe-staging.rb"
CASK = "Casks/dockpipe-desktop-staging.rb"


def download(path):
    # curl matches the release installers and handles Cloudflare's public endpoint.
    return subprocess.check_output([
        "curl", "--fail", "--silent", "--show-error", "--retry", "2",
        "--connect-timeout", "15", "--max-time", "60", "--proto", "=https",
        f"{ORIGIN}/{path}",
    ])


def github(path, payload=None, allow_missing=False, method=None):
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "dockpipe-homebrew-sync",
               "X-GitHub-Api-Version": "2022-11-28"}
    token = os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None if payload is None else json.dumps(payload).encode()
    if payload is not None:
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(f"https://api.github.com/repos/{path}", data=data,
                                     headers=headers, method=method or ("GET" if payload is None else "PUT"))
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            if response.status == 204:
                return {}
            return json.load(response)
    except urllib.error.HTTPError as error:
        if allow_missing and error.code == 404:
            return None
        raise


def completed_candidate(pointer, catalog, run):
    candidate = pointer["candidate"]
    version, run_id, attempt, short_sha = candidate_parts(candidate)
    manifest = f"packages/candidates/{candidate}/release-manifest.json"
    if pointer.get("channel") != "staging" or pointer.get("version") != version or pointer.get("manifest") != manifest:
        raise ValueError("Staging pointer identity mismatch")
    source_sha = catalog.get("source_sha", "")
    if (catalog.get("schema") != 1 or catalog.get("channel") != "staging"
            or catalog.get("candidate") != candidate or catalog.get("version") != version
            or not re.fullmatch(r"[0-9a-f]{40}", source_sha) or not source_sha.startswith(short_sha)):
        raise ValueError("Staging catalog provenance mismatch")
    if (run.get("id") != int(run_id) or run.get("run_attempt") != int(attempt)
            or run.get("head_sha") != source_sha or run.get("head_branch") != "staging"
            or run.get("event") != "push" or run.get("path") != ".github/workflows/ci.yml"
            or run.get("repository", {}).get("full_name") != SOURCE):
        raise ValueError("Release does not match the staging CI run")
    return run.get("status") == "completed" and run.get("conclusion") == "success"


def latest_release():
    pointer = json.loads(download("packages/latest.json"))
    candidate = pointer["candidate"]
    _, run_id, attempt, _ = candidate_parts(candidate)
    # Construct the path from the validated identity, never from an arbitrary pointer URL.
    base = f"packages/candidates/{candidate}"
    catalog_bytes = download(f"{base}/release-manifest.json")
    catalog = json.loads(catalog_bytes)
    run = github(f"{SOURCE}/actions/runs/{run_id}/attempts/{attempt}")
    if not completed_candidate(pointer, catalog, run):
        print("Staging publication has not completed successfully; leaving the tap unchanged.")
        return None
    checksums = parse_checksums(download(f"{base}/SHA256SUMS.txt").decode())
    if checksums.get("release-manifest.json") != hashlib.sha256(catalog_bytes).hexdigest():
        raise ValueError("Release catalog checksum mismatch")
    return candidate, {FORMULA: render(candidate, checksums), CASK: render_cask(candidate, checksums)}


def require_forward_update(current, candidate, formula):
    if current == formula:
        return False
    if current:
        match = re.search(r'^  version "([^"]+)"$', current, re.MULTILINE)
        if not match:
            raise ValueError("Existing formula has no recognized candidate version")
        if candidate_order(candidate) < candidate_order(match[1]):
            raise ValueError("Refusing to roll back the staging formula")
        if candidate_order(candidate) == candidate_order(match[1]) and candidate != match[1]:
            raise ValueError("Conflicting identity for an existing candidate")
    return True


def output(name, value):
    if os.environ.get("GITHUB_OUTPUT"):
        with Path(os.environ["GITHUB_OUTPUT"]).open("a") as stream:
            stream.write(f"{name}={value}\n")


def prepare(directory):
    result = latest_release()
    if result is None:
        output("changed", "false")
        return
    candidate, contents = result
    changed = False
    for name, content in contents.items():
        current_path = Path(name)
        current = current_path.read_text() if current_path.exists() else ""
        changed = require_forward_update(current, candidate, content) or changed
    output("changed", str(changed).lower())
    if not changed:
        print(f"Tap already contains {candidate}.")
        return
    directory.mkdir(parents=True, exist_ok=True)
    for name, content in contents.items():
        (directory / Path(name).name).write_text(content)
    (directory / "candidate.txt").write_text(candidate + "\n")
    print(f"Prepared {candidate} for native Homebrew validation.")


def proposal_metadata(candidate):
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    proof = f"https://github.com/{TAP}/actions/runs/{run_id}" if run_id.isdigit() else "the parent qualification run"
    title = f"Update Dockpipe staging to {candidate}"
    body = (
        f"Candidate {candidate}. CLI and desktop cask bytes passed both macOS verification lanes in {proof}. "
        "Candidate provenance, forward ordering and current release metadata were rechecked before this proposal. "
        "Review and merge after required checks; this workflow never merges or bypasses protection."
    )
    return title, body


def candidate_head(branch):
    reference = github(f"{TAP}/git/ref/heads/{branch}")
    sha = reference["object"]["sha"]
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("Candidate branch did not report an exact commit SHA")
    return sha


def verify_candidate_scope(base_sha, head_sha, contents):
    comparison = github(f"{TAP}/compare/{base_sha}...{head_sha}")
    if comparison.get("status") not in {"ahead", "identical"}:
        raise ValueError("Existing candidate branch diverged; manual review is required")
    changed_files = set()
    for item in comparison.get("files", []):
        changed_files.add(item["filename"])
        if item.get("previous_filename"):
            changed_files.add(item["previous_filename"])
    if not changed_files <= set(contents):
        raise ValueError("Existing candidate branch contains unrelated changes")


def verify_candidate_commit(branch, contents):
    # Read all files at one immutable commit. A moving branch must never turn
    # separately verified files into a qualification claim for different bytes.
    sha = candidate_head(branch)
    main = github(f"{TAP}/git/ref/heads/main")
    verify_candidate_scope(main["object"]["sha"], sha, contents)
    for name, content in contents.items():
        verified = github(f"{TAP}/contents/{name}?ref={sha}")
        if base64.b64decode(verified["content"]).decode() != content:
            raise ValueError("Candidate commit differs from the tested content")
    return sha


def dispatch_checks(branch, sha):
    if candidate_head(branch) != sha:
        raise ValueError("Candidate branch moved after verification; manual review is required")
    path = f"{TAP}/actions/workflows/codeql.yml"
    runs = github(path + f"/runs?head_sha={sha}&event=workflow_dispatch&per_page=10")
    if any(run.get("head_sha") == sha and run.get("event") == "workflow_dispatch"
           for run in runs.get("workflow_runs", [])):
        print(f"CodeQL dispatch already recorded for {sha}; retry remains an explicit action.")
        return
    github(path + "/dispatches", {"ref": branch, "inputs": {"expected_head_sha": sha}}, method="POST")
    print(f"Dispatched CodeQL for exact candidate commit {sha}.")


def propose(directory):
    if os.environ.get("GITHUB_REPOSITORY") != TAP or os.environ.get("GITHUB_REF") != "refs/heads/main":
        raise ValueError("Proposal requires the official tap's main workflow")
    candidate = (directory / "candidate.txt").read_text().strip()
    contents = {name: (directory / Path(name).name).read_text() for name in (FORMULA, CASK)}
    latest = latest_release()
    if latest is None or latest[0] != candidate:
        print("A different candidate is current; leaving the tap unchanged.")
        return
    if latest[1] != contents:
        raise ValueError("Tested tap content differs from the current release metadata")

    # Validate both main-branch records before creating any proposal. There are
    # no direct main writes and no automatic merges in this flow.
    changed = False
    for name, content in contents.items():
        existing = github(f"{TAP}/contents/{name}?ref=main", allow_missing=True)
        current = base64.b64decode(existing["content"]).decode() if existing else ""
        changed = require_forward_update(current, candidate, content) or changed
    if not changed:
        print(f"Tap already contains {candidate}.")
        return

    branch = "staging-candidate/current"
    head = urllib.parse.quote("Dockpipe-Industries:" + branch, safe="")
    existing_pulls = github(f"{TAP}/pulls?state=open&base=main&head={head}")
    if len(existing_pulls) > 1:
        raise ValueError("Multiple candidate proposals require manual review")
    reference_path = f"{TAP}/git/ref/heads/{branch}"
    reference = github(reference_path, allow_missing=True)
    if reference is not None and not existing_pulls:
        raise ValueError("Candidate branch has no open proposal; manual retirement is required")
    if reference is None and existing_pulls:
        raise ValueError("Open candidate proposal has no branch; manual review is required")
    if reference is None:
        main = github(f"{TAP}/git/ref/heads/main")
        github(f"{TAP}/git/refs", {"ref": "refs/heads/" + branch,
               "sha": main["object"]["sha"]}, method="POST")
    else:
        main = github(f"{TAP}/git/ref/heads/main")
        verify_candidate_scope(main["object"]["sha"], reference["object"]["sha"], contents)

    encoded_branch = urllib.parse.quote(branch, safe="")
    for name, content in contents.items():
        endpoint = f"{TAP}/contents/{name}"
        existing = github(endpoint + "?ref=" + encoded_branch, allow_missing=True)
        current = base64.b64decode(existing["content"]).decode() if existing else ""
        if current != content:
            payload = {"message": f"Propose Dockpipe staging {candidate}", "branch": branch,
                       "content": base64.b64encode(content.encode()).decode()}
            if existing:
                payload["sha"] = existing["sha"]
            github(endpoint, payload)
        verified = github(endpoint + "?ref=" + encoded_branch)
        if base64.b64decode(verified["content"]).decode() != content:
            raise ValueError("Candidate branch read-back differs from the tested content")

    verified_sha = verify_candidate_commit(branch, contents)
    title, body = proposal_metadata(candidate)
    if existing_pulls:
        pull = existing_pulls[0]
        if pull.get("title") != title or pull.get("body") != body:
            github(f"{TAP}/pulls/{pull['number']}", {"title": title, "body": body}, method="PATCH")
        print(f"Existing staging proposal: {pull['html_url']}")
        dispatch_checks(branch, verified_sha)
        return
    pull = github(f"{TAP}/pulls", {
        "title": title, "head": branch, "base": "main", "body": body
    }, method="POST")
    print(f"Opened staging proposal: {pull['html_url']}")
    dispatch_checks(branch, verified_sha)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("prepare", "propose"))
    parser.add_argument("--output", type=Path, default=Path("prepared"))
    arguments = parser.parse_args()
    if arguments.command == "prepare":
        prepare(arguments.output)
    else:
        propose(arguments.output)
