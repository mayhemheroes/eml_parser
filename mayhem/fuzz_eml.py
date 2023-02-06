#!/usr/bin/env python3

import atheris
import sys
import fuzz_helpers

with atheris.instrument_imports(include=['eml_parser']):
    import eml_parser

ep = eml_parser.EmlParser()
def TestOneInput(data):
    fdp = fuzz_helpers.EnhancedFuzzedDataProvider(data)
    try:
        ep.decode_email_bytes(fdp.ConsumeRemainingBytes())
    except (AttributeError, IndexError):
        return -1

def main():
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()


if __name__ == "__main__":
    main()
