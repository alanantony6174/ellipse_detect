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

# Ensure directories exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULT_FOLDER, exist_ok=True)

@app.post("/detect")
async def detect_ellipse(file: UploadFile = File(...)):
    # Save uploaded file
    input_path = os.path.join(UPLOAD_FOLDER, file.filename)
    output_path = os.path.join(RESULT_FOLDER, f"{file.filename}_detected.png")

    with open(input_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Run ellipse detection
    result = subprocess.run(
        [BINARY_PATH, input_path],
        capture_output=True,
        text=True
    )

    # Check if the output image was generated
    if not os.path.exists(output_path):
        return JSONResponse(content={
            "error": "Processed image not found",
            "output": result.stdout,
            "errors": result.stderr
        })
    
    # Read image as base64
    with open(output_path, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode('utf-8')

    # Return JSON with output text and base64 image
    return {
        "output": result.stdout,
        "errors": result.stderr,
        "image_base64": encoded_string
    }
