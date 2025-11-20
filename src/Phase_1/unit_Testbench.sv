/******************************************************************************/
/* Module:   drawing_Testbench                                                */
/* Modified: July 2025                                                        */
/* Description: Automated Testbench for COMP32211 Phase 1                     */
/******************************************************************************/

`timescale 1ns / 10ps

module unit_Testbench ();
`define CLOCK_PERIOD   10   
`define MAX_CYCLES     50000
`define TPD             1

// Configuration
parameter UNIT_TO_TEST = 1; 

// Signals
reg          clk;
reg          req;
wire         ack;
wire         busy;
reg  [31:0]  r0, r1, r2, r3, r4, r5, r6, r7;

// Display interface
wire         de_req;
reg          de_ack;
wire [17:0]  de_addr;
wire  [3:0]  de_nbyte;
wire [31:0]  de_data;

// Data Types
typedef struct {
  bit [17:0] addr;
  bit [3:0]  nbyte;
  bit [31:0] data;
} pixel_t;

pixel_t golden_queue[$]; 
pixel_t dut_queue[$];    

// Instantiate DUT
generate
  if (UNIT_TO_TEST == 1) begin : gen_unit_1
    unit_1 drawing_line ( .clk(clk), .req(req), .ack(ack), .busy(busy), .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7), .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data));
  end
  // ... (Add other units as needed) ...
endgenerate

// Clock Generation
initial clk <= 1;
always #(`CLOCK_PERIOD/2) clk <= !clk;

