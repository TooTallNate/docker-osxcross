FROM debian:jessie
MAINTAINER Andrew Dunham <andrew@du.nham.ca>

# Install build tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -yy && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yy \
        automake            \
        bison               \
        curl                \
        file                \
        flex                \
        gcc                 \
        g++                 \
        git                 \
        libmpc-dev          \
        libmpfr-dev         \
        libgmp-dev          \
        libtool             \
        pkg-config          \
        python              \
        texinfo             \
        vim                 \
        wget                \
        zlib1g-dev

# Install osxcross
# NOTE: The Docker Hub's build machines run varying types of CPUs, so an image
# built with `-march=native` on one of those may not run on every machine - I
# ran into this problem when the images wouldn't run on my 2013-era Macbook
# Pro.  As such, we remove this flag entirely.
RUN git clone https://github.com/tpoechtrager/osxcross.git /opt/osxcross
WORKDIR /opt/osxcross
RUN git checkout 474f359d2f27ff68916a064f0138c9188c63db7d
RUN sed -i -e 's|-march=native||g' ./build_gcc.sh ./build_clang.sh ./wrapper/build.sh
RUN ./tools/get_dependencies.sh
ARG OSXCROSS_SDK_VERSION=10.8
RUN curl -L -o ./tarballs/MacOSX${OSXCROSS_SDK_VERSION}.sdk.tar.xz https://s3.amazonaws.com/andrew-osx-sdks/MacOSX${OSXCROSS_SDK_VERSION}.sdk.tar.xz
RUN yes | PORTABLE=true ./build.sh
RUN yes | PORTABLE=true ./build_gcc.sh
RUN ./build_compiler_rt.sh
ENV PATH "$PATH:/opt/osxcross/target/bin"

WORKDIR /usr/src
ENV AR=x86_64-apple-darwin12-gcc-ar
ENV NM=x86_64-apple-darwin12-gcc-nm
ENV RANLIB=x86_64-apple-darwin12-gcc-ranlib
ENV STRIP=x86_64-apple-darwin12-strip
ENV CC='x86_64-apple-darwin12-gcc -flto -O3 -mmacosx-version-min=10.6'
ENV CXX='x86_64-apple-darwin12-g++ -flto -O3 -mmacosx-version-min=10.6'
ENV OSXCROSS_NO_INCLUDE_PATH_WARNINGS=1
