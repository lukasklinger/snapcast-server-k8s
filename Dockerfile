# image OS
ARG ALPINE_BASE="3"

# SnapCast build stage
FROM alpine:${ALPINE_BASE} as compiler

# snapcast version tag to build
ENV VERSION="v0.27.0"

RUN apk -U add \
        alsa-lib-dev \
        avahi-dev \
        bash \
        boost-dev \
        build-base \
        ccache \
        cmake \
        expat-dev \
        flac-dev \
        git \
        libvorbis-dev \
        opus-dev \
        soxr-dev

RUN git clone --recursive --depth 1 --branch $VERSION https://github.com/badaix/snapcast.git

RUN cd snapcast && cmake -S . -B build \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DBUILD_WITH_PULSE=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_CLIENT=OFF \
        ..

RUN cd snapcast && cmake --build build --parallel 3

# SnapWeb build stage
FROM node:alpine as snapweb

RUN apk -U add build-base git
RUN npm install -g typescript
RUN git clone https://github.com/badaix/snapweb
RUN make -C snapweb

# Final stage
FROM alpine:${ALPINE_BASE}
LABEL maintainer="lukasklinger"

RUN apk add --no-cache \
        alsa-lib \
        avahi-libs \
        expat \
        flac \
        libvorbis \
        opus \
        soxr

COPY --from=compiler snapcast/bin/snapserver /usr/local/bin/
COPY --from=snapweb snapweb/dist/ /usr/share/snapserver/snapweb

EXPOSE 1704
EXPOSE 1705
EXPOSE 1780

ENTRYPOINT ["snapserver"]
