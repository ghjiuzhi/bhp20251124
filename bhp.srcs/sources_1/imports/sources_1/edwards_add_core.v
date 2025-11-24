`timescale 1ns / 1ps
`define GFP_DATA_WIDTH 256


module edwards_add_core#(
    parameter P_MOD = {`GFP_DATA_WIDTH{1'b1}}
    )
    (
    //clock from MCMM or PLL
    input wire                              pm_clk_i,
    //asynchronous reset
    input wire                              pm_rstn_i,
    //domain parameters for an elliptic curve scheme 
    //the following input signals must be synchronous to the pm_clk_i
    input wire [`GFP_DATA_WIDTH-1:0]        this_xp_i,
    input wire [`GFP_DATA_WIDTH-1:0]        this_yp_i,
    input wire [`GFP_DATA_WIDTH-1:0]        that_xp_i,
    input wire [`GFP_DATA_WIDTH-1:0]        that_yp_i,
    input wire [`GFP_DATA_WIDTH-1:0]        tw_a_i,
    input wire [`GFP_DATA_WIDTH-1:0]        tw_d_i,
    input wire                              pm_param_tvalid_i,
    //point multiplication(PM) results
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_u_o,
    output wire                             rslt_u_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_v0_o,
    output wire                             rslt_v0_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_v1_o,
    output wire                             rslt_v1_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_h1_o,
    output wire                             rslt_h1_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_x3_o,
    output wire                             rslt_x3_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_y3_o,
    output wire                             rslt_y3_tvalid_o,
    output wire                             rslt_all_tvalid_o,
    //ready signal, asserted when PM is idle
    output reg                              pm_tready_o,
    //------Field Multiplier Interface------
    input wire [`GFP_DATA_WIDTH-1:0]        pm_mul0_rslt_i,
    input wire                              pm_mul0_rslt_valid_i,
    output wire [`GFP_DATA_WIDTH-1:0]       pm_mul0_a_o,
    output wire [`GFP_DATA_WIDTH-1:0]       pm_mul0_b_o,
    output wire                             pm_mul0_ab_valid_o,
    //------Field Adder-Subtractor Interface------
    input wire [`GFP_DATA_WIDTH-1:0]        pm_as_rslt_i,
    output wire [`GFP_DATA_WIDTH-1:0]       pm_as_a_o,
    output wire [`GFP_DATA_WIDTH-1:0]       pm_as_b_o,
    output wire                             pm_as_mode_ctrl_o,
    //------Field Inverter Interface------
    input wire [`GFP_DATA_WIDTH-1:0]        pm_inv_rslt_i,
    input wire                              pm_inv_rslt_valid_i,
    output wire [`GFP_DATA_WIDTH-1:0]       pm_inv_a_o,
    output wire [`GFP_DATA_WIDTH-1:0]       pm_inv_b_o,
    output wire                             pm_inv_ab_valid_o

    );


//-----------------------------------------------------------------------------------------------------
// Local Parameter
//-----------------------------------------------------------------------------------------------------
    localparam SM_IDLE                  = 49'd1;
    localparam SM_INIT_WAIT             = 49'd2;
    localparam SM_ST1                   = 49'd3;
    localparam SM_ST2                   = 49'd4;
    localparam SM_ST3                   = 49'd5;
    localparam SM_ST4                   = 49'd6;
    localparam SM_ST5                   = 49'd7;
    localparam SM_ST6                   = 49'd8;
    localparam SM_ST7                   = 49'd9;
    localparam SM_ST8                   = 49'd10;
    localparam SM_ST9                   = 49'd11;
    localparam SM_ST10                  = 49'd12;
    localparam SM_ST11                  = 49'd13;
    localparam SM_ST12                  = 49'd14;
    localparam SM_ST13                  = 49'd15;
    localparam SM_ST14                  = 49'd16;
    localparam SM_ST15                  = 49'd17;
    localparam SM_ST16                  = 49'd18;
    localparam SM_FINISH                = 49'd19;

