`timescale 1ns / 1ps
`define GFP_DATA_WIDTH 256


module montgomery_add_core#(
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
    input wire [`GFP_DATA_WIDTH-1:0]        coeff_a_i,
    input wire [`GFP_DATA_WIDTH-1:0]        coeff_b_i,
    input wire                              pm_param_tvalid_i,
    //point multiplication(PM) results
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_thaty_o,
    output wire                             rslt_thaty_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_lambda_o,
    output wire                             rslt_lambda_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_sumx_o,
    output wire                             rslt_sumx_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_sumy_o,
    output wire                             rslt_sumy_tvalid_o,
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
    localparam SM_FINISH                = 49'd15;

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
    reg [`GFP_DATA_WIDTH-1:0]               r_delta_y;
    reg [`GFP_DATA_WIDTH-1:0]               r_delta_x;
    reg [`GFP_DATA_WIDTH-1:0]               r_lambda;
    reg [`GFP_DATA_WIDTH-1:0]               r_lambda2;
    reg [`GFP_DATA_WIDTH-1:0]               r_coeffb;
    reg [`GFP_DATA_WIDTH-1:0]               r_coeffa;
    reg [`GFP_DATA_WIDTH-1:0]               r_sumx;
    reg [`GFP_DATA_WIDTH-1:0]               r_sumy;
    reg [`GFP_DATA_WIDTH-1:0]               r1;
    reg [`GFP_DATA_WIDTH-1:0]               r2;
    reg [`GFP_DATA_WIDTH-1:0]               r3;
    reg [`GFP_DATA_WIDTH-1:0]               r4;
    reg [`GFP_DATA_WIDTH-1:0]               r5;
    reg [`GFP_DATA_WIDTH-1:0]               r6;


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

    reg                                     rslt_thaty_tvalid;
    reg                                     rslt_lambda_tvalid;
    reg                                     rslt_sumx_tvalid;
    reg                                     rslt_sumy_tvalid;
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
            SM_ST2   :                                nstate = SM_ST3   ;
            SM_ST3   : if(gf_inv_rslt_valid  == 1'b1) nstate = SM_ST4   ; else nstate = SM_ST3   ;
            SM_ST4   : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST5   ; else nstate = SM_ST4   ;
            SM_ST5   : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST6   ; else nstate = SM_ST5   ;
            SM_ST6   :                                nstate = SM_ST7   ;
            SM_ST7   :                                nstate = SM_ST8   ;
            SM_ST8   :                                nstate = SM_ST9   ;
            SM_ST9   :                                nstate = SM_ST10  ;
            SM_ST10  : if(gf_mul0_rslt_valid == 1'b1) nstate = SM_ST11  ; else nstate = SM_ST10  ;
            SM_ST11  :                                nstate = SM_ST12  ;
            SM_ST12  :                                nstate = SM_FINISH;
            SM_FINISH:                                nstate = SM_IDLE  ;
            default  :                                nstate = SM_IDLE  ;
        endcase
    end

    //state machine,internal logic part
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_thisx   <= 0; else if(pm_param_tvalid_i) r_thisx   <= this_xp_i; else r_thisx   <= r_thisx;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_thatx   <= 0; else if(pm_param_tvalid_i) r_thatx   <= that_xp_i; else r_thatx   <= r_thatx;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_thisy   <= 0; else if(pm_param_tvalid_i) r_thisy   <= this_yp_i; else r_thisy   <= r_thisy;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_thaty   <= 0; else if(pm_param_tvalid_i) r_thaty   <= that_yp_i; else r_thaty   <= r_thaty;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_coeffb  <= 0; else if(pm_param_tvalid_i) r_coeffb  <= coeff_b_i; else r_coeffb  <= r_coeffb;
always @(posedge pm_clk_i or negedge pm_rstn_i) if(~pm_rstn_i) r_coeffa  <= 0; else if(pm_param_tvalid_i) r_coeffa  <= coeff_a_i; else r_coeffa  <= r_coeffa;

always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_lambda   <= 0; SM_ST3 : r_lambda   <= gf_inv_rslt ; default: r_lambda   <= r_lambda  ; endcase

always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_lambda2  <= 0; SM_ST4 : r_lambda2  <= gf_mul0_rslt; default: r_lambda2  <= r_lambda2 ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r1         <= 0; SM_ST5 : r1         <= gf_mul0_rslt; default: r1         <= r1        ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r5         <= 0; SM_ST10: r5         <= gf_mul0_rslt; default: r5         <= r5        ; endcase

always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_delta_y  <= 0; SM_ST1 : r_delta_y  <= gf_as_rslt  ; default: r_delta_y  <= r_delta_y ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_delta_x  <= 0; SM_ST2 : r_delta_x  <= gf_as_rslt  ; default: r_delta_x  <= r_delta_x ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r2         <= 0; SM_ST6 : r2         <= gf_as_rslt  ; default: r2         <= r2        ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r3         <= 0; SM_ST7 : r3         <= gf_as_rslt  ; default: r3         <= r3        ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_sumx     <= 0; SM_ST8 : r_sumx     <= gf_as_rslt  ; default: r_sumx     <= r_sumx    ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r4         <= 0; SM_ST9 : r4         <= gf_as_rslt  ; default: r4         <= r4        ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r6         <= 0; SM_ST11: r6         <= gf_as_rslt  ; default: r6         <= r6        ; endcase
always @(posedge pm_clk_i) case(cstate) SM_IDLE: r_sumy     <= 0; SM_ST12: r_sumy     <= gf_as_rslt  ; default: r_sumy     <= r_sumy    ; endcase


//Field Multiplier
    //mul0
    always @ ( * )
    begin
        case(cstate)
            SM_IDLE     : begin gf_mul0_a = 0           ; gf_mul0_b = 0         ; end
            SM_ST4      : begin gf_mul0_a = r_lambda    ; gf_mul0_b = r_lambda  ; end
            SM_ST5      : begin gf_mul0_a = r_lambda2   ; gf_mul0_b = r_coeffb  ; end
            SM_ST10     : begin gf_mul0_a = r_lambda    ; gf_mul0_b = r4        ; end
            default     : begin gf_mul0_a = 0           ; gf_mul0_b = 0         ; end
        endcase
    end

    always @ (posedge pm_clk_i or negedge pm_rstn_i)
    begin
        if(!pm_rstn_i)
            gf_mul0_ab_valid <= 1'b0;
        else if(nstate != cstate)
            case(nstate)
                SM_ST4  : gf_mul0_ab_valid <= 1'b1;
                SM_ST5  : gf_mul0_ab_valid <= 1'b1;
                SM_ST10 : gf_mul0_ab_valid <= 1'b1;
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
            SM_ST1      : begin gf_as_a = r_thaty   ; gf_as_b = r_thisy     ; gf_as_mode_ctrl = 1'b0; end
            SM_ST2      : begin gf_as_a = r_thatx   ; gf_as_b = r_thisx     ; gf_as_mode_ctrl = 1'b0; end
            SM_ST6      : begin gf_as_a = r1        ; gf_as_b = r_coeffa    ; gf_as_mode_ctrl = 1'b0; end
            SM_ST7      : begin gf_as_a = r2        ; gf_as_b = r_thisx     ; gf_as_mode_ctrl = 1'b0; end
            SM_ST8      : begin gf_as_a = r3        ; gf_as_b = r_thatx     ; gf_as_mode_ctrl = 1'b0; end
            SM_ST9      : begin gf_as_a = r_sumx    ; gf_as_b = r_thisx     ; gf_as_mode_ctrl = 1'b0; end
            SM_ST11     : begin gf_as_a = r5        ; gf_as_b = r_thisy     ; gf_as_mode_ctrl = 1'b1; end
            SM_ST12     : begin gf_as_a = 0         ; gf_as_b = r6          ; gf_as_mode_ctrl = 1'b0; end
            default     : begin gf_as_a = 0         ; gf_as_b = 0           ; gf_as_mode_ctrl = 1'b0; end
        endcase
    end


//Field Inverter
    always @ ( * )
    begin
        case(cstate)
            SM_IDLE     : begin gf_inv_a = 0           ; gf_inv_b = 0         ; end
            SM_ST3      : begin gf_inv_a = r_delta_x   ; gf_inv_b = r_delta_y ; end
            default     : begin gf_inv_a = 0           ; gf_inv_b = 0         ; end
        endcase
    end

    always @ (posedge pm_clk_i or negedge pm_rstn_i)
    begin
        if(!pm_rstn_i)
            gf_inv_ab_valid <= 1'b0;
        else if(nstate != cstate)
            case(nstate)
                SM_ST3  : gf_inv_ab_valid <= 1'b1;
                default : gf_inv_ab_valid <= 1'b0;
            endcase
        else
            gf_inv_ab_valid <= 1'b0;
    end


//result
assign rslt_thaty_o      = r_thaty;
assign rslt_lambda_o     = r_lambda;
assign rslt_sumx_o       = r_sumx;
assign rslt_sumy_o       = r_sumy;

assign rslt_thaty_tvalid_o  = rslt_thaty_tvalid;
assign rslt_lambda_tvalid_o = rslt_lambda_tvalid;
assign rslt_sumx_tvalid_o   = rslt_sumx_tvalid;
assign rslt_sumy_tvalid_o   = rslt_sumy_tvalid;
assign rslt_all_tvalid_o    = rslt_all_tvalid;

always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_thaty_tvalid  <= 1'b0; else if(nstate >  SM_ST1 ) rslt_thaty_tvalid  <= 1'b1; else rslt_thaty_tvalid  <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_lambda_tvalid <= 1'b0; else if(nstate >  SM_ST3 ) rslt_lambda_tvalid <= 1'b1; else rslt_lambda_tvalid <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_sumx_tvalid   <= 1'b0; else if(nstate >  SM_ST8 ) rslt_sumx_tvalid   <= 1'b1; else rslt_sumx_tvalid   <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_sumy_tvalid   <= 1'b0; else if(nstate >  SM_ST12) rslt_sumy_tvalid   <= 1'b1; else rslt_sumy_tvalid   <= 1'b0;
always @ (posedge pm_clk_i or negedge pm_rstn_i) if(!pm_rstn_i) rslt_all_tvalid    <= 1'b0; else if(nstate >  SM_ST12) rslt_all_tvalid    <= 1'b1; else rslt_all_tvalid    <= 1'b0;

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
