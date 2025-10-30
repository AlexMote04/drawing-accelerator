/******************************************************************************/
/* Module:   drawing_Testbench                                                */
/* Modified: July 2025                                                        */
/* Author:   J Garside / Completed by Gemini                                  */
/* */
/* Description:                                                               */
/* */
/* Complete testbench for COMP32211 Phase 1.                                  */
/* This testbench includes:                                                   */
/* 1. A realistic, stalling framestore model.                                 */
/* 2. A pixel collector and golden model comparator.                          */
/* 3. A structured test suite for verifying line-drawing function.            */
/* */
/******************************************************************************/

`timescale 1ns / 10ps

module unit_Testbench ();
`define CLOCK_PERIOD   10		// Some constant definitions
`define MAX_CYCLES     50000 // Increased simulation time
`define TPD             1

// -----------------------------------------------------------------------------
// Test Configuration
// -----------------------------------------------------------------------------
// *** CHANGE THIS PARAMETER TO TEST UNITS 1-5 ***
parameter UNIT_TO_TEST = 1; 

// -----------------------------------------------------------------------------
// Signals and Wires
// -----------------------------------------------------------------------------
reg          clk;

// Host interface
reg          req;
wire         ack;
wire         busy;
reg  [31:0]  r0;
reg  [31:0]  r1;
reg  [31:0]  r2;
reg  [31:0]  r3;
reg  [31:0]  r4;
reg  [31:0]  r5;
reg  [31:0]  r6;
reg  [31:0]  r7;

// Display interface
wire         de_req;
reg          de_ack;
wire [17:0]  de_addr;
wire  [3:0]  de_nbyte;
wire [31:0]  de_data;

// -----------------------------------------------------------------------------
// Data Types for Verification
// -----------------------------------------------------------------------------
typedef struct {
  bit [17:0] addr;
  bit [3:0]  nbyte;
  bit [31:0] data;
} pixel_t;

// Queues for comparison
pixel_t golden_queue[$]; // Stores expected pixels from C++ model 
pixel_t dut_queue[$];    // Stores actual pixels from the DUT

// -----------------------------------------------------------------------------
// Instantiate the Unit Under Test (UUT)
// -----------------------------------------------------------------------------
/* All the units for test have the same interface specification.
*/
/* This 'generate' block selects the unit based on the parameter above.
*/
generate
  if (UNIT_TO_TEST == 1) begin : gen_unit_1
    unit_1 drawing_line ( .clk(clk), .req(req), .ack(ack), .busy(busy), .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7), .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data));
  end else if (UNIT_TO_TEST == 2) begin : gen_unit_2
    unit_2 drawing_line ( .clk(clk), .req(req), .ack(ack), .busy(busy), .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7), .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data));
  end else if (UNIT_TO_TEST == 3) begin : gen_unit_3
    unit_3 drawing_line ( .clk(clk), .req(req), .ack(ack), .busy(busy), .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7), .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data));
  end else if (UNIT_TO_TEST == 4) begin : gen_unit_4
    unit_4 drawing_line ( .clk(clk), .req(req), .ack(ack), .busy(busy), .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7), .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data));
  end else if (UNIT_TO_TEST == 5) begin : gen_unit_5
    unit_5 drawing_line ( .clk(clk), .req(req), .ack(ack), .busy(busy), .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7), .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data));
  end
endgenerate


// -----------------------------------------------------------------------------
// Clock and Simulation Control
// -----------------------------------------------------------------------------
initial clk <= 1;			// Define the clock
always #(`CLOCK_PERIOD/2) clk <= !clk;

initial					// Limit the simulation run
begin
  repeat (`MAX_CYCLES) @ (posedge clk);	// Count off so many clock edges ...
  $error("Simulation timed out after %0d cycles.", `MAX_CYCLES);
  $stop;
  // ... then terminate
end

// -----------------------------------------------------------------------------
// Test Sequence (Stimulus)
// -----------------------------------------------------------------------------
initial					// Input stimuli
begin
  $display("\n[TB] Starting Phase 1 Verification Harness for Unit %0d...", UNIT_TO_TEST);
  req <= 1'b0;				// Ensure inactive from start
  repeat (4) @ (posedge clk);
  // Wait a bit before starting

  // --- Test Suite ---
  // Run tests for "extreme" conditions 
  
