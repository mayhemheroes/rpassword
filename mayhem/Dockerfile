# Build Stage
FROM --platform=linux/amd64 ubuntu:22.04 AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl build-essential
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

ADD . /src
WORKDIR /src/fuzzing

RUN cargo build --release && \
    mv target/release/fuzz_password_input /fuzz_password_input

# Package Stage
FROM ubuntu:22.04
COPY --from=builder /fuzz_password_input /
