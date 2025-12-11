/******************************************************************************/
/* Module:   unit_Testbench                                                   */
/* Description: Automated Testbench for COMP32211 Phase 1                     */
/******************************************************************************/

`timescale 1ns / 10ps

module unit_Testbench ();

  `define CLOCK_PERIOD   10   
  `define MAX_CYCLES     50000

  // -- Configuration Parameters --
  // Can be overridden via command line: vsim ... -gUNIT_ID=2
  parameter UNIT_ID = 1; 

  // -- Signals --
  reg          clk;
  reg          rst_n;
  
  // Command Interface
  reg          req;
  wire         ack;
  wire         busy;
  reg  [31:0]  r0, r1, r2, r3, r4, r5, r6, r7;
  
  // Display/Memory Interface
  wire         de_req;
  reg          de_ack;
  wire [17:0]  de_addr;
  wire  [3:0]  de_nbyte;
  wire [31:0]  de_data;
  bit state = 0;

  // -- Data Structures --
  typedef struct {
    bit [17:0] addr;
    bit [3:0]  nbyte;
    bit [31:0] data;
  } pixel_t;

  pixel_t golden_queue[$];
  pixel_t dut_queue[$];

  // -- DUT Instantiation (Selectable) --
  generate
    case (UNIT_ID)
      1: unit_1 u_dut (
           .clk(clk), .req(req), .ack(ack), .busy(busy), 
           .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7),
           .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data)
         );
      2: unit_2 u_dut (
           .clk(clk), .req(req), .ack(ack), .busy(busy), 
           .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7),
           .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data)
         );
      3: unit_3 u_dut (
           .clk(clk), .req(req), .ack(ack), .busy(busy), 
           .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7),
           .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data)
         );
      4: unit_4 u_dut (
           .clk(clk), .req(req), .ack(ack), .busy(busy), 
           .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7),
           .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data)
         );
      5: unit_5 u_dut (
           .clk(clk), .req(req), .ack(ack), .busy(busy), 
           .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7),
           .de_req(de_req), .de_ack(de_ack), .de_addr(de_addr), .de_nbyte(de_nbyte), .de_data(de_data)
         );
      default: initial $error("Invalid UNIT_ID selected");
    endcase
  endgenerate

  // -- Clock & Timeout --
  initial clk = 0;
  always #(`CLOCK_PERIOD/2) clk = ~clk;

  initial begin
    repeat (`MAX_CYCLES) @(posedge clk);
    $display("[TIMEOUT] Simulation ran for too many cycles.");
    $stop;
  end

  // -----------------------------------------------------------------------------
  // MAIN TEST SEQUENCER
  // -----------------------------------------------------------------------------
  initial begin
    string golden_file_path;
    string command_file_path;
    
    // Initial Cleanup
    req   = 0;
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
    
    // 1. Get Arguments
    if (!$value$plusargs("golden_file=%s", golden_file_path)) begin
       $display("[ERROR] No golden_file specified!"); $finish;
    end
    if (!$value$plusargs("command_file=%s", command_file_path)) begin
       $display("[ERROR] No command_file specified!"); $finish;
    end

    // 2. Load Data & Run
    load_golden_data(golden_file_path);
    execute_input_file(command_file_path);

    // 3. Verify
    check_results();
    $stop;
  end

  // -----------------------------------------------------------------------------
  // TASKS
  // -----------------------------------------------------------------------------

  task load_golden_data(string file_path);
    integer fd, code, t_addr, t_nbyte, t_data;
    pixel_t p;
    
    fd = $fopen(file_path, "r");
    if (!fd) begin $error("Cannot open golden file: %s", file_path); $finish; end

    golden_queue.delete();
    while (!$feof(fd)) begin
      // Expect format: Address nByte Data
      code = $fscanf(fd, "%d %d %d", t_addr, t_nbyte, t_data);
      if (code == 3) begin
        p.addr  = 18'(t_addr);
        p.nbyte = 4'(t_nbyte);
        p.data  = 32'(t_data);
        golden_queue.push_back(p);
      end
    end
    $fclose(fd);
  endtask

  task execute_input_file(string file_path);
    integer fd, code;
    string cmd;
    integer x0, y0, x1, y1, col;
    integer rad;
    string dummy;

    fd = $fopen(file_path, "r");
    if (!fd) begin $error("Cannot open command file: %s", file_path); $finish; end

  while (!$feof(fd)) begin
      code = $fscanf(fd, "%s", cmd);

      if (code == 1) begin
        if (cmd == "line") begin
            code = $fscanf(fd, "%d %d %d %d %h", x0, y0, x1, y1, col);
            if (code == 5) begin
                drive_line(x0, y0, x1, y1, col);
                while (busy) @(posedge clk);
                repeat(5) @(posedge clk);
            end
        end 
        else if (cmd == "circle") begin
            code = $fscanf(fd, "%d %d %d %h", x0, y0, rad, col); 
            if (code == 4) begin
                // You need a new task or modify drive_dut to handle circles
                drive_circle(x0, y0, rad, col); 
                while (busy) @(posedge clk);
                repeat(5) @(posedge clk);
            end
        end 
        else begin
            // Consume line if not matched
            void'($fgets(dummy, fd));
        end
      end
    end
    $fclose(fd);
  endtask

  task drive_line(input int x0, y0, x1, y1, col);
    $display("[TB] Driving Line: %0d,%0d -> %0d,%0d (Color %h)", x0, y0, x1, y1, col);
    @(posedge clk);
    r0 <= x0; r1 <= y0; r2 <= x1; r3 <= y1; r6 <= col;
    req <= 1;
    while (!ack) @(posedge clk);
    req <= 0;
  endtask

  task drive_circle(input int x0, y0, rad, col);
    $display("[TB] Driving Circle: %0d,%0d, (Radius %0d) (Color %h)", x0, y0, rad, col);
    @(posedge clk);
    r0 <= x0; r1 <= y0; r4 <= rad; r6 <= col;
    req <= 1;
    while (!ack) @(posedge clk);
    req <= 0;
  endtask

  task check_results();
    bit fail;
    int count;
    pixel_t g;
    pixel_t d;
    int i;

    fail = 0;
    
    count = (golden_queue.size() > dut_queue.size()) ? golden_queue.size() : dut_queue.size();
    
    $display("---------------------------------------------------");
    $display("Checking %0d pixels...", count);

    for (i=0; i<count; i++) begin
      // Create a mask based on active-low byte enables
      bit [31:0] data_mask;

      g = (i < golden_queue.size()) ? golden_queue[i] : '{default:0};
      d = (i < dut_queue.size())    ? dut_queue[i]    : '{default:0};

      data_mask[31:24] = (g.nbyte[3] == 0) ? 8'hFF : 8'h00;
      data_mask[23:16] = (g.nbyte[2] == 0) ? 8'hFF : 8'h00;
      data_mask[15:8]  = (g.nbyte[1] == 0) ? 8'hFF : 8'h00;
      data_mask[7:0]   = (g.nbyte[0] == 0) ? 8'hFF : 8'h00;

      if (g.addr !== d.addr || g.nbyte !== d.nbyte || 
         (g.data & data_mask) !== (d.data & data_mask)) begin
         
        $display("[FAIL] Mismatch at #%0d", i);
        $display("       EXP: Addr:%h nByte:%b Data (Masked):%h", g.addr, g.nbyte, (g.data & data_mask));
        
        $display("       GOT: Addr:%h nByte:%b Data (Raw)   :%h", d.addr, d.nbyte, d.data);
        fail = 1;
      end
    end

    if (!fail && count > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $display("---------------------------------------------------");
  endtask

  // -----------------------------------------------------------------------------
  // MEMORY MONITOR & ACK HANDLER
  // -----------------------------------------------------------------------------
  
  // This simulates memory wait states. 
  // The real hardware takes at 2 cycles for a write.
  always @(posedge clk) begin
    de_ack <= 1'b0;
    
    case (state)
      0: begin
        if (de_req) begin
           // Wait here randomly, then move to ACK state
           if ($urandom_range(3) == 0) begin
               // Do NOT ack here yet
               state <= 1; 
           end
        end
      end
      1: begin
        // ACK happens one cycle later
        de_ack <= 1'b1;
        state <= 0;
      end
    endcase
  end

  // Capture DUT Output
  always @(posedge clk) begin
    if (de_ack) begin
      dut_queue.push_back('{de_addr, de_nbyte, de_data});
    end
  end

  // -----------------------------------------------------------------------------
  // ASSERTIONS
  // -----------------------------------------------------------------------------
  
  // -- Command Interface Assertions --

  // Ack must not be asserted if Req is low (spurious Acks)
  property p_ack_needs_req;
    @(posedge clk) disable iff (!rst_n) ack |-> req;
  endproperty
  assert property(p_ack_needs_req) 
    else $error("Protocol Violation: DUT asserted ACK without REQ.");

  // Busy must be asserted when Ack is asserted
  property p_ack_implies_busy;
    @(posedge clk) disable iff (!rst_n) ack |-> busy;
  endproperty
  assert property(p_ack_implies_busy) 
    else $error("Protocol Violation: BUSY not asserted during ACK.");

  // Ack Must Pulse
  property p_ack_pulse;
    @(posedge clk) disable iff (!rst_n) ack |=> !ack;
  endproperty
  assert property(p_ack_pulse) else $error("Protocol Violation: ACK high for more than one clock cycle.");

  // -- Drawing (Memory) Interface Assertions --
  // Address Stability: Address must not change while waiting for memory ack
  property p_addr_stable;
    @(posedge clk) disable iff (!rst_n) (de_req && !de_ack) |=> $stable(de_addr);
  endproperty
  assert property(p_addr_stable) 
    else $error("Protocol Violation: de_addr changed while de_req was pending.");

  // Data Stability: Data must not change while waiting for memory ack
  property p_data_stable;
    @(posedge clk) disable iff (!rst_n) (de_req && !de_ack) |=> $stable(de_data);
  endproperty
  assert property(p_data_stable) 
    else $error("Protocol Violation: de_data changed while de_req was pending.");

  // Byte Enable Stability
  property p_nbyte_stable;
    @(posedge clk) disable iff (!rst_n) (de_req && !de_ack) |=> $stable(de_nbyte);
  endproperty
  assert property(p_nbyte_stable) 
    else $error("Protocol Violation: de_nbyte changed while de_req was pending.");

  // Check Busy signal logic
  property p_busy_active;
    @(posedge clk) disable iff (!rst_n) de_req |-> busy;
  endproperty
  assert property(p_busy_active) else $error("Protocol Violation: Access requested while NOT busy");

  // Request must drop after Ack (unless back-to-back)
  // The manual says "de_req should be inactivated unless there is another output request."
  // This is hard to enforce strictly

  // -- Valid Output Range Assertions --
  // Address Out of Bounds (Screen Size Check)
  // 640x480 pixels = 307,200 pixels.
  // 4 pixels per word = 76,800 words.
  // Max valid word address = 76,799 (decimal) = 0x12BFF
  property p_valid_address;
    @(posedge clk) disable iff (!rst_n) de_req |-> (de_addr < 76800);
  endproperty
  assert property(p_valid_address) 
    else $error("Functional Error: de_addr out of bounds (screen overflow).");

  // Valid Byte Strobes
  // nByte is active low. At least one byte must be enabled (0), 
  // so nByte cannot be 4'b1111 (0xF) during a request.
  property p_valid_strobes;
    @(posedge clk) disable iff (!rst_n) de_req |-> (de_nbyte != 4'hF);
  endproperty
  assert property(p_valid_strobes) 
    else $error("Functional Error: de_req asserted but no byte lanes enabled.");

endmodule