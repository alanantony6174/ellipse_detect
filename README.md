# Standard Ellipse Detection Docker Setup

This repository provides a Dockerized environment for building and running the Standard Ellipse Detection algorithm. It includes installation of OpenCV 3.4.7, LAPACK 3.9.1, and other necessary dependencies.

## Prerequisites

Ensure you have Docker installed on your system. You may also need to enable X11 forwarding for GUI-based applications.

## Building the Docker Image

To build the Docker image, run the following command from the project root directory:

```sh
docker build -t ellipse-detection .
```

## Running the Docker Container

Run the container with the following command:

```sh
docker run --rm -it \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /home/alan/Desktop/standard-ellipse-detection/images:/opt/test_images \
    ellipse-detection
```

### Explanation of Flags:
- `--rm` removes the container after it exits.
- `-it` runs the container in interactive mode.
- `-e DISPLAY=$DISPLAY` allows GUI-based applications to work with X11 forwarding.
- `-v /tmp/.X11-unix:/tmp/.X11-unix` mounts the X11 socket for GUI display.
- `-v /home/alan/Desktop/standard-ellipse-detection/images:/opt/test_images` mounts the image directory into the container.

## Running Ellipse Detection

Inside the container, navigate to the build directory and run:

```sh
./bin/testdetect /opt/test_images/test3.jpg
```

## Notes
- If you encounter `Failed to load module "canberra-gtk-module"`, you can safely ignore this message.
- Modify the mounted image path (`-v /home/alan/Desktop/...`) according to your directory structure.
- Ensure your test images are in the `/opt/test_images` directory inside the container.

## License
This project is open-source. Feel free to use and modify as needed.

## Authors
Alan and contributors.

