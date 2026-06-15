#!/usr/bin/env bash
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer -g}"
: "${CC:=clang}" ; : "${CXX:=clang++}"
: "${MAYHEM_JOBS:=$(nproc)}"
export CC CXX MAYHEM_JOBS

cd "$SRC"

# Test oracle: clean venv (no sanitizers). Install package + test deps.
python3 -m venv /mayhem/test-venv
/mayhem/test-venv/bin/pip install --upgrade pip setuptools wheel
(
  export CC=clang CXX=clang++
  unset CFLAGS CXXFLAGS LDFLAGS
  # `test` lives under [dependency-groups] (PEP 735), not [project.optional-dependencies],
  # so `.[test]` does not pull it in — install the package and the test tooling explicitly.
  /mayhem/test-venv/bin/pip install -e .
  /mayhem/test-venv/bin/pip install "pytest>=8.3" pytest-sugar coverage
)

# Fuzz build: separate venv with atheris + PyInstaller ELF.
python3 -m venv /mayhem/fuzz-venv
/mayhem/fuzz-venv/bin/pip install --upgrade pip setuptools wheel
export CFLAGS="$SANITIZER_FLAGS" CXXFLAGS="$SANITIZER_FLAGS" LDFLAGS="$SANITIZER_FLAGS"
/mayhem/fuzz-venv/bin/pip install atheris pyinstaller
/mayhem/fuzz-venv/bin/pip install -e .

$CC -shared -fPIC -o /mayhem/asan_defaults.so "$SRC/mayhem/asan_defaults.c"

/mayhem/fuzz-venv/bin/pyinstaller \
  --distpath /tmp/pyinst-out \
  --workpath /tmp/pyinst-work \
  --specpath /tmp/pyinst-spec \
  --onefile \
  --name fuzz-eml \
  --paths "$SRC/mayhem" \
  --collect-all eml_parser \
  --collect-all publicsuffixlist \
  --collect-all charset_normalizer \
  --collect-all dateutil \
  --hidden-import fuzz_helpers \
  --hidden-import email \
  --hidden-import email.policy \
  --hidden-import email.message \
  --hidden-import email.headerregistry \
  --hidden-import email.utils \
  --hidden-import base64 \
  --hidden-import binascii \
  --hidden-import collections \
  --hidden-import collections.abc \
  --hidden-import datetime \
  --hidden-import hashlib \
  --hidden-import ipaddress \
  --hidden-import logging \
  --hidden-import os.path \
  --hidden-import pathlib \
  --hidden-import re \
  --hidden-import typing \
  --hidden-import urllib.parse \
  --hidden-import uuid \
  --hidden-import html \
  --add-binary /mayhem/asan_defaults.so:. \
  "$SRC/mayhem/fuzz_eml.py"

install -m 0755 /tmp/pyinst-out/fuzz-eml /mayhem/fuzz-eml
