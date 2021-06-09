FROM rust:1.46.0 as build

# cd "${PROJECT}"
# docker build --tag woc/rustic-core:0.1.0-SNAPSHOT -f docker/app/Dockerfile .

RUN rustup component add rustfmt

WORKDIR /usr/src/dendrite_example
COPY proto/ proto/
COPY src/ src/
COPY *.rs ./
COPY Cargo.* ./
RUN bash -c 'touch src/proto_{dendrite_config,example}.rs'

RUN cargo install --path .

FROM gcr.io/distroless/cc-debian10

COPY --from=build /usr/local/cargo/bin/dendrite_example /usr/local/bin/dendrite_example

CMD ["dendrite_example"]