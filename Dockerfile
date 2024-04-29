# syntax = docker/dockerfile:1.4
FROM nixos/nix:2.22.0 AS builder

WORKDIR /tmp/build
RUN mkdir /tmp/nix-store-closure
COPY . .

RUN \
  --mount=type=cache,target=/nix,from=nixos/nix:2.22.0,source=/nix \
  --mount=type=cache,target=/root/.cache \
  --mount=type=bind,target=/tmp/build \
  <<EOF
  nix \
    --extra-experimental-features "nix-command flakes" \
    --option filter-syscalls false \
    --show-trace \
    --log-format raw \
    build .#dev --out-link /tmp/output/result
  cp -R $(nix-store -qR /tmp/output/result) /tmp/nix-store-closure
EOF


FROM scratch

WORKDIR /workspace

COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /tmp/output/ /workspace/
ENV PATH=/workspace/result/bin:$PATH
RUN ["ln","-s", "/workspace/result/bin", "/bin"]
RUN ["mkdir","-p", "/usr/bin"]
RUN ["ln","-s", "/workspace/result/bin/env", "/usr/bin/env"]
# For bats
RUN ["mkdir","--mode", "1777", "/tmp"]