//-----------------------------------------------------------------------------------------------------
// Signal Declaration
//-----------------------------------------------------------------------------------------------------
    //state machine
    reg [48:0]                              cstate;
    reg [48:0]                              nstate;

    reg [`GFP_DATA_WIDTH-1:0]               r_thisx;
    reg [`GFP_DATA_WIDTH-1:0]               r_thatx;
    reg [`GFP_DATA_WIDTH-1:0]               r_thisy;
    reg [`GFP_DATA_WIDTH-1:0]               r_thaty;
    reg [`GFP_DATA_WIDTH-1:0]               r_u;
    reg [`GFP_DATA_WIDTH-1:0]               r_v0;
    reg [`GFP_DATA_WIDTH-1:0]               r_v1;
    reg [`GFP_DATA_WIDTH-1:0]               r_h1;
    reg [`GFP_DATA_WIDTH-1:0]               r_x3;
    reg [`GFP_DATA_WIDTH-1:0]               r_y3;
    reg [`GFP_DATA_WIDTH-1:0]               r_tw_a;
    reg [`GFP_DATA_WIDTH-1:0]               r_tw_d;
    reg [`GFP_DATA_WIDTH-1:0]               r1;
    reg [`GFP_DATA_WIDTH-1:0]               r2;
    reg [`GFP_DATA_WIDTH-1:0]               r3;
    reg [`GFP_DATA_WIDTH-1:0]               r4;
    reg [`GFP_DATA_WIDTH-1:0]               r5;
    reg [`GFP_DATA_WIDTH-1:0]               r6;
    reg [`GFP_DATA_WIDTH-1:0]               r7;
    reg [`GFP_DATA_WIDTH-1:0]               r8;
    reg [`GFP_DATA_WIDTH-1:0]               r9;
    reg [`GFP_DATA_WIDTH-1:0]               r10;


    reg [`GFP_DATA_WIDTH-1:0]               gf_mul0_a;
    reg [`GFP_DATA_WIDTH-1:0]               gf_mul0_b;
    reg                                     gf_mul0_ab_valid;
    wire [`GFP_DATA_WIDTH-1:0]              gf_mul0_rslt;
    wire                                    gf_mul0_rslt_valid;

    reg [`GFP_DATA_WIDTH-1:0]               gf_as_a;
    reg [`GFP_DATA_WIDTH-1:0]               gf_as_b;
    reg                                     gf_as_mode_ctrl;
    wire [`GFP_DATA_WIDTH-1:0]              gf_as_rslt;

    reg [`GFP_DATA_WIDTH-1:0]               gf_inv_a;
    reg [`GFP_DATA_WIDTH-1:0]               gf_inv_b;
    reg                                     gf_inv_ab_valid;
    wire [`GFP_DATA_WIDTH-1:0]              gf_inv_rslt;
    wire [`GFP_DATA_WIDTH-1:0]              gf_inv_rslt_valid;

    reg                                     rslt_rslt_u_tvalid;
    reg                                     rslt_rslt_v0_tvalid;
    reg                                     rslt_rslt_v1_tvalid;
    reg                                     rslt_rslt_h1_tvalid;
    reg                                     rslt_rslt_x3_tvalid;
    reg                                     rslt_rslt_y3_tvalid;
    reg                                     rslt_all_tvalid;

