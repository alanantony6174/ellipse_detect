import subprocess
import argparse
import os

def run_ellipse_detection(binary_path, image_path):
    if not os.path.exists(binary_path):
        print(f"Error: Binary file not found at {binary_path}")
        return
    
    if not os.path.exists(image_path):
        print(f"Error: Image file not found at {image_path}")
        return
    
    try:
        result = subprocess.run([binary_path, image_path], capture_output=True, text=True)
        print("Output:\n", result.stdout)
        if result.stderr:
            print("Errors:\n", result.stderr)
    except Exception as e:
        print(f"Failed to run inference: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run ellipse detection inference on an image.")
    parser.add_argument("image_path", type=str, help="Path to the input image")
    args = parser.parse_args()

    binary_path = "./build/bin/testdetect"  # Update if the binary is in a different path
    run_ellipse_detection(binary_path, args.image_path)
