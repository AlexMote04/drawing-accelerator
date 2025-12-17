/******************************************************************************/
/*                                                                            */
/*  Module:        drawing_control                                            */
/*                                                                            */
/*  Description:   Module holding register file and control logic for the     */
/*                 drawing system. This module handles the control            */
/*                 signals for the drawing units, and provides a              */
/*                 register interface to the processor.                       */
/*                 It also has an argument interface from the Video           */
/*                 Display Unit Controller (VDUC).                            */
/*                                                                            */
/*  Authors:       A Mathews, J Garside                                       */
/*  Updated:       August 2025                                                */
/*                                                                            */
/******************************************************************************/
/*                                                                            */
/* Drawing Control Register Descriptions:                                     */
/*                                                                            */
/* 00-1C  Arguments       32  R/W  General drawing arguments.                 */
/*  20    Command          3  WO   Code to activate particular drawing unit.  */
/*  24    Status          14  RO   See status definition below.               */
/*  28    Status Clear    14  WO   Clears bits of Status Registers.           */
/*  2C    Status Set      14  WO   Set bits of Status register.               */
/*  30    Drawing base    20  R/W  Set base framestore for drawing.           */
/*  40    Display base    20  RO   Display start (top left).                  */
/*  44    Display mode     2  RO   Mode code {colour, resolution}.            */
/*  48    Display width   10  RO   Width in pixels.                           */
/*  4C    Display height  10  RO   Height in pixels.                          */
/*                                                                            */
/*  Status Register further description:                                      */
/*                                                                            */
/*  Bit  Name    Width  R/W   Description                                     */
/*  0-7  Busy      8     RO   Busy flags for each drawing unit.               */
/*  8    Done      1     RO   High if a drawing unit has completed a request. */
/*                            Cleared by via the Status Clear register.       */
/*  9    Queue     1     RO   High if a drawing unit has a job queued.        */
/*                            This is cleared as tasks are committed.         */
/*                            or via the Status Clear register 'Q' bit.       */
/*  10   Job IE    1     R/W  Interrupt enable for Done.  If set, an interrupt*/
/*                            may be triggered when a drawing unit completes. */
/*  11   Queue IE  1     R/W  Interrupt enable for Queue.                     */
/*                            If set, an interrupt may be generated when a    */
/*                            the drawing engine has a job queued.            */
/*  12   Base Bit  1     R/W  If set, the drawing_base register is offered as */
/*                            the base address for drawing.  If clear, the    */
/*                            VDUC display_base register is selected.         */
/*  13   Reset     1     R/W  Writing a 1 to this bit will reset all drawing  */
/*                            drawing units.                                  */
/*                                                                            */
/******************************************************************************/

typedef logic [31:0] argument_bus_t [7:0];

module drawing_control(
               input  logic          clk,
               input  logic          reset_i,
               input  logic          cs_i,         /* Processor bus interface */
               input  logic          read_i,
               input  logic          write_i,
               input  logic   [31:0] address_i,
               input  logic    [1:0] size_i,
               input  logic    [1:0] mode_i,
               output logic          stall_o,
               output logic   [2:0]  abort_v_o,
               input  logic   [31:0] data_in,
               output logic   [31:0] data_out,
               output logic    [1:0] ireq_o,

               output argument_bus_t arguments_o,
               output logic   [31:0] command_o,
               output logic          req_o,
               input  logic          ack_i,

               input  wire    [17:0] v_base_i,
               input  wire     [1:0] v_mode_i,
               input  wire     [9:0] v_width_i,
               input  wire     [9:0] v_height_i,

               output logic   [17:0] display_base_o,
               output logic    [1:0] display_mode_o,
               output logic    [9:0] display_width_o,
               output logic    [9:0] display_height_o,

               input  logic   [7:0] busy_i,        /* Busy signals from units */
               input  logic   [7:0] done_i,  /* Completion signals from units */
               output logic         drawing_unit_reset_o);

