import subprocess
import os
import sys

# --- Configuration ---
CONTROLLER_EXE = "./models/controller"
PIXELS_PATH = "pixels.txt"
os.environ["SALT_LICENSE_SERVER"] = "1718@cadmaster.cs.man.ac.uk"
VERILOG_SIM_EXE = "/cadtools5/questasim/QUESTA-CORE-PRIME_2023.4/questasim/bin/vsim"

# Display Resolution
FS_WIDTH = 640
FS_HEIGHT = 480

UNIT_ID = 6 # Circle has unit id 6
SIM_ARGS = [
    "-64", "-gui", "-voptargs=+acc", f"-gUNIT_ID={UNIT_ID}", "-L", "GLIB", "-do", "do wave.do; run -all"
]

# --- Test Cases ---
# Format: ("test_name", "command args")
LINE_TESTS = [
    ("test_simple_line",     "line 10 10 15 12 0x99"),
    ("test_horizontal_line", "line 20 20 25 20 0xAA"),
    ("test_vertical_line",   "line 30 30 30 35 0xBB"),
    ("test_single_pixel",    "line 40 40 40 40 0xCC"),
    ("test_reverse_line",    "line 50 50 45 45 0xDD")
]

CIRCLE_TESTS = [
    ("test_center_standard", "circle 320 240 100 0xFF"),
    ("test_center_odd", "circle 321 241 100 0x8"),
    ("test_center_odd_radius", "circle 320 240 101 0x80"),
    ("test_radius_small",    "circle 100 100 2 0xAA"),
    ("test_radius_large",    "circle 320 240 230 0xBB"),
    ("test_clip_top",        "circle 320 10 20 0xCC"),
    ("test_clip_left",       "circle 10 240 20 0xDD"),
    ("test_clip_right",      "circle 630 240 20 0xEE"),
    ("test_clip_bottom",     "circle 320 470 20 0x99"),
    ("test_clip_corner",     "circle 0 0 50 0x88"),
    ("test_fully_offscreen", "circle 800 600 50 0x77"),
]

def run_commands_cpp(commands):
    try:
        joined_cmds = "\n".join(commands)
        input_command = f"clear\n{joined_cmds}\nquit\n"
        subprocess.run(CONTROLLER_EXE, input=input_command, text=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running C++ model: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: C++ executable not found at {CONTROLLER_EXE}")
        sys.exit(1)

def read_pixel_outputs():
    if not os.path.exists(PIXELS_PATH):
        print("No pixel output file")
        return []
    with open(PIXELS_PATH, mode='r', encoding='utf-8') as f:
        return [line.strip() for line in f if line.strip()]

def convert_golden_data_sv(golden_data_cpp: list[str]):
    golden_data_sv = []
    for pixel_value_cpp in golden_data_cpp:
        parts = pixel_value_cpp.split()
        if len(parts) < 2: continue

        byte_addr, colour = map(int, parts)
        word_addr = byte_addr // 4
        byte_pos = byte_addr % 4

        nbyte = ~(1 << byte_pos) & 0xF
        data = colour << (byte_pos * 8)

        golden_data_sv.append(f"{word_addr} {nbyte} {data}")
    return golden_data_sv

def run_simulation(test_name, commands, golden_data_list):
    # Files are created in the root, where vsim expects them
    cmd_file = f"{test_name}_cmd.dat"
    gold_file = f"{test_name}_gold.dat"

    with open(cmd_file, "w", encoding='utf-8') as f:
        f.write("\n".join(commands))
    with open(gold_file, "w", encoding='utf-8') as f:
        f.write("\n".join(golden_data_list))

    # Clean, simple command construction
    sim_cmd = [
            VERILOG_SIM_EXE,
            "Phase_1.unit_Testbench", # Explicit library path
            "GLIB.glbl"               # Global reset
        ] + SIM_ARGS + [              # Add flags defined at top
            f"+command_file={cmd_file}",
            f"+golden_file={gold_file}"
        ]

    print(f"--- Running Simulation: {test_name} ---")
    try:
        # Run the simulation
        subprocess.run(sim_cmd, capture_output=True, text=True, check=True)

    except subprocess.CalledProcessError as e:
        print(f"❌ Simulation Crashed for {test_name}")
        print(e.stderr) # Print stderr to see why vsim crashed
    finally:
        if os.path.exists(cmd_file): os.remove(cmd_file)
        if os.path.exists(gold_file): os.remove(gold_file)

def run_tests(tests):
    commands = [test[1] for test in tests]
    run_commands_cpp(commands)
    golden_pixels_cpp = read_pixel_outputs()
    golden_pixels_sv = convert_golden_data_sv(golden_pixels_cpp)
    run_simulation("Running All Tests", commands, golden_pixels_sv)

if __name__ == "__main__":
    run_tests(CIRCLE_TESTS)
