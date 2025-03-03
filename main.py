from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
import subprocess
import shutil
import os
import base64

app = FastAPI()

UPLOAD_FOLDER = "/app/uploads"
RESULT_FOLDER = "/app/results"
BINARY_PATH = "/app/standard-ellipse-detection/build/bin/testdetect"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULT_FOLDER, exist_ok=True)

@app.post("/detect")
async def detect_ellipse(file: UploadFile = File(...)):
    # Save the uploaded file
    input_path = os.path.join(UPLOAD_FOLDER, file.filename)
    output_img_path = os.path.join(RESULT_FOLDER, f"{file.filename}_detected.png")
    output_txt_path = os.path.join(RESULT_FOLDER, f"{file.filename}_result.txt")

    with open(input_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Run the ellipse detection binary
    result = subprocess.run([BINARY_PATH, input_path], capture_output=True, text=True)

    # Check if the result text file exists
    if not os.path.exists(output_txt_path):
        return JSONResponse(content={
            "error": "Processed image result file not found",
            "stdout": result.stdout,
            "stderr": result.stderr
        })

    # Read the text file and convert to structured dictionary
    detection_result = {}
    with open(output_txt_path, "r") as f:
        lines = f.readlines()
        current_ellipse = None
        for line in lines:
            line = line.strip()
            if line.startswith("filename:"):
                detection_result["filename"] = line.split(": ")[1]
            elif line.startswith("ellipse_count:"):
                detection_result["ellipse_count"] = int(line.split(": ")[1])
                detection_result["ellipses"] = []
            elif line.startswith("Ellipse"):
                if current_ellipse:
                    detection_result["ellipses"].append(current_ellipse)
                current_ellipse = {}
            elif "Center" in line:
                values = line.split(": ")[1].strip("()").split(", ")
                current_ellipse["center"] = [float(values[0]), float(values[1])]
            elif "Axes" in line:
                values = line.split(": ")[1].strip("()").split(" x ")
                current_ellipse["axes"] = [float(values[0]), float(values[1])]
            elif "Rotation Angle" in line:
                current_ellipse["rotation_angle"] = float(line.split(": ")[1].split()[0])
            elif "Goodness" in line:
                current_ellipse["goodness"] = float(line.split(": ")[1])
            elif "Polarity" in line:
                current_ellipse["polarity"] = int(line.split(": ")[1])
            elif "Coverage Angle" in line:
                current_ellipse["coverage_angle"] = float(line.split(": ")[1].split()[0])
            elif "output_image_path" in line:
                detection_result["output_image_path"] = line.split(": ")[1]

        if current_ellipse:
            detection_result["ellipses"].append(current_ellipse)

    # Check if the processed image exists
    if not os.path.exists(output_img_path):
        return JSONResponse(content={
            "error": "Processed image not found",
            "binary_stdout": result.stdout,
            "binary_stderr": result.stderr
        })

    # Read image as base64
    with open(output_img_path, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode('utf-8')

    detection_result["image_base64"] = encoded_string

    return detection_result
