/******************************************************************************/
/* Module:   drawing_Testbench                                                */
/* Modified: July 2025                                                        */
/* Author:   J Garside                                                        */
/*                                                                            */
/* Description:                                                               */
/*                                                                            */
/* Skeleton testbench: a template to get COMP32211 phase 1 tests started.     */
/*            As supplied this does not do very much actual verification! :-) */
/*                                                                            */
/******************************************************************************/

`timescale 1ns / 10ps

module unit_Testbench ();

`define CLOCK_PERIOD   10		// Some constant definitions
`define MAX_CYCLES     50
`define TPD             1

reg          clk;

reg          req;			// Host interface
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

wire         de_req;			// Framestore interface
reg          de_ack;
wire [17:0]  de_addr;
wire  [3:0]  de_nbyte;
wire [31:0]  de_data;

/* All the units for test have the same interface specification.             */
/* You can change what is instantiated as 'drawing_line' by varying 'unit_?' */
unit_1 drawing_line ( .clk      (clk),
                      .req      (req),
                      .ack      (ack),
                      .busy     (busy),
//                    .reset    (    ),    // Not used in these instances
                      .r0       (r0),
                      .r1       (r1),
                      .r2       (r2),
                      .r3       (r3),
                      .r4       (r4),
                      .r5       (r5),
                      .r6       (r6),
                      .r7       (r7),
                      .de_req   (de_req),
                      .de_ack   (de_ack),
                      .de_addr  (de_addr),
                      .de_nbyte (de_nbyte),
                      .de_data  (de_data));

// Several parallel 'threads' give timing flexibility.
initial clk <= 1;			// Define the clock
always #(`CLOCK_PERIOD/2) clk <= !clk;

initial					// Limit the simulation run
begin
repeat (`MAX_CYCLES) @ (posedge clk);	// Count off so many clock edges ...
$stop;					// ... then terminate
end

/*----------------------------------------------------------------------------*/

initial					// Input stimuli
begin
req <= 1'b0;				// Ensure inactive from start
repeat (4) @ (posedge clk);		// Wait a bit before starting

test_drawing_command(10, 10, 15, 20, 16'h0099);

// Etc.

end

always @ (posedge clk)			// Independent 'thread' for pixel I/F
if (de_ack !== 1'b0) de_ack <= #`TPD 1'b0;// !== comparison saves initialisation
else if (de_req)     de_ack <= #`TPD 1'b1;

// This always reacts immediately: this is not a thorough test since the real
// system will not always do this.

/*----------------------------------------------------------------------------*/

// Request a line is drawn: a primitive illustration of use of a Verilog 'task'.
task test_drawing_command(input reg [15:0] x0,
                          input reg [15:0] y0, 
                          input reg [15:0] x1, 
                          input reg [15:0] y1,
                          input reg [15:0] colour);
begin 
r0  <= x0;		// Set inputs
r1  <= y0;
r2  <= x1;
r3  <= y1;
r6  <= colour;

// Assert request and wait for acknowledgement
req <= 1'b1;
while (ack == 0 ) @(posedge clk);

// Once acknowledged, de-assert request
req <= 1'b0;
end 

endtask
// This illustrates a means of writing patterns conveniently with a task.
// It omits several aspects of a thorough test: e.g. it produces a 1 clock
// 'req' pulse instead of holding 'req' until 'ack' is received.
// Feel free to improve it!


// -----------------------------------------------------------------------------

// CONCURRENT ASSERTIONS FOR COMMAND INTERFACE, assumes synchronous behaviour
// ON posedge clk, if criteria is true "|->" perform test
// ##[n] delay test by n posedge clks, ##[a:b] declares a range

// Input Protocol

assertAckOnlyOneCycleLong: assert property (@(posedge clk) (ack == 1 |-> ##1 ack == 0))
                      else $warning("Warning ack should only be one clock cycle long.");

assertBusyStartsWhenAckRises: assert property (@(posedge clk) $rose(ack) |-> busy)
  else $warning("Busy should be asserted in the same cycle ack rises.");

// Unit waits until request arrives
assertAckOnlyTriggeredByReq: assert property (@(posedge clk) $rose(ack) |-> req)
  else $warning("Ack should only be raised if req is high.");



// Check busy is held for duration of the command?


// Output Protocol

// address, data etc. should not change while de_req is asserted

// de_ack goes high for single active clock edge when outputs are accepted

// de_req goes low after ack is seen


endmodule

/*============================================================================*/
