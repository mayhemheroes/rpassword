FROM rust:latest as builder
# RUN rustup toolchain install nightly && cargo install cargo-fuzz
COPY . /rpassword/
WORKDIR /rpassword/fuzzing
RUN cargo build

FROM debian:bullseye-slim
COPY --from=builder /rpassword/fuzzing/target/debug .