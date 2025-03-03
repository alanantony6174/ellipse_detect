# Standard Ellipse Detection Docker Setup

This repository provides a Dockerized environment for building and running the Standard Ellipse Detection algorithm. The setup builds OpenCV 3.4.7 and LAPACK 3.9.1 from source, compiles the ellipse detection binary along with its tests, and packages everything into a multi-stage Docker image. A FastAPI server is also provided to allow image processing via an HTTP endpoint.


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
    -v /home/user/Desktop/standard-ellipse-detection/images:/opt/test_images \
    ellipse-detection
```

Inside the container, navigate to the build directory and execute:

```sh
cd /app/standard-ellipse-detection/build
./bin/testdetect /opt/test_images/test3.jpg
```

Replace `/home/user/Desktop/standard-ellipse-detection/images` with your actual path containing test images.

## Using the FastAPI `/detect` Endpoint

The FastAPI server (launched automatically when the container starts) provides a POST endpoint `/detect` for ellipse detection. Here’s how it works:

1. **Upload an Image:**  
   Send a `multipart/form-data` POST request with the image file.

2. **Processing:**  
   The server saves the uploaded file, runs the `testdetect` binary on it, and checks for the output text file (named `<original_filename>_result.txt`) and image (named `<original_filename>_detected.png`).

3. **Response:**  
   Upon success, the endpoint returns a JSON object containing:
   - `filename`: The name of the processed file.
   - `ellipse_count`: The total number of ellipses detected.
   - `ellipses`: A list of ellipse objects, where each ellipse contains:
     - `center`: Center coordinates of the ellipse.
     - `axes`: Lengths of the short and long axes.
     - `rotation_angle`: The rotation angle of the ellipse.
     - `goodness`: A score representing the detection quality.
     - `polarity`: The polarity of the ellipse.
     - `coverage_angle`: The coverage angle of the ellipse.
   - `output_image_path`: The file path of the processed image.
   - `image_base64`: The processed image encoded as a base64 string.

   In case of an error (e.g., if the output text file isn’t found), the response will include an error message along with the binary’s standard output and error.

Example using `curl`:

```sh
curl -X POST "http://localhost:8000/detect" \
  -F "file=@/path/to/your/image.jpg"
```

## Notes

- If you see the message `Failed to load module "canberra-gtk-module"`, it can be safely ignored.
- Adjust the volume mount paths (`-v`) according to your local directory structure.
- This project is open-source. Feel free to use, modify, and contribute as needed.
- For further details or issues, refer to the code comments and documentation within the repository.

## Authors

Alan and contributors.

---

## Credits

This project is inspired by and builds upon the work from [memory-overflow/standard-ellipse-detection](https://github.com/memory-overflow/standard-ellipse-detection), a high-quality ellipse detector based on arc-support line segments.

---