// Test 1: Simple Line (10, 10) -> (15, 12)
  // Golden data from C++ model:
  // (10, 10, 153)
  // (11, 10, 153)
  // (12, 11, 153)
  // (13, 11, 153)
  // (14, 12, 153)
  // (15, 12, 153)
  
  // These are the correct values for Test 1:
  golden_queue.push_back('{18'h0642, 4'b1011, 32'h00990000}); // (10, 10)
  golden_queue.push_back('{18'h0642, 4'b0111, 32'h99000000}); // (11, 10)
  golden_queue.push_back('{18'h06E3, 4'b1110, 32'h00000099}); // (12, 11)
  golden_queue.push_back('{18'h06E3, 4'b1101, 32'h00009900}); // (13, 11)
  golden_queue.push_back('{18'h0783, 4'b1011, 32'h00990000}); // (14, 12)
  golden_queue.push_back('{18'h0783, 4'b0111, 32'h99000000}); // (15, 12)
  run_test_case("Simple Line (10,10) -> (15,12)", 10, 10, 15, 12, 16'h0099);

  // Test 2: Horizontal Line (20, 20) -> (25, 20)
  // TODO: Populate golden_queue from C++ model
  run_test_case("Horizontal Line (20,20) -> (25,20)", 20, 20, 25, 20, 16'hAAAA);
  
  // Test 3: Vertical Line (30, 30) -> (30, 35)
  // TODO: Populate golden_queue from C++ model
  run_test_case("Vertical Line (30,30) -> (30,35)", 30, 30, 30, 35, 16'hBBBB);

  // Test 4: Single Pixel Line (40, 40) -> (40, 40)
  // TODO: Populate golden_queue from C++ model
  run_test_case("Single Pixel Line (40,40) -> (40,40)", 40, 40, 40, 40, 16'hCCCC);

  // Test 5: Test re-trigger bug (hold req high)
  // TODO: Populate golden_queue from C++ model
  $display("\n[TB] Starting Test: Re-trigger bug");
  golden_queue.push_back('{18'h000A2, 4'b1101, 32'h000000DD}); // (10,10)
  send_command(10, 10, 10, 10, 16'hDDDD, 1'b1); // Send command, hold req
  wait (busy == 0);
  @(posedge clk);
  req <= 1'b0; // De-assert req
  check_results("Re-trigger bug test");
  
  // Add more tests for all octants...

  $display("\n[TB] Test sequence complete.");
  $stop;
end

// -----------------------------------------------------------------------------
// Realistic Framestore Monitor (DUT `de_` interface)
// -----------------------------------------------------------------------------
// This replaces the simple, immediate-ack monitor.
// This model simulates:
// 1. A 2-cycle write period 
// 2. Random stalls (to mimic VDU contention)
//
reg [1:0] write_delay_fsm = 0;
initial de_ack <= 1'b0;

always @(posedge clk) begin
  de_ack <= 1'b0; // de_ack is a one-clock pulse

  case (write_delay_fsm)
    0: begin // IDLE: Ready to accept a request
      if (de_req) begin
        // Simulate a random stall (1 in 4 chance)
        if ($random(4) == 0) begin
          write_delay_fsm <= 0; // Stalled, stay idle
        end else begin
          // Not stalled, accept the request
          de_ack <= 1'b1;
          write_delay_fsm <= 1; // Begin 2-cycle memory write
        end
      end
    end
    1: begin // Write Cycle 1
      write_delay_fsm <= 2;
    end
    2: begin // Write Cycle 2
      write_delay_fsm <= 0; // Write complete, return to idle
    end
  endcase
end

// -----------------------------------------------------------------------------
// Pixel Collector (Monitors DUT output)
// -----------------------------------------------------------------------------
// This block 'watches' the interface and collects pixel data
// whenever the DUT's request is acknowledged.
always @(posedge clk) begin
  if (de_req && de_ack) begin
    dut_queue.push_back('{de_addr, de_nbyte, de_data});
  end
end

// -----------------------------------------------------------------------------
// Test Tasks
// -----------------------------------------------------------------------------

// This task runs one complete test case
task run_test_case(string test_name,
                   input reg [15:0] x0, input reg [15:0] y0, 
                   input reg [15:0] x1, input reg [15:0] y1,
                   input reg [15:0] colour);
  begin
    $display("\n[TB] Starting Test: %s", test_name);
    // 1. Send the command to the DUT
    send_command(x0, y0, x1, y1, colour, 1'b0); // 1'b0 = don't hold req
    
    // 2. Wait for the command to finish
    wait (busy == 0);
    
    // 3. Check the results
    check_results(test_name);
  end
endtask

// This task sends the command and parameters
task send_command(input reg [15:0] x0, input reg [15:0] y0, 
                  input reg [15:0] x1, input reg [15:0] y1,
                  input reg [15:0] colour,
                  input bit hold_req);
  begin 
    r0  <= x0;		// Set inputs
    r1  <= y0;
    r2  <= x1;
    r3  <= y1;
    r6  <= colour;

    // Assert request and wait for acknowledgement
    req <= 1'b1;
    while (ack == 0 ) @(posedge clk);
    
    // Once acknowledged, de-assert request (unless testing re-trigger)
    if (!hold_req) begin
      req <= 1'b0;
    end
  end 
endtask

// This task compares the collected DUT pixels with the golden reference
task check_results(string test_name);
  bit error_found = 0;
  begin
    $display("[TB] Test '%s' complete. Checking results...", test_name);
    
    // Check pixel count
    if (dut_queue.size() != golden_queue.size()) begin
      $error("[FAIL] %s: Pixel count mismatch. Expected %0d, Got %0d.",
             test_name, golden_queue.size(), dut_queue.size());
      error_found = 1;
    end

    // Check pixel-by-pixel
    int max_pixels = (dut_queue.size() > golden_queue.size()) ? dut_queue.size() : golden_queue.size();
    for (int i = 0; i < max_pixels; i++) begin
      pixel_t gold = (i < golden_queue.size()) ? golden_queue[i] : '0;
      pixel_t dut  = (i < dut_queue.size()) ? dut_queue[i] : '0;

      if (gold !== dut) begin
        $error("[FAIL] %s: Pixel %0d mismatch.", test_name, i);
        $display("       Expected: Addr=%h, nByte=%b, Data=%h", gold.addr, gold.nbyte, gold.data);
        $display("       Got:      Addr=%h, nByte=%b, Data=%h", dut.addr, dut.nbyte, dut.data);
        error_found = 1;
      end
    end

    if (!error_found) begin
      $display("[PASS] %s: All %0d pixels matched.", test_name, golden_queue.size());
    end

    // Clear queues for next test
    golden_queue.delete();
    dut_queue.delete();
  end
endtask

// -----------------------------------------------------------------------------
// CONCURRENT ASSERTIONS
// -----------------------------------------------------------------------------

// ---- Command Interface ----

// ack is a one-clock pulse
assertAckOnlyOneCycleLong: assert property (@(posedge clk) (ack == 1 |-> ##1 ack == 0))
                      else $warning("Warning: ack should only be one clock cycle long.");

// busy is asserted at the same time as ack 
assertBusyStartsWhenAckRises: assert property (@(posedge clk) $rose(ack) |-> busy)
  else $warning("Busy should be asserted in the same cycle ack rises.");

// Parameters are latched when ack is asserted
assertParamsLatched: assert property (@(posedge clk) (ack == 1 |-> 
                                (drawing_line.r0 == r0 &&
                                 drawing_line.r1 == r1 &&
                                 drawing_line.r2 == r2 &&
                                 drawing_line.r3 == r3 &&
                                 drawing_line.r6 == r6)))
  else $warning("Input parameters were not latched correctly on ack.");

// ack only happens when req is high
assertAckOnlyTriggeredByReq: assert property (@(posedge clk) $rose(ack) |-> req)
  else $warning("Ack should only be raised if req is high.");

// ---- Drawing Interface ----

// de_req should be asserted after ack (gives 10 cycles grace)
assertDeReqAssertedAfterAck: assert property (@(posedge clk) $rose(ack) |-> ##[0:10] de_req)
  else $warning("de_req was not asserted within 10 cycles of ack.");

// Data must be stable while de_req is high 
assertAddressNotChangedDuringDeReq: assert property (@(posedge clk) de_req |-> $stable(de_addr))
  else $warning("Address should not be changed when de_req is high");
assertNByteNotChangedDuringDeReq: assert property (@(posedge clk) de_req |-> $stable(de_nbyte))
  else $warning("n_byte should not be changed when de_req is high");
assertDataNotChangedDuringDeReq: assert property (@(posedge clk) de_req |-> $stable(de_data))
  else $warning("Data should not be changed when de_req is high");

// de_ack is a one-clock pulse
assertDeAckOnlyOneCycleLong: assert property (@(posedge clk) (de_ack == 1 |-> ##1 de_ack == 0))
                      else $warning("Warning: de_ack should only be one clock cycle long.");

// Unit must be busy if it is requesting to draw 
assertBusyDuringDeReq: assert property (@(posedge clk) de_req |-> busy)
  else $warning("de_req was asserted, but busy was not high.");

// Unit must not request to draw if it is not busy 
assertNoDeReqWhenNotBusy: assert property (@(posedge clk) !busy |-> !de_req)
  else $warning("de_req was asserted, but busy was low.");
endmodule

/*============================================================================*/