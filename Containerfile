FROM ubuntu as base

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_LISTCHANGES_FRONTEND=none
ENV APT_LISTBUGS_FRONTEND=none

RUN echo 'tzdata tzdata/Areas select America' | debconf-set-selections && \
    echo 'tzdata tzdata/Zones/America select New_York' | debconf-set-selections

RUN apt update && apt install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    curl \
    sudo \
    ubuntu-minimal && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM base as final

RUN useradd -m tester && \
    echo "tester:tester" | chpasswd && \
    adduser tester sudo

USER tester
WORKDIR /home/tester
