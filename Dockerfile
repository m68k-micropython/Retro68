# vim:ft=dockerfile

# Base image
FROM debian:trixie-slim AS base

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        --no-install-recommends --no-install-suggests \
        make libc6-dev gcc g++ git macutils curl \
        python3-pip python3-wheel-whl xz-utils \
        libgmp-dev libgmpxx4ldbl libmpc3  && apt-get clean

RUN pip install --break-system-packages pyyaml click

# Add toolchain to default PATH
ENV PATH=/Retro68-build/toolchain/bin:$PATH
WORKDIR /root

# Build image
FROM base AS build

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        --no-install-recommends --no-install-suggests\
        cmake libgmp-dev libmpfr-dev libmpc-dev \
        libboost-all-dev bison texinfo bzip2 \
        ruby flex && apt-get clean

ADD . /Retro68

RUN mkdir /Retro68-build && \
    mkdir /Retro68-build/bin && \
    bash -c "cd /Retro68-build && bash /Retro68/build-toolchain.bash --no-ppc"

# Release image
FROM base AS release

ENV INTERFACES=multiversal

COPY --from=build \
    /Retro68/interfaces-and-libraries.sh \
    /Retro68/prepare-headers.sh \
    /Retro68/prepare-rincludes.sh \
    /Retro68/install-universal-interfaces.sh \
    /Retro68/docker-entrypoint.sh \
    /Retro68-build/bin/

COPY --from=build /Retro68-build/toolchain /Retro68-build/toolchain

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        --no-install-recommends --no-install-suggests \
        libboost-filesystem1.83.0 libboost-program-options1.83.0 libboost-wave1.83.0 libboost-thread1.83.0 

RUN curl https://nodejs.org/dist/v22.18.0/node-v22.18.0-linux-x64.tar.xz | unxz | tar -C /usr/local --wildcards --wildcards-match-slash --strip-components=1 -xvf - '*/bin/*' '*/share/*' '*/lib/*'

LABEL org.opencontainers.image.source https://github.com/m68k-micropython/Retro68

CMD [ "/bin/bash" ]
ENTRYPOINT [ "/Retro68-build/bin/docker-entrypoint.sh" ]
