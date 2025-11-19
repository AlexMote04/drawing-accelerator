import os
import subprocess
import sys

# --- Configuration ---
CONTROLLER_EXE = "./controller"      # Path to the C++ model
VERILOG_SIM_EXE = "./simv"           # Path to your compiled Verilog sim
TEST_DIR = "./test_cases"            # Directory containing the .txt command files
GOLDEN_DIR = "./golden_outputs"      # Where to save the generated golden data

def run_test(test_name):
    command_file = os.path.join(TEST_DIR, f"{test_name}.txt")
    golden_file = os.path.join(GOLDEN_DIR, f"{test_name}.gold")
    
    print(f"--- Running Test: {test_name} ---")

    # 1. Generate Golden Data using the C++ Controller
    # Equivalent to: ./controller < test_cases/line_draw.txt > golden_outputs/line_draw.gold
    print(f"  [1/2] Generating golden data...")
    try:
        with open(command_file, 'r') as infile, open(golden_file, 'w') as outfile:
            # We assume your C++ controller outputs the formatted (addr nbyte data) 
            # lines to stdout, which we redirect to the .gold file.
            subprocess.run(CONTROLLER_EXE, stdin=infile, stdout=outfile, check=True)
    except subprocess.CalledProcessError:
        print("  Error: C++ Controller failed.")
        return False
    except FileNotFoundError:
         print(f"  Error: Input file {command_file} not found.")
         return False

    # 2. Run Verilog Simulation
    # We pass the golden filename as a generic argument (plusarg) to Verilog
    print(f"  [2/2] Running Verilog Simulation...")
    try:
        # +golden_file=... is a standard way to pass args to Verilog
        cmd = [VERILOG_SIM_EXE, f"+golden_file={golden_file}"]
        
        # Capture output to check for "TEST PASSED" or specific failures
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if "TEST PASSED" in result.stdout: # Adjust this string based on your Verilog $display
            print("  RESULT: PASS ✅")
            return True
        else:
            print("  RESULT: FAIL ❌")
            print("  --- Sim Output Snippet ---")
            print(result.stdout[-300:]) # Print last 300 chars of sim output
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