localparam REG_ARGUMENTS      = 8'h00;                    /* Register offsets */
localparam REG_COMMAND        = 8'h20;
localparam REG_STATUS         = 8'h24;
localparam REG_STATUS_CLR     = 8'h28;
localparam REG_STATUS_SET     = 8'h2C;
localparam REG_DRAWING_BASE   = 8'h30;
localparam REG_DISPLAY_BASE   = 8'h40;
localparam REG_DISPLAY_MODE   = 8'h44;
localparam REG_DISPLAY_WIDTH  = 8'h48;
localparam REG_DISPLAY_HEIGHT = 8'h4c;

localparam STATUS_JOB_DONE    =  8;                   /* Status bit positions */
localparam STATUS_QUEUED      =  9;
localparam STATUS_JOB_IE      = 10;
localparam STATUS_QUEUE_IE    = 11;
localparam STATUS_BASE_BIT    = 12;
localparam STATUS_RESET_BIT   = 13;

reg [7:0]   addr;

/* Registers */
reg  [31:0] arguments [7:0];
reg  [31:0] command;
reg  [17:0] drawing_base;
logic       job_queue_interrupt_enable;
logic       job_complete_interrupt_enable;
logic       job_queued;
logic       job_queue_interrupt;
logic       job_complete_interrupt;                        /* Also status bit */
logic       drawing_base_ctrl;

logic       writing;                         /* The unit is being written to. */
logic       clr_status;              /* Pulses high if clearing status bit(s) */
logic       set_status;              /* Pulses high if setting  status bit(s) */
logic       reset_drawing_units;
logic       clr_done;                         /* Processor set/clear requests */
logic       set_done;

reg command_requested;       /* Latches the input stimulus; one cycle latency */

logic [31:0] status;  /* Status register assembly: see bit definitions above. */

assign stall_o   = 1'b0;
assign abort_v_o = 3'b000;

always_comb
begin : drawing_video_bus_out
display_base_o   = drawing_base_ctrl ? drawing_base : v_base_i;
display_mode_o   = v_mode_i;
display_width_o  = v_width_i;
display_height_o = v_height_i;
end

always_comb                                     /* Interrupts and their masks */
ireq_o = {job_queue_interrupt    && job_queue_interrupt_enable,
          job_complete_interrupt && job_complete_interrupt_enable};
    

always_comb drawing_unit_reset_o = reset_i || reset_drawing_units;

always_comb
  begin : drawing_bus_out
  status = {18'h0,                                              /* Spare bits */
             1'b0,                                      /* (Former) reset Bit */
            drawing_base_ctrl,
            job_queue_interrupt_enable,
            job_complete_interrupt_enable,
            job_queued,
            job_complete_interrupt,
            busy_i[7:0]};

  command_o   = command;
  arguments_o = arguments;
  req_o       = command_requested;
  end

always_comb writing = cs_i && write_i;    /* For convenience in source, below */

always_ff @( posedge clk )
begin : reg_latching
if (reset_i)
  begin : clear_registers
  arguments[3'd0] <= 0;
  arguments[3'd1] <= 0;
  arguments[3'd2] <= 0;
  arguments[3'd3] <= 0;
  arguments[3'd4] <= 0;
  arguments[3'd5] <= 0;
  arguments[3'd6] <= 0;
  arguments[3'd7] <= 0;
  drawing_base    <= 0;
  drawing_base_ctrl <= 0;

  // Clear interrupt and masks on reset
  job_queue_interrupt_enable    <= 1'b0;
  job_complete_interrupt_enable <= 1'b0;
  end
else
  begin

  if (writing)                                 /* Writes to control registers */
    case(address_i[7:0])
      REG_ARGUMENTS + 8'h00 : arguments[3'd0] <= data_in;
      REG_ARGUMENTS + 8'h04 : arguments[3'd1] <= data_in;
      REG_ARGUMENTS + 8'h08 : arguments[3'd2] <= data_in;
      REG_ARGUMENTS + 8'h0C : arguments[3'd3] <= data_in;
      REG_ARGUMENTS + 8'h10 : arguments[3'd4] <= data_in;
      REG_ARGUMENTS + 8'h14 : arguments[3'd5] <= data_in;
      REG_ARGUMENTS + 8'h18 : arguments[3'd6] <= data_in;
      REG_ARGUMENTS + 8'h1C : arguments[3'd7] <= data_in;
      REG_DISPLAY_BASE : drawing_base <= data_in[19:2];
      REG_STATUS_CLR : begin
            if (data_in[STATUS_JOB_IE])   job_complete_interrupt_enable <= 0;
            if (data_in[STATUS_QUEUE_IE]) job_queue_interrupt_enable    <= 0;
            if (data_in[STATUS_BASE_BIT]) drawing_base_ctrl             <= 0;
                end
      REG_STATUS_SET : begin
            if (data_in[STATUS_JOB_IE])   job_complete_interrupt_enable <= 1;
            if (data_in[STATUS_QUEUE_IE]) job_queue_interrupt_enable    <= 1;
            if (data_in[STATUS_BASE_BIT]) drawing_base_ctrl             <= 1;
                end
    endcase
  end
