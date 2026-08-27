FROM alpine:3.22

# Runtime + test dependencies. GNU coreutils/grep/sed over busybox for parity
# with common Linux setups (helpers.sh uses sed -r, sort -rn, grep -E).
RUN apk add --no-cache \
  bash \
  coreutils \
  fzf \
  gawk \
  git \
  grep \
  ncurses \
  sed \
  tmux \
  zoxide

# bats + helper libraries, pinned
RUN git clone --depth 1 --branch v1.12.0 https://github.com/bats-core/bats-core /opt/bats \
  && git clone --depth 1 --branch v0.3.0 https://github.com/bats-core/bats-support /opt/bats-libs/bats-support \
  && git clone --depth 1 --branch v2.1.0 https://github.com/bats-core/bats-assert /opt/bats-libs/bats-assert \
  && ln -s /opt/bats/bin/bats /usr/local/bin/bats

ENV BATS_LIB_PATH=/opt/bats-libs

WORKDIR /workspace
