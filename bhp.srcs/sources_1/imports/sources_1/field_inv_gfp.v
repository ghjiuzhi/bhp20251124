
`timescale      1ns/1ns
`define GFP_DATA_WIDTH                  256


module field_inv_gfp#(
    parameter P_MOD = {`GFP_DATA_WIDTH{1'b1}}
    )
    (
    //clock from MCMM or PLL
    input wire                                  fi_clk_i,
    //asynchronous reset
    input wire                                  fi_rstn_i,

    //m bit multiplier operands
    input wire [`GFP_DATA_WIDTH-1:0]            fi_a_i,
    input wire [`GFP_DATA_WIDTH-1:0]            fi_b_i,
    input wire                                  fi_ab_valid_i,

    //result of Multiplier over GF(p)
    output reg [`GFP_DATA_WIDTH-1:0]            fi_rslt_o,
    output reg                                  fi_rslt_valid_o
    );



//----------------------------------------------------------------------------------------------------------------------
// Local Parameter
//----------------------------------------------------------------------------------------------------------------------
    //state machine
    localparam SM_IDLE = 4'b0001;
    localparam SM_INIT = 4'b0010;
    localparam SM_CALCU = 4'b0100;
    localparam SM_FINISH = 4'b1000;

//-----------------------------------------------------------------------------------------------------
// Signal Declaration
//-----------------------------------------------------------------------------------------------------
    reg [3:0]                               cstate;
    reg [3:0]                               nstate;

    wire [`GFP_DATA_WIDTH-1:0]              mod;

    reg [`GFP_DATA_WIDTH-1:0]               u;
    reg [`GFP_DATA_WIDTH-1:0]               v;

    wire [`GFP_DATA_WIDTH:0]                u_sub_v;
    wire [`GFP_DATA_WIDTH:0]                v_sub_u;

    reg [`GFP_DATA_WIDTH-1:0]               x;
    wire [`GFP_DATA_WIDTH-1:0]              x_int;
    wire [`GFP_DATA_WIDTH:0]                x_add_mod;
    wire [`GFP_DATA_WIDTH-1:0]              x_sub_y;

    reg [`GFP_DATA_WIDTH-1:0]               y;
    wire [`GFP_DATA_WIDTH-1:0]              y_int;
    wire [`GFP_DATA_WIDTH:0]                y_add_mod;
    wire [`GFP_DATA_WIDTH-1:0]              y_sub_x;


//-----------------------------------------------------------------------------------------------------
// User Logic
//-----------------------------------------------------------------------------------------------------
    assign mod = P_MOD;
    
    //state machine, 1st always block, sequential state transition  
    always @ (posedge fi_clk_i or negedge fi_rstn_i)
    begin
        if (!fi_rstn_i)
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
            SM_IDLE:
            begin
                if (fi_ab_valid_i == 1'b1)
                begin
                    nstate = SM_INIT;
                end
                else
                begin
                    nstate = SM_IDLE;
                end
            end         
            SM_INIT:
            begin
                nstate = SM_CALCU;
            end
            SM_CALCU:
            begin
                if((u == {{(`GFP_DATA_WIDTH-1){1'b0}},1'b1}) || (v == {{(`GFP_DATA_WIDTH-1){1'b0}},1'b1})) 
                begin
                    nstate = SM_FINISH; 
                end
                else 
                begin
                    nstate = SM_CALCU;      
                end 
            end
            SM_FINISH:
            begin
                nstate = SM_IDLE;
            end
            default:
            begin
                nstate = SM_IDLE;
            end
        endcase
    end

    //state machine,internal logic part
    //new u
    always @ (posedge fi_clk_i)
    begin
        case(nstate)
            SM_IDLE:
            begin
                u <= {`GFP_DATA_WIDTH{1'b0}};   
            end         
            SM_INIT:
            begin
                u <= fi_a_i;
            end
            SM_CALCU:
            begin
                if(u[0] == 1'b0) 
                begin
                    u <= u >> 1;
                end
                else 
                begin
                    if((u >= v) && (v[0] == 1'b1)) 
                    begin
                        u <= u_sub_v[`GFP_DATA_WIDTH-1:0];
                    end
                    else 
                    begin
                        u <= u;
                    end
                end         
            end
            SM_FINISH:
            begin
                u <= u;         
            end
            default:
            begin
                u <= u; 
            end
        endcase
    end

    //new v
    always @ (posedge fi_clk_i)
    begin
        case(nstate)
            SM_IDLE:
            begin
                v <= {`GFP_DATA_WIDTH{1'b0}};   
            end         
            SM_INIT:
            begin
                v <= mod;
            end
            SM_CALCU:
            begin
                if(v[0] == 1'b0) 
                begin
                    v <= v >> 1;
                end
                else 
                begin
                    if((u < v) && (u[0] == 1'b1)) 
                    begin
                        v <= v_sub_u[`GFP_DATA_WIDTH-1:0];
                    end
                    else 
                    begin
                        v <= v;
                    end
                end         
            end
            SM_FINISH:
            begin
                v <= v;     
            end
            default:
            begin
                v <= v;
            end
        endcase
    end


    //new x and new y
    assign x_int = (x[0] ? x_add_mod : {1'b0,x}) >> 1;
    assign y_int = (y[0] ? y_add_mod : {1'b0,y}) >> 1;

    //new x
    always @ (posedge fi_clk_i)
    begin
        case(nstate)
            SM_IDLE:
            begin
                x <= {`GFP_DATA_WIDTH{1'b0}};
            end
            SM_INIT:
            begin
                x <= fi_b_i;
            end
            SM_CALCU:
            begin
                if(u[0] == 1'b0)
                begin
                    x <= x_int[`GFP_DATA_WIDTH-1:0];    
                end
                else 
                begin
                    if((u >= v) && (v[0] == 1'b1)) 
                    begin
                        x <= x_sub_y;
                    end
                    else 
                    begin
                        x <= x;
                    end
                end
            end
            SM_FINISH:
            begin
                x <= x;         
            end
            default:
            begin
                x <= x; 
            end
        endcase
    end

    //new y
    always @ (posedge fi_clk_i)
    begin
        case(nstate)
            SM_IDLE:
            begin
                y <= {`GFP_DATA_WIDTH{1'b0}};       
            end         
            SM_INIT:
            begin
                y <= {`GFP_DATA_WIDTH{1'b0}};
            end
            SM_CALCU:
            begin
                if(v[0] == 1'b0) 
                begin   
                    y <= y_int[`GFP_DATA_WIDTH-1:0];
                end
                else 
                begin
                    if(((u < v)) && (u[0] == 1'b1)) 
                    begin
                        y <= y_sub_x;
                    end
                    else 
                    begin
                        y <= y;
                    end
                end             
            end
            SM_FINISH:
            begin
                y <= y;
            end
            default:
            begin
                y <= y;
            end
        endcase
    end

    //result
    always @ (posedge fi_clk_i or negedge fi_rstn_i)
    begin
        if(!fi_rstn_i) 
        begin
            fi_rslt_o <= {`GFP_DATA_WIDTH{1'b0}};
            fi_rslt_valid_o <= 1'b0;
        end
        else 
        begin
            case(nstate)
                SM_FINISH:
                begin
                    if(u == {{(`GFP_DATA_WIDTH-1){1'b0}},1'b1}) 
                    begin
                        fi_rslt_o <= x;
                    end
                    else 
                    begin
                        fi_rslt_o <= y; 
                    end
                    fi_rslt_valid_o <= 1'b1;
                end
                default:
                begin
                    fi_rslt_o <= {`GFP_DATA_WIDTH{1'b0}};
                    fi_rslt_valid_o <= 1'b0;
                end
            endcase
        end
    end

//-----------------------------------------------------------------------------------------------------
// Instantiate the normal Subtractor and Addder
//-----------------------------------------------------------------------------------------------------
    subtractor u0_subtractor(
        .sub_a_i                (u),
        .sub_b_i                (v),
        .sub_rslt_o             (u_sub_v)
    );

    subtractor u1_subtractor(
        .sub_a_i                (v),
        .sub_b_i                (u),
        .sub_rslt_o             (v_sub_u)
    );


    bhp_adder u0_adder(
        .add_a_i                (x),
        .add_b_i                (mod),
        .add_rslt_o             (x_add_mod)
    );

    bhp_adder u1_adder(
        .add_a_i                (y),
        .add_b_i                (mod),
        .add_rslt_o             (y_add_mod)
    );


//-----------------------------------------------------------------------------------------------------
// Instantiate the Full-Precision Field Adder-Subtractor for field addition and subtraction
//-----------------------------------------------------------------------------------------------------
    bhp_field_add_sub_gfp #(
        .P_MOD                  (P_MOD)
    )
    u0_field_add_sub_gfp(
        .fas_a_i                (x),
        .fas_b_i                (y),
        // .fas_mod_sel_i          (fi_mod_sel_i),
        .fas_mode_ctrl_i        (1'b0),
        .fas_rslt_o             (x_sub_y)
    );


    bhp_field_add_sub_gfp #(
        .P_MOD                  (P_MOD)
    )
    u1_field_add_sub_gfp(
        .fas_a_i                (y),
        .fas_b_i                (x),
        // .fas_mod_sel_i          (fi_mod_sel_i),
        .fas_mode_ctrl_i        (1'b0),
        .fas_rslt_o             (y_sub_x)
    );

endmodule
