# see https://hub.docker.com/_/swift
FROM swift:6.4.0-jammy

COPY . /container
WORKDIR /container

RUN swift build -c release

CMD ["swift", "test", "-c", "release"]