end

always_ff @( posedge clk )         /* Command input and (potential) buffering */
begin : command_reg
if (reset_i)
  begin
  command           <= 0;
  command_requested <= 0;
  end
else
  if (ack_i) command_requested <= 0;
  else
    begin
    if (writing)                               /* Writes to control registers */
      case (address_i[7:0])
        REG_COMMAND : begin                        /* Writing command sets up */
                      command           <= data_in;
                      command_requested <= 1;    /* Register command validity */
                      end
        REG_STATUS_CLR : if (data_in[STATUS_QUEUED]) command_requested <= 0;
      endcase                                /* Clear 'Q' to cancel input job */
  end
end

// Doesn't verify size of write; assumes 'word' (so behave!)
always_comb clr_status = writing && (address_i[7:0] == REG_STATUS_CLR);
always_comb set_status = writing && (address_i[7:0] == REG_STATUS_SET);

always_comb reset_drawing_units = set_status && data_in[STATUS_RESET_BIT];
always_comb clr_done  = clr_status && data_in[STATUS_JOB_DONE];
always_comb set_done  = set_status && data_in[STATUS_JOB_DONE];
  /* Although why anyone would want to set this bit in software is a mystery! */

always_ff @( posedge clk )
  if      (reset_i || clr_done) job_complete_interrupt <= 1'b0;
  else if (|done_i || set_done) job_complete_interrupt <= 1'b1;

always_comb job_queued = command_requested;    /* Adequate in absence of FIFO */

always_comb job_queue_interrupt = !job_queued;    /* Interrupt if empty queue */


// Anthony Fix 
always @ (posedge clk)                                    /* Address bit hold */
if (read_i) addr <= address_i[7:0];                   /* Delay for next cycle */

always_comb
begin : comb_data_bus_output 
  begin                                    /* Reading back from the registers */
  case(address_i[7:0])
    REG_ARGUMENTS + 8'h00 : data_out = arguments[3'd0];
    REG_ARGUMENTS + 8'h04 : data_out = arguments[3'd1];
    REG_ARGUMENTS + 8'h08 : data_out = arguments[3'd2];
    REG_ARGUMENTS + 8'h0C : data_out = arguments[3'd3];
    REG_ARGUMENTS + 8'h10 : data_out = arguments[3'd4];
    REG_ARGUMENTS + 8'h14 : data_out = arguments[3'd5];
    REG_ARGUMENTS + 8'h18 : data_out = arguments[3'd6];
    REG_ARGUMENTS + 8'h1C : data_out = arguments[3'd7];
    REG_COMMAND           : data_out = command;
    REG_STATUS            : data_out = status;
    REG_DRAWING_BASE      : data_out = {12'h000,  drawing_base, 2'h0};
    REG_DISPLAY_BASE      : data_out = {12'h000,      v_base_i, 2'h0};
    REG_DISPLAY_HEIGHT    : data_out = {22'h000000,   v_height_i};
    REG_DISPLAY_WIDTH     : data_out = {22'h000000,   v_width_i};
    REG_DISPLAY_MODE      : data_out = {30'h00000000, v_mode_i};
    default               : data_out = 32'hxxxx_xxxx;
  endcase
  end                             /* Default output */
end

endmodule

/******************************************************************************/
