
FROM ubuntu:20.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies required for building OpenCV, LAPACK, and ellipse-detection
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    gfortran \
    wget \
    pkg-config \
    libgtk2.0-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Build OpenCV 3.4.7 from source
WORKDIR /opt
RUN wget -O opencv-3.4.7.zip https://github.com/opencv/opencv/archive/3.4.7.zip && \
    unzip opencv-3.4.7.zip && \
    cd opencv-3.4.7 && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && \
    make install && ldconfig

# Download, build, and install LAPACK 3.9.1 from the correct GitHub URL
WORKDIR /opt
RUN wget https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.9.1.tar.gz -O lapack-3.9.1.tar.gz && \
    tar -xzvf lapack-3.9.1.tar.gz && \
    cd lapack-3.9.1 && \
    mkdir build && cd build && \
    cmake .. && make -j$(nproc) && \
    make install && ldconfig && \
    cp ../LAPACKE/include/*.h /usr/local/include/

# Clone, build, and install standard-ellipse-detection using OpenCV3
WORKDIR /opt
RUN git clone https://github.com/memory-overflow/standard-ellipse-detection.git && \
    cd standard-ellipse-detection && \
    mkdir build && cd build && \
    cmake .. -DOpenCV_DIR=/usr/local/lib/cmake/opencv3 && make -j$(nproc) && \
    make install

# Set the working directory for standard-ellipse-detection
WORKDIR /opt/standard-ellipse-detection/build

# Build tests for standard-ellipse-detection
RUN cmake .. -DBUILD_TESTING=ON -DOpenCV_DIR=/usr/local/lib/cmake/opencv3 && \
    make -j$(nproc)

# Default command
CMD ["/bin/bash"]