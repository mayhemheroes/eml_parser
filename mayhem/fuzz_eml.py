#!/usr/bin/env python3
"""Atheris harness for eml_parser: parse arbitrary raw RFC822 bytes."""

import binascii
import sys

import atheris

import fuzz_helpers

with atheris.instrument_imports():
    import eml_parser

try:
    from dateutil.parser import ParserError as _DateutilParserError
except ImportError:  # pragma: no cover
    _DateutilParserError = ValueError

# Parser instance reused across iterations (matches upstream usage).
_ep = eml_parser.EmlParser()

# Exceptions that are input-dependent / expected on malformed email bytes.
# These mirror the error types eml_parser itself catches internally while
# working around broken files; surfacing them is not a real defect.
_EXPECTED = (
    ValueError,
    TypeError,
    IndexError,
    AttributeError,
    KeyError,
    LookupError,
    UnicodeError,
    binascii.Error,
    RecursionError,
    OverflowError,
    _DateutilParserError,
)


def TestOneInput(data):
    fdp = fuzz_helpers.EnhancedFuzzedDataProvider(data)
    raw = fdp.ConsumeRemainingBytes()
    try:
        _ep.decode_email_bytes(raw)
    except _EXPECTED:
        return -1


def main():
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()


if __name__ == "__main__":
    main()
