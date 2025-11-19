import os
import subprocess
import sys
import shutil

# --- Configuration ---
CONTROLLER_EXE = "../models/controller" # Path to the C++ model
VERILOG_SIM_EXE = "./simv"              # Path to your compiled Verilog sim
TEST_DIR = "./drawing_commands"         # Directory containing the .txt command files
GOLDEN_DIR = "./golden_outputs"         # Where to save the generated golden data
DEFAULT_DUMP_FILE = "vsDump.txt"        # The file your C++ model automatically generates

def run_test(test_name):
    command_file = os.path.join(TEST_DIR, f"{test_name}.txt")
    golden_file = os.path.join(GOLDEN_DIR, f"{test_name}.gold")

    print(f"--- Running Test: {test_name} ---")

    # 1. Generate Golden Data using the C++ Controller
    print(f"  [1/2] Generating golden data...")

    # Clean up any stale dump file
    if os.path.exists(DEFAULT_DUMP_FILE):
        try:
            os.remove(DEFAULT_DUMP_FILE)
        except OSError as e:
            print(f"  Warning: Could not remove stale {DEFAULT_DUMP_FILE}: {e}")

    try:
        with open(command_file, 'r') as infile:
            # Run controller. Suppress stdout.
            subprocess.run(CONTROLLER_EXE, stdin=infile, stdout=subprocess.DEVNULL, check=True)

        # Move the output file
        if os.path.exists(DEFAULT_DUMP_FILE):
            os.replace(DEFAULT_DUMP_FILE, golden_file)
        else:
            print(f"  Error: Controller ran, but {DEFAULT_DUMP_FILE} was not generated.")
            return False

    except subprocess.CalledProcessError:
        print("  Error: C++ Controller failed (non-zero exit code).")
        return False
    except FileNotFoundError:
         print(f"  Error: Input file {command_file} not found.")
         return False

    # 2. Run Verilog Simulation
    print("  [2/2] Running Verilog Simulation...")
    try:
        # We pass BOTH the golden file AND the command file to Verilog
        cmd = [
            VERILOG_SIM_EXE, 
            f"+golden_file={golden_file}",
            f"+command_file={command_file}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if "TEST PASSED" in result.stdout:
            print("  RESULT: PASS ✅")
            return True
        else:
            print("  RESULT: FAIL ❌")
            print("  --- Sim Output Snippet ---")
            print(result.stdout[-500:]) # Show a bit more error context
            return False

    except Exception as e:
        print(f"  Error running simulation: {e}")
        return False

if __name__ == "__main__":
    # Ensure output directory exists
    os.makedirs(GOLDEN_DIR, exist_ok=True)

    # List of tests to run (filenames without .txt extension)
    tests_to_run = ["test_simple_line", "test_vertical_line", "test_single_pixel"]

    passes = 0
    for test in tests_to_run:
        if run_test(test):
            passes += 1
    
    print(f"\nSummary: {passes}/{len(tests_to_run)} tests passed.")