# Build Stage
FROM fuzzers/atheris:2.0.7-python3.9
RUN apt-get update && \
    DEBIAN_FRONTEND=NONINTERACTIVE apt-get install -y git

ADD . /src
WORKDIR /src
RUN python3 -m pip install .

CMD ["/src/mayhem/fuzz_eml.py"]
