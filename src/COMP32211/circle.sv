/******************************************************************************/
/*                                                                            */
/*  Module:  circle                                                           */
/*  Author:  A Mote                                                           */
/*                                                                            */
/*  Description:                                                              */
/*  This unit draws a circle from centred at x (R0), y (R1) with radius (R4)  */
/*  in a solid colour (R6).                                                   */
/*                                                                            */
/******************************************************************************/
 
`timescale 1ns / 10ps 

module circle( 
                 input  logic        clk,
                 input  logic        reset,

                 input  logic        req,             /* Interface to command */
                 output logic        ack,

                 input  logic [31:0] r0,              /*  General arguments   */
                 input  logic [31:0] r1,
                 input  logic [31:0] r2,
                 input  logic [31:0] r3,
                 input  logic [31:0] r4,
                 input  logic [31:0] r5,
                 input  logic [31:0] r6,
                 input  logic [31:0] r7,

                 output logic        busy,            /*    Status outputs    */
                 output logic        done,

                 output logic        de_req,          /* Framestore interface */
                 input  logic        de_ack,
                 output logic [17:0] de_addr,
                 output logic  [3:0] de_nbyte,
                 output logic        de_rnw,
                 output logic [31:0] de_w_data,
                 input  logic [31:0] de_r_data,

                 input  logic [17:0] display_base,    /* Display status info. */
                 input  logic  [1:0] display_mode,    /*  *May* be used for   */
                 input  logic  [9:0] display_height,  /*  added flexibility.  */
                 input  logic  [9:0] display_width );


/* State enum */
typedef enum logic [2:0] { 
  IDLE,
  INIT,
  PLOT,
  CALC,
  DONE
} state_t;

/* Internal Signals*/
state_t state;

logic signed [17:0] cx, cy, rad; // Latched inputs
logic signed [17:0] x, y;        // Algo variables
logic signed [19:0] err;         // Error term (needs to be wider for calculation)
logic [2:0] octant_cnt;
logic valid_pixel;               // Used to selectively disable de_req when clipping occurs

// Current target pixel coordinates (combinatorial)
logic signed [17:0] plot_x, plot_y;
logic [7:0] colour;
logic [19:0] pixel_addr;

// Debugging Utilities
/*
always @(posedge clk) begin
    if (de_req && de_ack) 
        $display("HW WRITE: Octant %0d at Addr %h", octant_cnt, de_addr);
end

always @(posedge clk) begin
    if (de_req && de_ack) 
        $display("HW WRITE: x=%0d, y=%0d", x, y);
end
*/

// Combinatorial block to determine CURRENT target pixel based on octant
always_comb begin 
    case (octant_cnt)
        0: begin plot_x = cx + x; plot_y = cy + y; end
        1: begin plot_x = cx - x; plot_y = cy + y; end
        2: begin plot_x = cx + x; plot_y = cy - y; end
        3: begin plot_x = cx - x; plot_y = cy - y; end
        4: begin plot_x = cx + y; plot_y = cy + x; end
        5: begin plot_x = cx - y; plot_y = cy + x; end
        6: begin plot_x = cx + y; plot_y = cy - x; end
        7: begin plot_x = cx - y; plot_y = cy - x; end
        default: begin plot_x = cx; plot_y = cy; end
    endcase

    // Check bounds (Clipping)
    if(plot_x < 0 || plot_x >= 640 || plot_y < 0 || plot_y >= 480) begin 
        pixel_addr = 0; // Value doesn't matter
        valid_pixel = 0;
    end else begin 
        // Calculate Linear Address (Y * 640 + X)
        // 640 = 512 + 128 (shift 9 and shift 7)
        pixel_addr = (plot_y << 9) + (plot_y << 7) + plot_x;
        valid_pixel = 1;
    end
end

// Output Assignments (combinatorial)
assign de_addr = pixel_addr[19:2]; // Word address
assign de_w_data = {4{colour}};    // Replicate colour byte 4 times
assign de_rnw = 0;                 // This unit only writes
assign busy = state != IDLE;

// Byte selection (Active Low)
always_comb begin 
    case (pixel_addr[1:0])
        2'b00: de_nbyte = 4'b1110;
        2'b01: de_nbyte = 4'b1101;
        2'b10: de_nbyte = 4'b1011;
        2'b11: de_nbyte = 4'b0111;
        default: de_nbyte = 4'b1111;
    endcase
end

// Main Sequential FSM
always_ff @ (posedge clk) begin
    if (reset) begin
        state   <= IDLE;
        ack     <= 0;
        de_req  <= 0;
        done    <= 0;
    end else begin 
        // Defaults
        ack <= 0; // Ack is a pulse
        done <= 0; // Done is a pulse

        case (state)
            IDLE: begin
                if (req) begin 
                    state <= INIT;
                    // Latch inputs
                    cx <= r0[17:0];
                    cy <= r1[17:0];
                    rad <= r4[17:0];
                    colour <= r6[7:0];
                    ack <= 1;  // Pulse ack
                end
            end

            INIT: begin 
                x <= 0;
                y <= rad;
                err <= rad;
                octant_cnt <= 0;
                state <= PLOT;
                de_req <= 0; // Don't start writing until bounds have been checked
            end

            PLOT: begin
                // Case 1: We are currently requesting (waiting for de_ack)
                if (de_req) begin
                    if (de_ack) begin
                        de_req <= 0;
                        if (octant_cnt == 7) begin
                            state <= CALC;
                            octant_cnt <= 0; // Reset here to be safe
                        end else begin
                            octant_cnt <= octant_cnt + 1;
                        end
                    end
                    // Else keep de_req high
                end

                // Case 2: We are not requesting (Checking Validity)
                else begin
                    if (valid_pixel) de_req <= 1;
                    else begin
                      // Invalid: Skip
                      if (octant_cnt == 7) state <= CALC;
                      else octant_cnt <= octant_cnt + 1;
                    end
                end
            end 

            CALC: begin
                // 1. Declare temporary variables for the "next" state
                automatic logic signed [17:0] next_x;
                automatic logic signed [17:0] next_y;
                automatic logic signed [19:0] err_temp;
                
                // 2. Calculate the updates (same math as before)
                // Using arithmetic shift or multiplication ensures signed behavior
                err_temp = err - signed'(x <<< 1);

                if (err_temp < 0) begin
                    next_y = y - 1;
                    err <= err_temp + signed'(y <<< 1);
                end else begin
                    next_y = y;
                    err <= err_temp;
                end
                
                next_x = x + 1;
                
                // 3. Commit updates to registers
                x <= next_x;
                y <= next_y;
                octant_cnt <= 0;

                // 4.Check termination on the *NEXT* values
                // If the NEW values have crossed, we are done. Do not go back to PLOT.
                if (next_x <= next_y) begin
                    state <= PLOT;
                end else begin
                    state <= IDLE;
                    done <= 1;
                end
            end
            default: state <= IDLE;
        endcase
    end
end
endmodule
