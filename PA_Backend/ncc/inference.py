
import sys
import time

def main():
    if len(sys.argv) != 3:
        print("Usage: python inference.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(input_file, "r") as f:
        prompt = f.readline().strip()

    # Simulate a delay for inference
    time.sleep(5)

    response = f"This is a dummy response to the prompt: '{prompt}'"

    with open(output_file, "w") as f:
        f.write(response)

if __name__ == "__main__":
    main()
