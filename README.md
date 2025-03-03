# Standard Ellipse Detection Docker Setup

This repository provides a Dockerized environment for building and running the Standard Ellipse Detection algorithm. The setup builds OpenCV 3.4.7 and LAPACK 3.9.1 from source, compiles the ellipse detection binary along with its tests, and packages everything into a multi-stage Docker image. A FastAPI server is also provided to allow image processing via an HTTP endpoint.

## Overview

The Docker image consists of two stages:

- **Builder Stage (Ubuntu 20.04):**
  - Installs build dependencies including Git, CMake, compilers, and libraries.
  - Builds OpenCV 3.4.7 from source.
  - Builds LAPACK 3.9.1 and installs LAPACKE header files.
  - Compiles the Standard Ellipse Detection project and its tests (producing `bin/testdetect`).

- **Final Runtime Stage (Python 3.8-slim):**
  - Installs only the necessary runtime libraries (e.g., GTK, libgfortran).
  - Sets up required Python packages (FastAPI, Uvicorn, etc.).
  - Copies the compiled binaries and libraries from the builder stage.
  - Provides a FastAPI server (defined in `main.py`) exposing a `/detect` endpoint for processing images.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system.
- For GUI-based applications or if you want to view images directly, ensure you have X11 forwarding enabled (using the `-e DISPLAY` and X11 socket volume mount).

## Building the Docker Image

From the project root directory, build the Docker image using:

```sh
docker build -t ellipse-detection .
```

Alternatively, if you prefer to use the pre-built image from Docker Hub, pull it with:

```sh
docker pull alan6174/ellipse-detect-api:latest
```

## Running the Docker Container

### To Run the FastAPI Server

The FastAPI server exposes a `/detect` endpoint to process images. Run the container with:

```sh
docker run --rm -it \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -p 8000:8000 \
    alan6174/ellipse-detect-api:latest
```

This command:
- Removes the container when it exits (`--rm`).
- Runs interactively (`-it`).
- Exports your host's X11 display to the container.
- Publishes port `8000` for the FastAPI server.

### To Run the Ellipse Detection Binary Manually

If you want to run the command-line binary directly (for example, for testing with specific images), mount your image directory and run the container:

```sh
docker run --rm -it \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /home/alan/Desktop/standard-ellipse-detection/images:/opt/test_images \
    ellipse-detection
```

Inside the container, navigate to the build directory and execute:

```sh
cd /app/standard-ellipse-detection/build
./bin/testdetect /opt/test_images/test3.jpg
```

Replace `/home/alan/Desktop/standard-ellipse-detection/images` with your actual path containing test images.

## Using the FastAPI `/detect` Endpoint

The FastAPI server (launched automatically when the container starts) provides a POST endpoint `/detect` for ellipse detection. Here’s how it works:

1. **Upload an Image:**  
   Send a `multipart/form-data` POST request with the image file.

2. **Processing:**  
   The server saves the uploaded file, runs the `testdetect` binary on it, and checks for the output image (named `<original_filename>_detected.png`).

3. **Response:**  
   The endpoint returns a JSON object with:
   - `output`: The standard output from the ellipse detection binary.
   - `errors`: Any error messages from the detection process.
   - `image_base64`: The processed image encoded in base64.

Example using `curl`:

```sh
curl -X POST "http://localhost:8000/detect" \
  -F "file=@/path/to/your/image.jpg"
```

## Dockerfile Breakdown

- **Stage 1 (Builder):**
  - Based on `ubuntu:20.04` with noninteractive APT.
  - Installs build tools and libraries.
  - Downloads, builds, and installs OpenCV 3.4.7.
  - Downloads, builds, and installs LAPACK 3.9.1.
  - Copies the local Standard Ellipse Detection project, builds the project, and creates tests.

- **Stage 2 (Runtime):**
  - Uses `python:3.8-slim` as the base.
  - Installs runtime dependencies like GTK and libgfortran.
  - Installs necessary Python packages.
  - Copies over built libraries and binaries from the builder stage.
  - Sets up required directories for uploads and results.
  - Launches the FastAPI server using Uvicorn.

## Notes

- If you see the message `Failed to load module "canberra-gtk-module"`, it can be safely ignored.
- Adjust the volume mount paths (`-v`) according to your local directory structure.
- This project is open-source. Feel free to use, modify, and contribute as needed.
- For further details or issues, refer to the code comments and documentation within the repository.

## Authors

Alan and contributors.

---

This updated README now reflects all the build, run, and usage instructions as described in your Dockerfile and server setup.