//-----------------------------------------------------------------------------------------------------
// Control Logic
//-----------------------------------------------------------------------------------------------------
    //state machine, 1st always block, sequential state transition  
    always @ (posedge pm_clk_i or negedge pm_rstn_i)
    begin
        if (!pm_rstn_i)
        begin
            cstate <= SM_IDLE;
        end
        else
        begin
            cstate <= nstate;
        end
    end

    //state machine, 2nd always block, combinational state judgement    
    always @ ( * )
    begin
        nstate = SM_IDLE;
        case(cstate)
            SM_IDLE  : if (pm_param_tvalid_i == 1'b1) nstate = SM_INIT_WAIT; else nstate = SM_IDLE;
            SM_INIT_WAIT:
                //nstate = SM_DBLU_ST1;
                if (pm_param_tvalid_i == 1'b1)
                    nstate = SM_INIT_WAIT;
                else
                    nstate = SM_ST1;
            SM_ST1   :                                nstate = SM_ST2   ;
            SM_ST2   : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST3   ; else nstate = SM_ST2   ;
            SM_ST3   :                                nstate = SM_ST4   ;
            SM_ST4   : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST5   ; else nstate = SM_ST4   ;
            SM_ST5   : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST6   ; else nstate = SM_ST5   ;
            SM_ST6   : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST7   ; else nstate = SM_ST6   ;
            SM_ST7   : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST8   ; else nstate = SM_ST7   ;
            SM_ST8   : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST9   ; else nstate = SM_ST8   ;
            SM_ST9   :                                nstate = SM_ST10  ;
            SM_ST10  :                                nstate = SM_ST11  ;
            SM_ST11  : if(gf_inv_rslt_valid  == 1'b1) nstate = SM_ST12  ; else nstate = SM_ST11  ;
            SM_ST12  : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST13  ; else nstate = SM_ST12  ;
            SM_ST13  :                                nstate = SM_ST14  ;
            SM_ST14  :                                nstate = SM_ST15  ;
            SM_ST15  :                                nstate = SM_ST16  ;
            SM_ST16  : if(gf_inv_rslt_valid  == 1'b1) nstate = SM_FINISH; else nstate = SM_ST16  ;
            SM_FINISH:                                nstate = SM_IDLE  ;
            default  :                                nstate = SM_IDLE  ;
        endcase
    end

    //state machine,internal logic part
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_thisx <= 0; else if(pm_param_tvalid_i) r_thisx <= this_xp_i; else r_thisx <= r_thisx;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_thatx <= 0; else if(pm_param_tvalid_i) r_thatx <= that_xp_i; else r_thatx <= r_thatx;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_thisy <= 0; else if(pm_param_tvalid_i) r_thisy <= this_yp_i; else r_thisy <= r_thisy;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_thaty <= 0; else if(pm_param_tvalid_i) r_thaty <= that_yp_i; else r_thaty <= r_thaty;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_tw_a  <= 0; else if(pm_param_tvalid_i) r_tw_a  <= tw_a_i   ; else r_tw_a  <= r_tw_a ;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_tw_d  <= 0; else if(pm_param_tvalid_i) r_tw_d  <= tw_d_i   ; else r_tw_d  <= r_tw_d ;

always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_x3 <= 0; SM_ST11: r_x3 <= gf_inv_rslt ; default: r_x3 <= r_x3; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_y3 <= 0; SM_ST16: r_y3 <= gf_inv_rslt ; default: r_y3 <= r_y3; endcase

always @(posedge pm_clk_i) case(cstate) SM_IDLE: r2   <= 0; SM_ST2 : r2   <= gf_mul0_rslt; default: r2   <= r2   ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_u  <= 0; SM_ST4 : r_u  <= gf_mul0_rslt; default: r_u  <= r_u  ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_v0 <= 0; SM_ST5 : r_v0 <= gf_mul0_rslt; default: r_v0 <= r_v0 ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_v1 <= 0; SM_ST6 : r_v1 <= gf_mul0_rslt; default: r_v1 <= r_v1 ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_h1 <= 0; SM_ST7 : r_h1 <= gf_mul0_rslt; default: r_h1 <= r_h1 ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r4   <= 0; SM_ST8 : r4   <= gf_mul0_rslt; default: r4   <= r4   ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r7   <= 0; SM_ST12: r7   <= gf_mul0_rslt; default: r7   <= r7   ; endcase

always @(posedge pm_clk_i) case(cstate) SM_IDLE: r1   <= 0; SM_ST1 : r1   <= gf_as_rslt  ; default: r1   <= r1   ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r3   <= 0; SM_ST3 : r3   <= gf_as_rslt  ; default: r3   <= r3   ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r5   <= 0; SM_ST9 : r5   <= gf_as_rslt  ; default: r5   <= r5   ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r6   <= 0; SM_ST10: r6   <= gf_as_rslt  ; default: r6   <= r6   ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r8   <= 0; SM_ST13: r8   <= gf_as_rslt  ; default: r8   <= r8   ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r9   <= 0; SM_ST14: r9   <= gf_as_rslt  ; default: r9   <= r9   ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r10  <= 0; SM_ST15: r10  <= gf_as_rslt  ; default: r10  <= r10  ; endcase


//Field Multiplier
    //mul0
    always @ ( * )
    begin
        case(cstate)
            SM_IDLE     : begin gf_mul0_a = 0           ; gf_mul0_b = 0                 ; end
            SM_ST2      : begin gf_mul0_a = r_tw_a      ; gf_mul0_b = r_thisx           ; end
            SM_ST4      : begin gf_mul0_a = r1          ; gf_mul0_b = r3                ; end
            SM_ST5      : begin gf_mul0_a = r_thatx     ; gf_mul0_b = r_thisy           ; end
            SM_ST6      : begin gf_mul0_a = r_thisx     ; gf_mul0_b = r_thaty           ; end
            SM_ST7      : begin gf_mul0_a = r_v0        ; gf_mul0_b = r_v1              ; end
            SM_ST8      : begin gf_mul0_a = r_h1        ; gf_mul0_b = r_tw_d            ; end
            SM_ST12     : begin gf_mul0_a = r_tw_a      ; gf_mul0_b = r_v0              ; end
            default     : begin gf_mul0_a = 0           ; gf_mul0_b = 0                 ; end
        endcase
    end

    always @ (posedge pm_clk_i or negedge pm_rstn_i)
    begin
        if(!pm_rstn_i)
            gf_mul0_ab_valid <= 1'b0;
        else if(nstate != cstate)
            case(nstate)
                SM_ST2  : gf_mul0_ab_valid <= 1'b1;
                SM_ST4  : gf_mul0_ab_valid <= 1'b1;
                SM_ST5  : gf_mul0_ab_valid <= 1'b1;
                SM_ST6  : gf_mul0_ab_valid <= 1'b1;
                SM_ST7  : gf_mul0_ab_valid <= 1'b1;
                SM_ST8  : gf_mul0_ab_valid <= 1'b1;
                SM_ST12 : gf_mul0_ab_valid <= 1'b1;
                default : gf_mul0_ab_valid <= 1'b0;
            endcase
        else
            gf_mul0_ab_valid <= 1'b0;
    end


//Field Adder-Subtractor
    always @ ( * )
    begin
        case(cstate)
            SM_IDLE     : begin gf_as_a = 0         ; gf_as_b = 0           ; gf_as_mode_ctrl = 1'b0; end
            SM_ST1      : begin gf_as_a = r_thatx   ; gf_as_b = r_thaty     ; gf_as_mode_ctrl = 1'b1; end
            SM_ST3      : begin gf_as_a = r_thisy   ; gf_as_b = r2          ; gf_as_mode_ctrl = 1'b0; end
            SM_ST9      : begin gf_as_a = r_v0      ; gf_as_b = r_v1        ; gf_as_mode_ctrl = 1'b1; end
            SM_ST10     : begin gf_as_a = r4        ; gf_as_b = 1           ; gf_as_mode_ctrl = 1'b1; end
            SM_ST13     : begin gf_as_a = r7        ; gf_as_b = r_u         ; gf_as_mode_ctrl = 1'b1; end
            SM_ST14     : begin gf_as_a = r8        ; gf_as_b = r_v1        ; gf_as_mode_ctrl = 1'b0; end
            SM_ST15     : begin gf_as_a = 1         ; gf_as_b = r4          ; gf_as_mode_ctrl = 1'b0; end
            default     : begin gf_as_a = 0         ; gf_as_b = 0           ; gf_as_mode_ctrl = 1'b0; end
        endcase
    end

//Field Inverter
    always @ ( * )
    begin
        case(cstate)
            SM_IDLE     : begin gf_inv_a = 0           ; gf_inv_b = 0         ; end
            SM_ST11     : begin gf_inv_a = r6          ; gf_inv_b = r5        ; end// b*(a逆) mod p
            SM_ST16     : begin gf_inv_a = r10         ; gf_inv_b = r9        ; end// b*(a逆) mod p
            default     : begin gf_inv_a = 0           ; gf_inv_b = 0         ; end
        endcase
    end

    always @ (posedge pm_clk_i or negedge pm_rstn_i)
    begin
        if(!pm_rstn_i)
            gf_inv_ab_valid <= 1'b0;
        else if(nstate != cstate)
            case(nstate)
                SM_ST11 : gf_inv_ab_valid <= 1'b1;
                SM_ST16 : gf_inv_ab_valid <= 1'b1;
                default : gf_inv_ab_valid <= 1'b0;
            endcase
        else
            gf_inv_ab_valid <= 1'b0;
    end

//result
assign rslt_u_o      = r_u   ;
assign rslt_v0_o     = r_v0  ;
assign rslt_v1_o     = r_v1  ;
assign rslt_h1_o     = r_h1  ;
assign rslt_x3_o     = r_x3  ;
assign rslt_y3_o     = r_y3  ;

assign rslt_u_tvalid_o      = rslt_rslt_u_tvalid ;
assign rslt_v0_tvalid_o     = rslt_rslt_v0_tvalid;
assign rslt_v1_tvalid_o     = rslt_rslt_v1_tvalid;
assign rslt_h1_tvalid_o     = rslt_rslt_h1_tvalid;
assign rslt_x3_tvalid_o     = rslt_rslt_x3_tvalid;
assign rslt_y3_tvalid_o     = rslt_rslt_y3_tvalid;
assign rslt_all_tvalid_o    = rslt_all_tvalid    ;

always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_rslt_u_tvalid  <= 1'b0; else if(nstate >  SM_ST4 ) rslt_rslt_u_tvalid  <= 1'b1; else rslt_rslt_u_tvalid  <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_rslt_v0_tvalid <= 1'b0; else if(nstate >  SM_ST5 ) rslt_rslt_v0_tvalid <= 1'b1; else rslt_rslt_v0_tvalid <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_rslt_v1_tvalid <= 1'b0; else if(nstate >  SM_ST6 ) rslt_rslt_v1_tvalid <= 1'b1; else rslt_rslt_v1_tvalid <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_rslt_h1_tvalid <= 1'b0; else if(nstate >  SM_ST7 ) rslt_rslt_h1_tvalid <= 1'b1; else rslt_rslt_h1_tvalid <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_rslt_x3_tvalid <= 1'b0; else if(nstate >  SM_ST11) rslt_rslt_x3_tvalid <= 1'b1; else rslt_rslt_x3_tvalid <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_rslt_y3_tvalid <= 1'b0; else if(nstate >  SM_ST16) rslt_rslt_y3_tvalid <= 1'b1; else rslt_rslt_y3_tvalid <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_all_tvalid     <= 1'b0; else if(nstate >  SM_ST16) rslt_all_tvalid     <= 1'b1; else rslt_all_tvalid     <= 1'b0;

//ready signal generated
    always @ (posedge pm_clk_i or negedge pm_rstn_i)
    begin
        if(!pm_rstn_i)
        begin
            pm_tready_o <= 1'b0;
        end
        else
        begin
            if(nstate == SM_IDLE) 
            begin
                pm_tready_o <= 1'b1;
            end
            else 
            begin
                pm_tready_o <= 1'b0;
            end
        end
    end

//intermediate connection
    //mul
    assign pm_mul0_a_o = gf_mul0_a;
    assign pm_mul0_b_o = gf_mul0_b;
    assign pm_mul0_ab_valid_o = gf_mul0_ab_valid;
    assign gf_mul0_rslt = pm_mul0_rslt_i;
    assign gf_mul0_rslt_valid = pm_mul0_rslt_valid_i;


    //as
    assign pm_as_a_o = gf_as_a;
    assign pm_as_b_o = gf_as_b;
    assign pm_as_mode_ctrl_o = gf_as_mode_ctrl;
    assign gf_as_rslt = pm_as_rslt_i;

    //inv
    assign pm_inv_a_o = gf_inv_a;
    assign pm_inv_b_o = gf_inv_b;
    assign pm_inv_ab_valid_o = gf_inv_ab_valid;
    assign gf_inv_rslt = pm_inv_rslt_i;
    assign gf_inv_rslt_valid = pm_inv_rslt_valid_i;

endmodule
