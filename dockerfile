# Stage 1: Builder
FROM ubuntu:20.04 as builder
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    gfortran \
    wget \
    pkg-config \
    unzip \
    libgtk2.0-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    python3 \
    python3-pip \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    && rm -rf /var/lib/apt/lists/*

# Set Python3 as the default
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Python packages needed for building
RUN pip3 install --no-cache-dir numpy opencv-python

# Build OpenCV 3.4.7 from source
WORKDIR /opt
RUN wget -O opencv-3.4.7.zip https://github.com/opencv/opencv/archive/3.4.7.zip && \
    unzip opencv-3.4.7.zip && \
    cd opencv-3.4.7 && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && \
    make install && ldconfig

# Build and install LAPACK 3.9.1
WORKDIR /opt
RUN wget https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.9.1.tar.gz -O lapack-3.9.1.tar.gz && \
    tar -xzvf lapack-3.9.1.tar.gz && \
    cd lapack-3.9.1 && \
    mkdir build && cd build && \
    cmake .. && make -j$(nproc) && \
    make install && ldconfig && \
    cp ../LAPACKE/include/*.h /usr/local/include/

# Copy the local standard-ellipse-detection project into /app
WORKDIR /app
COPY . /app/standard-ellipse-detection

# Build standard-ellipse-detection (release build)
WORKDIR /app/standard-ellipse-detection
RUN mkdir build && cd build && \
    cmake .. -DOpenCV_DIR=/usr/local/lib/cmake/opencv3 && \
    make -j$(nproc) && \
    make install

# Build tests for standard-ellipse-detection (creates /build/bin/testdetect)
WORKDIR /app/standard-ellipse-detection/build
RUN cmake .. -DBUILD_TESTING=ON -DOpenCV_DIR=/usr/local/lib/cmake/opencv3 && \
    make -j$(nproc)

# Stage 2: Final runtime image
FROM python:3.8-slim
WORKDIR /app

# Install missing runtime libraries: libgfortran and GTK runtime
RUN apt-get update && apt-get install -y \
    libgfortran5 \
    libgtk2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install only necessary Python packages for runtime
RUN pip install --no-cache-dir fastapi uvicorn python-multipart numpy opencv-python

# Copy built libraries and binaries from builder stage
COPY --from=builder /usr/local /usr/local
COPY --from=builder /app/standard-ellipse-detection/build /app/standard-ellipse-detection/build

# Create required directories
RUN mkdir -p /app/uploads /app/results

# Copy FastAPI server script
COPY main.py /app/main.py

# Expose FastAPI port
EXPOSE 8000

# Run FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--app-dir", "/app"]
