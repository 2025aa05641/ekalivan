#!/usr/bin/env python3
"""Drive Kaggle end-to-end for Wan2.1 clip generation — no manual upload/download.

Given a beats.json (e.g. exported by Ekalivan at
Ekalivan/backend/rendered/video/<task_id>/beats.json), this:

  1. Uploads it as a private Kaggle dataset (create on first run, version on later runs).
  2. Pushes generate_clips_kaggle_parallel.ipynb as a GPU-enabled kernel referencing that
     dataset, so the notebook's beats.json auto-discovery picks it up from /kaggle/input/.
  3. Polls the kernel until it finishes.
  4. Downloads its output and unzips clips.zip into --out-dir.

One-time setup (can't be scripted — it's your Kaggle account):
  1. pip install kaggle   (installs the Kaggle CLI v2, OAuth-based)
  2. kaggle auth login    (opens a browser to sign in; run this yourself in a terminal)
  3. kaggle quota         (sanity check — confirms you're logged in and shows remaining
                           weekly GPU hours)

Usage:
  python run_clip_generation.py --beats-json path/to/beats.json --out-dir path/to/clip_cache

  (--kaggle-username is optional — auto-detected from `kaggle config view` if omitted)
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
import time
import zipfile
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
NOTEBOOK_NAME = "generate_clips_kaggle_parallel.ipynb"
DATASET_STAGING_DIR = THIS_DIR / "kaggle_beats_dataset"
KAGGLE_OUTPUT_DIR = THIS_DIR / "kaggle_output"
KERNEL_SLUG = "wan-clip-generator-parallel"
DATASET_SLUG = "textbook-to-video-beats"


def _detect_kaggle_username() -> str:
    """Read the logged-in Kaggle username from `kaggle config view`.

    Returns:
        The username tied to the active `kaggle auth login` session.

    Raises:
        SystemExit: If not logged in, or the username can't be parsed from the output.
    """
    result = subprocess.run(["kaggle", "config", "view"], capture_output=True, text=True, check=True)
    match = re.search(r"^- username:\s*(\S+)\s*$", result.stdout, re.MULTILINE)
    if not match:
        raise SystemExit(
            "Could not detect a logged-in Kaggle username from `kaggle config view`.\n"
            "Run `kaggle auth login` first, or pass --kaggle-username explicitly.\n"
            f"Output was:\n{result.stdout}"
        )
    return match.group(1)


def _run(cmd: list[str]) -> subprocess.CompletedProcess:
    """Run a command, streaming its output, and raise if it fails.

    Args:
        cmd: Argv to execute.

    Returns:
        The completed process.
    """
    print("+", " ".join(cmd))
    return subprocess.run(cmd, check=True)


def _stage_dataset(beats_json_path: Path, username: str) -> str:
    """Create or update the Kaggle dataset carrying this run's beats.json.

    Args:
        beats_json_path: Local beats.json to upload.
        username: Kaggle account username, used to namespace the dataset.

    Returns:
        The dataset reference (``username/slug``) for use as a kernel data source.

    Raises:
        SystemExit: If dataset creation fails for a reason other than already existing.
    """
    DATASET_STAGING_DIR.mkdir(exist_ok=True)
    shutil.copy(beats_json_path, DATASET_STAGING_DIR / "beats.json")
    dataset_ref = f"{username}/{DATASET_SLUG}"
    dataset_metadata = {
        "title": "Textbook-to-Video beats",
        "id": dataset_ref,
        "licenses": [{"name": "CC0-1.0"}],
    }
    (DATASET_STAGING_DIR / "dataset-metadata.json").write_text(json.dumps(dataset_metadata, indent=2))

    create = subprocess.run(
        ["kaggle", "datasets", "create", "-p", str(DATASET_STAGING_DIR), "-q"],
        capture_output=True,
        text=True,
    )
    if create.returncode != 0:
        combined_output = (create.stdout + create.stderr).lower()
        if "already exists" not in combined_output and "already in use" not in combined_output:
            print(create.stdout, create.stderr, file=sys.stderr)
            raise SystemExit("kaggle datasets create failed (see output above).")
        _run(["kaggle", "datasets", "version", "-p", str(DATASET_STAGING_DIR), "-m", "update beats.json", "-q"])
    else:
        print(create.stdout)
    _wait_for_dataset_ready(dataset_ref)
    return dataset_ref


def _wait_for_dataset_ready(dataset_ref: str, poll_seconds: int = 5, timeout_seconds: int = 120) -> None:
    """Block until Kaggle finishes processing a just-created/updated dataset.

    `datasets create`/`datasets version` return as soon as the upload finishes, while
    Kaggle keeps processing the dataset in the background. Pushing a kernel that
    references the dataset before that processing completes silently produces a kernel
    with an empty/stale `/kaggle/input/<slug>/` mount — no error, just missing files.

    Args:
        dataset_ref: Dataset reference to poll.
        poll_seconds: Delay between status checks.
        timeout_seconds: Give up (and proceed anyway) after this long.
    """
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        result = subprocess.run(["kaggle", "datasets", "status", dataset_ref], capture_output=True, text=True)
        status_text = result.stdout.strip().lower()
        if result.returncode == 0 and "ready" in status_text:
            print(f"dataset {dataset_ref} ready")
            return
        time.sleep(poll_seconds)
    print(
        f"WARNING: {dataset_ref} did not report ready within {timeout_seconds}s — "
        "proceeding anyway, but the kernel's dataset mount may be incomplete.",
        file=sys.stderr,
    )


def _push_kernel(username: str, dataset_ref: str) -> str:
    """Write kernel-metadata.json and push the notebook as a GPU kernel.

    Args:
        username: Kaggle account username, used to namespace the kernel.
        dataset_ref: Dataset reference to attach so the notebook can read beats.json.

    Returns:
        The kernel reference (``username/slug``).
    """
    kernel_ref = f"{username}/{KERNEL_SLUG}"
    kernel_metadata = {
        "id": kernel_ref,
        # Kaggle derives the kernel's *actual* slug from this title, not from "id" above,
        # when the two disagree — silently creating the kernel under a different ref than
        # KERNEL_SLUG and breaking every later lookup. Title must slugify to KERNEL_SLUG
        # exactly: lowercase words joined by hyphens, no punctuation/digits-with-dots.
        "title": KERNEL_SLUG.replace("-", " ").title(),
        "code_file": NOTEBOOK_NAME,
        "language": "python",
        "kernel_type": "notebook",
        # Kaggle's kernel-metadata.json schema uses stringified booleans, not JSON
        # booleans — "true"/"false" as strings, not true/false. Sending real JSON
        # booleans here is silently ignored (falls back to the false default).
        "is_private": "true",
        "enable_gpu": "true",
        "enable_internet": "true",
        # Without this, Kaggle may hand the run an older P100 (compute capability sm_60,
        # Pascal) instead of a T4 — the current PyTorch build in Kaggle's image has
        # dropped sm_60 support, which crashes bitsandbytes with an opaque
        # "named symbol not found" CUDA error deep inside 4-bit weight loading.
        "machine_shape": "NvidiaTeslaT4",
        "dataset_sources": [dataset_ref],
        "competition_sources": [],
        "kernel_sources": [],
    }
    (THIS_DIR / "kernel-metadata.json").write_text(json.dumps(kernel_metadata, indent=2))
    push = subprocess.run(["kaggle", "kernels", "push", "-p", str(THIS_DIR)], capture_output=True, text=True)
    print(push.stdout)
    if push.returncode != 0 or "does not resolve to the specified id" in push.stdout:
        print(push.stderr, file=sys.stderr)
        raise SystemExit(
            f"Kernel push for '{kernel_ref}' failed or the title/id slug mismatched — "
            "see output above. The kernel may have been created under a different ref "
            f"than expected; check https://www.kaggle.com/{username}/kernels before retrying."
        )
    return kernel_ref


def _wait_for_completion(kernel_ref: str, poll_seconds: int, timeout_seconds: int) -> None:
    """Poll kernel status until it completes, fails, or the timeout elapses.

    Args:
        kernel_ref: Kernel reference to poll.
        poll_seconds: Delay between status checks.
        timeout_seconds: Total time to wait before giving up.

    Raises:
        SystemExit: If the run errors/cancels, or the timeout elapses.
    """
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        result = subprocess.run(
            ["kaggle", "kernels", "status", kernel_ref], capture_output=True, text=True, check=True
        )
        status_text = result.stdout.strip()
        print(status_text)
        lowered = status_text.lower()
        if "complete" in lowered:
            return
        if "error" in lowered or "cancel" in lowered:
            raise SystemExit(f"Kaggle kernel run did not complete: {status_text}")
        time.sleep(poll_seconds)
    raise SystemExit(f"Timed out after {timeout_seconds}s waiting for {kernel_ref} to finish.")


def _download_clips(kernel_ref: str, out_dir: Path) -> None:
    """Download the finished kernel's output and unzip its clips into out_dir.

    Args:
        kernel_ref: Kernel reference to fetch output from.
        out_dir: Local directory to extract clip files into.

    Raises:
        SystemExit: If the expected clips.zip is missing from the kernel output.
    """
    if KAGGLE_OUTPUT_DIR.exists():
        shutil.rmtree(KAGGLE_OUTPUT_DIR)
    KAGGLE_OUTPUT_DIR.mkdir()
    _run(["kaggle", "kernels", "output", kernel_ref, "-p", str(KAGGLE_OUTPUT_DIR)])

    clips_zip = KAGGLE_OUTPUT_DIR / "clips.zip"
    if not clips_zip.exists():
        raise SystemExit(
            f"Expected {clips_zip} in kernel output but it was not found. "
            f"Check {KAGGLE_OUTPUT_DIR} for a log of what the kernel actually produced."
        )
    out_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(clips_zip) as zip_file:
        zip_file.extractall(out_dir)
    print(f"extracted clips into {out_dir}")


def main() -> None:
    """Parse arguments and run the full push -> wait -> download pipeline."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--beats-json", required=True, type=Path, help="Path to a beats.json exported from Ekalivan")
    parser.add_argument("--out-dir", required=True, type=Path, help="Local directory to place downloaded clips in")
    parser.add_argument("--kaggle-username", default=None, help="Defaults to the `kaggle auth login` session's username")
    parser.add_argument("--poll-seconds", type=int, default=30, help="Delay between Kaggle status checks")
    parser.add_argument("--timeout-seconds", type=int, default=3600, help="Give up waiting after this many seconds")
    args = parser.parse_args()

    if not args.beats_json.exists():
        raise SystemExit(f"beats.json not found: {args.beats_json}")

    username = args.kaggle_username or _detect_kaggle_username()
    print(f"Kaggle username: {username}")
    dataset_ref = _stage_dataset(args.beats_json, username)
    kernel_ref = _push_kernel(username, dataset_ref)
    print(f"kernel pushed: https://www.kaggle.com/code/{kernel_ref}")
    _wait_for_completion(kernel_ref, args.poll_seconds, args.timeout_seconds)
    _download_clips(kernel_ref, args.out_dir)
    print("done.")


if __name__ == "__main__":
    main()
