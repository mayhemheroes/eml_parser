# Build Stage
FROM python:3.11-slim

RUN apt-get update && \
    DEBIAN_FRONTEND=NONINTERACTIVE apt-get install -y \
        git \
        clang \
        python3-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip install atheris

ADD . /src
WORKDIR /src
RUN python3 -m pip install .

CMD ["/src/mayhem/fuzz_eml.py"]