// Simulation Timeout
initial begin
  repeat (`MAX_CYCLES) @ (posedge clk);
  $error("Simulation timed out.");
  $stop;
end

// -----------------------------------------------------------------------------
// MAIN TEST SEQUENCE
// -----------------------------------------------------------------------------
initial begin
  string golden_file_path;
  string command_file_path;
  
  $display("\n[TB] Starting Verification Harness...");
  req <= 1'b0;
  repeat (4) @ (posedge clk);

  // 1. Get file paths from Command Line (via Python script)
  if (!$value$plusargs("golden_file=%s", golden_file_path)) begin
     $error("[TB] No golden_file specified! Use +golden_file=<path>");
     $finish;
  end
  
  if (!$value$plusargs("command_file=%s", command_file_path)) begin
     $error("[TB] No command_file specified! Use +command_file=<path>");
     $finish;
  end

  // 2. Load the Golden Data (Expected Memory Writes)
  load_golden_data(golden_file_path);

  // 3. Execute the Input Commands (Drive the DUT)
  execute_input_file(command_file_path);

  // 4. Compare Final Results
  check_results();

  $display("[TB] Test sequence complete.");
  $finish;
end

// -----------------------------------------------------------------------------
// TASKS
// -----------------------------------------------------------------------------

// TASK: Load Golden Data from File (from C++ Model)
// Current Golden data has lines like: "010 010 153"
// Ideal Verilog DUT expects input like "18'addr, 4'nbyte, 32'temp_data"
// pixel_byte_address = (x + y*640)
// pixel_word_address = pixel_byte_address / 4
// pixel_byte_lane = pixel_byte_address % 4
// temp_nbyte = ~(1 << pixel_byte_lane) // Active low
// temp data should be calculated by converting the decimal value to binary, and then shifting to the appropriate byte lane
task load_golden_data(string file_path);
  integer file_handle, status, x_coord, y_coord, temp_addr, temp_nbyte, temp_data;
  pixel_t temp_pixel;
  
  file_handle = $fopen(file_path, "r");
  if (file_handle == 0) begin
    $error("[TB] Failed to open golden file: %s", file_path);
    $finish;
  end

  $display("[TB] Loading golden data from: %s", file_path);
  golden_queue.delete();

  while (!$feof(file_handle)) begin
    status = $fscanf(file_handle, "%d %d %d\n", x_coord, y_coord, temp_data);
    if (status == 3) begin
      temp_pixel.addr  = 18'(temp_addr);
      temp_pixel.nbyte = 4'(temp_nbyte);
      temp_pixel.data  = 32'(temp_data);
      golden_queue.push_back(temp_pixel);
    end
  end
  $fclose(file_handle);
endtask

// TASK: Read Command File and Drive DUT
// Current lines like: "line 10 10 20 20 0x99"
// Ideal lines like: "line "18'addr, 4'nbyte, 32'temp_data""
// pixel_byte_address = (x + y*640)
// pixel_word_address = pixel_byte_address / 4
// pixel_byte_lane = pixel_byte_address % 4
// temp_nbyte = ~(1 << pixel_byte_lane) // Active low
// temp data should be calculated by converting the decimal value to binary, and then shifting to the appropriate byte lane
task execute_input_file(string file_path);
  integer file_handle, status;
  string cmd_type;
  integer x0, y0, x1, y1, color;
  string line_ignore;
  
  file_handle = $fopen(file_path, "r");
  if (file_handle == 0) begin
    $error("[TB] Failed to open command file: %s", file_path);
    $finish;
  end

  $display("[TB] Executing commands from: %s", file_path);

  while (!$feof(file_handle)) begin
    // Peek at the command type
    status = $fscanf(file_handle, "%s", cmd_type);
    
    if (status == 1) begin
      if (cmd_type == "line") begin
        // Parse: line x0 y0 x1 y1 color
        status = $fscanf(file_handle, "%d %d %d %d %h", x0, y0, x1, y1, color);
        if (status == 5) begin
            send_command(16'(x0), 16'(y0), 16'(x1), 16'(y1), 16'(color));
            wait(busy == 0); // Wait for DUT to finish
        end
      end else begin
        // Ignore "clear", "dump", "quit" or comments
        void'($fgets(line_ignore, file_handle)); 
      end
    end
  end
  $fclose(file_handle);
endtask

// TASK: Send Command to DUT
task send_command(input reg [15:0] x0, y0, x1, y1, colour);
  begin 
    $display("[TB] Sending Line: (%0d,%0d) -> (%0d,%0d) Color: %h", x0, y0, x1, y1, colour);
    r0 <= x0; r1 <= y0; r2 <= x1; r3 <= y1; r6 <= colour;
    req <= 1'b1;
    while (ack == 0 ) @(posedge clk);
    req <= 1'b0;
  end 
endtask

// TASK: Compare Results
task check_results();
  bit error_found = 0;
  int max_pixels;
  
  $display("\n[TB] Checking Results...");
  
  if (dut_queue.size() != golden_queue.size()) begin
    $error("[FAIL] Count Mismatch! Expected: %0d, Got: %0d", golden_queue.size(), dut_queue.size());
    error_found = 1;
  end

  max_pixels = (dut_queue.size() > golden_queue.size()) ? dut_queue.size() : golden_queue.size();
  
  for (int i = 0; i < max_pixels; i++) begin
    // Safe access to queues
    pixel_t gold = (i < golden_queue.size()) ? golden_queue[i] : '{default:0};
    pixel_t dut  = (i < dut_queue.size()) ? dut_queue[i] : '{default:0};

    if (gold !== dut) begin
       $error("[FAIL] Mismatch at index %0d", i);
       $display("       Expected: Addr=%d nByte=%b Data=%h", gold.addr, gold.nbyte, gold.data);
       $display("       Got:      Addr=%d nByte=%b Data=%h", dut.addr, dut.nbyte, dut.data);
       error_found = 1;
       if (i > 10) begin $display("...too many errors, stopping check."); break; end
    end
  end

  if (!error_found && max_pixels > 0) 
    $display("TEST PASSED"); // Python script looks for this exact string
  else if (max_pixels == 0)
    $display("[WARN] No pixels were drawn/expected.");
    
  // Clean up
  golden_queue.delete();
  dut_queue.delete();
endtask

// -----------------------------------------------------------------------------
// CONCURRENT ASSERTIONS (PROTOCOL CHECKERS)
// -----------------------------------------------------------------------------

// ---- Command Interface ----

// 1. Ack should only be high for exactly one clock cycle
assertAckOnlyOneCycleLong: assert property (@(posedge clk) (ack == 1 |-> ##1 ack == 0))
  else $error("Protocol Violation: 'ack' signal stuck high for >1 cycle.");

// 2. Busy must go high immediately when Ack rises (handshake start)
assertBusyStartsWhenAckRises: assert property (@(posedge clk) $rose(ack) |-> busy)
  else $error("Protocol Violation: 'busy' did not assert when 'ack' rose.");

// 3. Ack should only happen if we actually requested something
assertAckOnlyTriggeredByReq: assert property (@(posedge clk) $rose(ack) |-> req)
  else $error("Protocol Violation: Spurious 'ack' received without 'req'.");

// ---- Display/Memory Interface ----

// 4. If we Ack a command, the DUT must eventually ask to draw (within 500 cycles)
assertDeReqAssertedAfterAck: assert property (@(posedge clk) $rose(ack) |-> ##[0:500] de_req)
  else $warning("Performance Warning: de_req took >500 cycles after ack.");

// 5. Stability Checks: Address/Data must not change while Request is active
assertAddressStable: assert property (@(posedge clk) de_req |-> $stable(de_addr))
  else $error("Protocol Violation: de_addr changed while de_req was high.");

assertNByteStable: assert property (@(posedge clk) de_req |-> $stable(de_nbyte))
  else $error("Protocol Violation: de_nbyte changed while de_req was high.");

assertDataStable: assert property (@(posedge clk) de_req |-> $stable(de_data))
  else $error("Protocol Violation: de_data changed while de_req was high.");

// 6. Memory Ack should be a single pulse (simulating our TB behavior logic)
assertDeAckPulse: assert property (@(posedge clk) (de_ack == 1 |-> ##1 de_ack == 0))
  else $error("Testbench Error: de_ack stuck high (Monitor issue).");

// 7. The DUT must be 'busy' if it is currently trying to draw
assertBusyDuringDeReq: assert property (@(posedge clk) de_req |-> busy)
  else $error("Protocol Violation: DUT requested memory access (de_req) but 'busy' is low.");

// 8. The DUT should not ask to draw if it isn't busy processing a command
assertNoDeReqWhenNotBusy: assert property (@(posedge clk) !busy |-> !de_req)
  else $error("Protocol Violation: Spurious de_req while DUT was not busy.");

// -----------------------------------------------------------------------------
// Monitor & Interface Logic
// -----------------------------------------------------------------------------
reg [1:0] write_delay_fsm = 0;
initial de_ack <= 1'b0;

always @(posedge clk) begin
  de_ack <= 1'b0; 
  case (write_delay_fsm)
    0: if (de_req) begin
         if ($random(4) == 0) write_delay_fsm <= 0; // Random stall
         else begin de_ack <= 1'b1; write_delay_fsm <= 1; end
       end
    1: write_delay_fsm <= 2;
    2: write_delay_fsm <= 0;
  endcase
end

always @(posedge clk) begin
  if (de_req && de_ack) begin
    dut_queue.push_back('{de_addr, de_nbyte, de_data});
  end
end

endmodule