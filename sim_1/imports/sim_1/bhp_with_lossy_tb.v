`timescale 1ns / 1ps
`define LVS_R_V





module bhp_with_lossy_tb;

    // Inputs
    reg clk;
    reg rstn;
    reg i_vld;
    reg [127:0] i_a;
    reg [127:0] zzt_data;
    reg [2:0] i_size;
    reg i_signed;

    reg i_lvs_rdy;
    reg i_res_rdy;

    // Outputs
    wire o_rdy;
    wire [4:0] cur_state;

    wire         o_lvs_vld  ;
    wire [255:0] o_lvs      ;
    wire         o_field_ena;
    wire         o_last     ;
    wire [  7:0] o_length   ;

    wire         o_res_vld   ;
    wire [127:0] o_res       ;
    wire [  2:0] o_size      ;
    wire         o_signed    ;

    reg  [255:0] cur_res;
    reg  [255:0] exp_rslt;
    reg  [255:0] zzt_out;
    reg  [255:0] out;

    wire [8  -1:0]unsign_res_8  ;assign unsign_res_8   = cur_res[8  -1:0];
    wire [16 -1:0]unsign_res_16 ;assign unsign_res_16  = cur_res[16 -1:0];
    wire [32 -1:0]unsign_res_32 ;assign unsign_res_32  = cur_res[32 -1:0];
    wire [64 -1:0]unsign_res_64 ;assign unsign_res_64  = cur_res[64 -1:0];
    wire [128-1:0]unsign_res_128;assign unsign_res_128 = cur_res[128-1:0];
    wire [8  -1:0]signed_res_8  ;assign signed_res_8   = cur_res[8  -1:0];
    wire [16 -1:0]signed_res_16 ;assign signed_res_16  = cur_res[16 -1:0];
    wire [32 -1:0]signed_res_32 ;assign signed_res_32  = cur_res[32 -1:0];
    wire [64 -1:0]signed_res_64 ;assign signed_res_64  = cur_res[64 -1:0];
    wire [128-1:0]signed_res_128;assign signed_res_128 = cur_res[128-1:0];

    localparam ST_IDLE    = 1;
    localparam ST_BHP     = 2;
    localparam ST_LOSSY   = 3;
    localparam ST_OUTPUT  = 4;
    localparam ST_RST     = 5;
    localparam ST_FINISH  = 6;

    localparam B8   = 3'b001;
    localparam B16  = 3'b010;
    localparam B32  = 3'b011;
    localparam B64  = 3'b100;
    localparam B128 = 3'b101;
    localparam I     = 1'b1;
    localparam U     = 1'b0;



    localparam PAD8___0 = 120'b0;
    localparam PAD16__0 = 112'b0;
    localparam PAD32__0 = 96'b0;
    localparam PAD64__0 = 64'b0;
    // localparam PAD128_0 = 3'b0;

      localparam integer WIDTH = 256;
      localparam integer DEPTH = 684;
      reg [WIDTH-1:0] xmem [0:DEPTH-1];// 存储数组：索引 0..683
      reg [WIDTH-1:0] ymem [0:DEPTH-1];// 存储数组：索引 0..683
      reg [8*256-1:0] XDATA_FILE;
      reg [8*256-1:0] YDATA_FILE;
      reg [32-1:0] ID;
      reg [32+WIDTH*8-1:0] FRAME;
      reg [WIDTH-1:0] FRAMEX1;
      reg [WIDTH-1:0] FRAMEX2;
      reg [WIDTH-1:0] FRAMEX3;
      reg [WIDTH-1:0] FRAMEX4;
      reg [WIDTH-1:0] FRAMEY1;
      reg [WIDTH-1:0] FRAMEY2;
      reg [WIDTH-1:0] FRAMEY3;
      reg [WIDTH-1:0] FRAMEY4;
      reg [31:0] frame_data_out;
      reg frame_valid_out;
      integer fd;
      integer i;
      integer FRAME_i;
      integer FRAME_i_start;
      integer frame_id;
      integer read_items;

    wire         top_request;
    reg [256 - 1:0]i_sp_x;
    reg [256 - 1:0]i_sp_y;
    reg [ 10 - 1:0]i_sp_i;

    wire [2 : 0]   data_count;
    reg  [3 : 0]   data_count_max;


    reg [32:0] lvs_test;
    integer fd_lvs;
    reg [1023:0] pathA, pathB;

    reg reverse;

    reg zzt_testcase_r;
    reg zzt_testcase_pause1_r;

    // Instantiate the Unit Under Test (UUT)
    bhp_with_lossy uut (
        .clk(clk),
        .rstn(rstn),

        .i_vld(i_vld),
        .o_rdy(o_rdy),
        .i_a(i_a),
        .i_size(i_size),
        .i_signed(i_signed),

        `ifdef LVS_R_V
        .i_lvs_rdy  (o_lvs_vld  ),    // indicate if downstream is ready
        `else
        .i_lvs_rdy  (i_lvs_rdy  ),    // indicate if downstream is ready
        `endif
        .o_lvs_vld  (o_lvs_vld  ),    // indicate if leaves is valid
        .o_lvs      (o_lvs      ),        // leaves
        .o_field_ena(o_field_ena),  // indicate if is a 253-bit field
        .o_last     (o_last     ),       // last leaf
        .o_length   (o_length   ),     // leaves num in o_lvs

        // .i_res_rdy  (i_res_rdy  ),
        .o_res_vld  (o_res_vld  ),
        .o_res      (o_res      ),
        .o_size     (o_size     ),
        .o_signed   (o_signed   ),

        // .i_sp_x     (i_sp_x     ),
        // .i_sp_y     (i_sp_y     ),
        // .i_sp_i     (i_sp_i     ),
        .top_request(top_request),//pluse
        .bc_din     (frame_data_out     ),
        .bc_in_valid(frame_valid_out    ),

        .cur_state  (cur_state  ),
        .ft_data_count(data_count)
    );
    // Clock generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    integer index;
    integer error;
    integer temp_ready;
    initial begin
        // Initialize Inputs
        clk <= 0;
        out <= 0;
        error <= 0;
        index <= 0;
        i_vld <= 0;
        i_a <= 0;
        fd_lvs <= 0;
        i_size <= 0;
        cur_res <= 0;
        zzt_out <= 0;
        reverse <= 0; // 1: 输入正序，不需要tb中反序 0: 输入逆序，需要tb中反序
        zzt_data <= 0;
        exp_rslt <= 0;
        i_signed <= 0;
        lvs_test <= 0;
        i_lvs_rdy <= 0;
        i_res_rdy <= 0;
        frame_lvs_cnt <= 0;
        zzt_testcase_r <= 0;
        data_count_max <= 0;
        zzt_testcase_cnt <= 0;
        frame_lvs_cnt_max <= 0;
        zzt_testcase_pause1_r <= 0;
        zzt_testcase_cnt___8_max <= 0;
        zzt_testcase_cnt__16_max <= 0;
        zzt_testcase_cnt__32_max <= 0;
        zzt_testcase_cnt__64_max <= 0;
        zzt_testcase_cnt_128_max <= 0;
        rstn <= 0;
        #100;// Wait 100 ns for global reset
        rstn <= 1;
        #10000;

    $display("Starting bhp_with_lossy etc testbench...");
        reverse  <=  1;
        lvs_test <=  0;
        // zzt_data <=  {PAD8___0,8'b11101000};
        zzt_data <=  {PAD8___0,8'h17};
        zzt_out  <=  256'h62;
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);







`ifdef LVS_R_V
    ;
`else
    $display("Starting bhp_with_lossy pause lvs testbench...");
        reverse  <=  0;
        temp_ready = 1000;
        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        // if (fd_lvs == 0) begin
        //     $display("Error: Failed to open file!");
        // end else begin
        //     $display("File opened successfully! File descriptor: %0d", fd_lvs);
        // end
        lvs_test <=  1;
        zzt_data <=  {PAD8___0,8'b01101000};
        zzt_out  <= -256'd119;
        #10;zzt_testcase_pause(B8,I,zzt_data,0,zzt_out,temp_ready);
        // $display("$fclose(fd_lvs);...");
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs_right.txt";
        check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B16_U_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  2;
        zzt_data <=  {PAD16__0,16'b1110110100111010};
        zzt_out  <=  256'd55547;
        #10;zzt_testcase_pause(B16,U,zzt_data,0,zzt_out,temp_ready);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B16_U_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B16_U_lvs_right.txt";
        check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B32_U_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  3;
        zzt_data <=  {PAD32__0,32'b11101101001110101101101010100000};
        zzt_out  <=  256'd464081867;
        #10;zzt_testcase_pause(B32,U,zzt_data,0,zzt_out,temp_ready);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B32_U_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B32_U_lvs_right.txt";
        check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B64_I_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  4;
        zzt_data <=  {PAD64__0,64'b1000011110001101111000001111110000001101011110111011111110100110};
        zzt_out  <= -256'd3757354933473194135;
        #10;zzt_testcase_pause(B64,I,zzt_data,0,zzt_out,temp_ready);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B64_I_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B64_I_lvs_right.txt";
        check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B128_U_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  5;
        zzt_data <=  {128'b00001001101100010100111001110011010110010101000110010011000011010101011111011010000011100100111100110100100010101100000100001001};
        zzt_out  <=  256'd240735502027167243905959988592635201365;
        #10;zzt_testcase_pause(B128,U,zzt_data,0,zzt_out,temp_ready);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B128_U_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B128_U_lvs_right.txt";
        check_file_diff(pathA, pathB);
        lvs_test <= 0;
`endif


    $display("Starting bhp_with_lossy all lvs testbench...");
        reverse  <=  0;
        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  0;
        zzt_data <=  {PAD8___0,8'b01101000};
        zzt_out  <= -256'd119;
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs_right.txt";
        // check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  1;
        zzt_data <=  {PAD8___0,8'b01101000};
        zzt_out  <= -256'd119;
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B8_I_lvs_right.txt";
        check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B16_U_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  2;
        zzt_data <=  {PAD16__0,16'b1110110100111010};
        zzt_out  <=  256'd55547;
        #10;zzt_testcase(B16,U,zzt_data,0,zzt_out);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B16_U_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B16_U_lvs_right.txt";
        check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B32_U_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  3;
        zzt_data <=  {PAD32__0,32'b11101101001110101101101010100000};
        zzt_out  <=  256'd464081867;
        #10;zzt_testcase(B32,U,zzt_data,0,zzt_out);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B32_U_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B32_U_lvs_right.txt";
        check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B64_I_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  4;
        zzt_data <=  {PAD64__0,64'b1000011110001101111000001111110000001101011110111011111110100110};
        zzt_out  <= -256'd3757354933473194135;
        #10;zzt_testcase(B64,I,zzt_data,0,zzt_out);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B64_I_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B64_I_lvs_right.txt";
        check_file_diff(pathA, pathB);

        fd_lvs = $fopen("E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B128_U_lvs.txt", "w"); // "w" 覆盖写；用 "a" 追加写
        lvs_test <=  5;
        zzt_data <=  {128'b00001001101100010100111001110011010110010101000110010011000011010101011111011010000011100100111100110100100010101100000100001001};
        zzt_out  <=  256'd240735502027167243905959988592635201365;
        #10;zzt_testcase(B128,U,zzt_data,0,zzt_out);
        $fclose(fd_lvs);
        pathA = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B128_U_lvs.txt";
        pathB = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\B128_U_lvs_right.txt";
        check_file_diff(pathA, pathB);
        lvs_test <= 0;

    $display("Starting bhp_with_lossy rust testbench...");
        reverse  <=  0;
        zzt_data <=  {PAD8___0,8'b01101000};
        zzt_out  <= -256'd119;
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);
        #10;zzt_testcase(B8,I,zzt_data,1,zzt_out);
        #10;zzt_testcase(B8,I,zzt_data,2,zzt_out);
        #10;zzt_testcase(B8,I,zzt_data,10,zzt_out);

        zzt_data <=  {PAD16__0,16'b1110110100111010};
        zzt_out  <=  256'd55547;
        #10;zzt_testcase(B16,U,zzt_data,0,zzt_out);
        zzt_data <=  {PAD32__0,32'b11101101001110101101101010100000};
        zzt_out  <=  256'd464081867;
        #10;zzt_testcase(B32,U,zzt_data,0,zzt_out);
        zzt_data <=  {PAD64__0,64'b1000011110001101111000001111110000001101011110111011111110100110};
        zzt_out  <= -256'd3757354933473194135;
        #10;zzt_testcase(B64,I,zzt_data,0,zzt_out);
        zzt_data <=  {128'b00001001101100010100111001110011010110010101000110010011000011010101011111011010000011100100111100110100100010101100000100001001};
        zzt_out  <=  256'd240735502027167243905959988592635201365;
        #10;zzt_testcase(B128,U,zzt_data,0,zzt_out);

    $display("Starting bhp_with_lossy res testbench...");
        reverse  <=  0;
        zzt_data <=  {PAD8___0,8'b10000001};
        zzt_out  <= -256'd108;
        #10;zzt_testcase(B8,I,zzt_data,0,zzt_out);// r35 = -127i8
        zzt_data <=  {PAD8___0,8'b01101010};
        zzt_out  <=  256'd124;
        #10;zzt_testcase(B8,U,zzt_data,0,zzt_out);// r73 = 86u8
        zzt_data <=  {PAD16__0,16'b0101001011100001};
        zzt_out  <= -256'd5436;
        #10;zzt_testcase(B16,I,zzt_data,0,zzt_out);// r36 = -30902i16
        zzt_data <=  {PAD16__0,16'b1100000000111001};
        zzt_out  <=  256'd65180;
        #10;zzt_testcase(B16,U,zzt_data,0,zzt_out);// r23 = 39939u16
        zzt_data <=  {PAD32__0,32'b11101101110111011101101111110100};
        zzt_out  <=  256'd44175768;
        #10;zzt_testcase(B32,U,zzt_data,0,zzt_out);// r25 = 802929591u32
        zzt_data <=  {PAD32__0,32'b01001111110100101000110111000011};
        zzt_out  <=  256'd1204778383;
        #10;zzt_testcase(B32,I,zzt_data,0,zzt_out);// r37 = -1011790862i32
        zzt_data <=  {PAD32__0,32'b01101010110100111001001101110110};
        zzt_out  <=  256'd4190545906;
        #10;zzt_testcase(B32,U,zzt_data,0,zzt_out);// r62 = 1858718550u32
        zzt_data <=  {PAD64__0,64'b0111100001110110110100011101011100101111101110011110101110000001};
        zzt_out  <= -256'd4141294807192883151;
        #10;zzt_testcase(B64,I,zzt_data,0,zzt_out);// r38 = -9090623647574692322i64
        zzt_data <=  {128'b10100001111001111111110000111011011100111100001101000111101100111100011000001001110001100000101100101101001101010010001000101011};
        zzt_out  <= -256'd90688762945525946560039629278205026328;
        #10;zzt_testcase(B128,I,zzt_data,0,zzt_out);// r43 = -58129452728141601913315296611871496315i128
        zzt_data <=  {128'b10101010111000110110101110111111011011111100010110000110101110101011100001101011001100010010001100000101000111111101100010101101};
        zzt_out  <=  256'd61796151080661114844789465080232536318;
        #10;zzt_testcase(B128,U,zzt_data,0,zzt_out);// r43 = 240735502027167243905959988592635201365u128
        zzt_data <=  {128'b11111001100100010111001110111100110100110101111101101111101011011000110101101101100111001110110000100000000000000001000100100110};
        zzt_out  <=  256'd21937996922040675612839171161438846618;
        #10;zzt_testcase(B128,I,zzt_data,0,zzt_out);// r43 = 133628952285256420965695742983782959519i128
        zzt_data <=  {128'b01001101101011111011111101111110011110000110101111101001100000111111001101101111001110100000000001111011110000101111011101011011};
        zzt_out  <= -256'd17769464564413354883854205372395042579;
        #10;zzt_testcase(B128,I,zzt_data,0,zzt_out);// r59 = -49268328380429069828539320563432294990i128

    $display("Starting bhp_with_lossy bhp res testbench...");
        reverse  <=  0;
        zzt_data <=  {PAD64__0,64'b0111000111100100001001100110111111101111010001101101101100110110};
        zzt_out  <=  256'd13939859218897041345;
        #10;zzt_testcase(B64,U,zzt_data,0,zzt_out);// r100 = 7843971993126053774u64
        // without lossy exp_rslt <= 256'd5914309815371756391930615066479578717744312390660347880758017036720578492353;
        // without lossy #10;if(cur_res == exp_rslt) $display("Test case %03d dui", index - 1); else $display("Test case %03d cuo", index - 1);
        zzt_data <=  {PAD64__0,64'b0101010110111010111010010010011111001100110000010010001001010110};
        zzt_out  <=  256'd15797984249017069009;
        #10;zzt_testcase(B64,U,zzt_data,0,zzt_out);// r100 = 7657389525338381738u64
        // without lossy exp_rslt <= 256'd18425323531885336325674946456547389643693526238098411518623172538258222545;
        // without lossy #10;if(cur_res == exp_rslt) $display("Test case %03d dui", index - 1); else $display("Test case %03d cuo", index - 1);
        zzt_data <=  {PAD64__0,64'b0101011100110000010011010000011001000001100111000100011011111000};
        zzt_out  <=  256'd2124715295645252764;
        #10;zzt_testcase(B64,U,zzt_data,0,zzt_out);// r100 = 2261433195024223466u64
        // without lossy exp_rslt <= 256'd2695652556226353077407541515338418700604309234267402846477146244993532705948;
        // without lossy #10;if(cur_res == exp_rslt) $display("Test case %03d dui", index - 1); else $display("Test case %03d cuo", index - 1);
        zzt_data <=  {PAD64__0,64'b0000001011101010111110101001100011101010100110110001110100100001};
        zzt_out  <=  256'd9611865768901920898;
        #10;zzt_testcase(B64,U,zzt_data,0,zzt_out);// r100 = 9563632776832309056u64
        // without lossy exp_rslt <= 256'd6801306421848326749099757148404427533425921078146406253858347907806430152834;
        // without lossy #10;if(cur_res == exp_rslt) $display("Test case %03d dui", index - 1); else $display("Test case %03d cuo", index - 1);

    $display("Starting bhp_with_lossy bhp lots res testbench...");
        reverse  <=  0;
        zzt_data <=  {PAD64__0,64'b0000001011101010111110101001100011101010100110110001110100100001};
        zzt_out  <=  256'd9611865768901920898;
        #10;zzt_testcase(B64,U,zzt_data,0,zzt_out);// r100 = 9563632776832309056u64

    $display("Starting bhp_with_lossy bhp lots res testbench...");
        // Executing instruction (hash.bhp256 r21 into r47 as u8;)
        reverse  <=  1;
        zzt_data <=  8'd76;
        zzt_out  <=  8'd175;
        #10;zzt_testcase(B8,U,zzt_data,0,zzt_out);

    $display("Starting bhp_with_lossy bhp lots res testbench: index:%04d,error:%04d.",index,error);
        wait(o_rdy);
        #200;
        // $display("frame_lvs_cnt_max  : %7d",frame_lvs_cnt_max);
        $display("fifo: data_count_max: %7d",data_count_max);
        $display("IU8   :%08d",zzt_testcase_cnt___8_max);
        $display("IU16  :%08d",zzt_testcase_cnt__16_max);
        $display("IU32  :%08d",zzt_testcase_cnt__32_max);
        $display("IU64  :%08d",zzt_testcase_cnt__64_max);
        $display("IU128 :%08d",zzt_testcase_cnt_128_max);
        $finish;
    end


  initial begin
    // from start
    // i_sp_x = 256'd0;
    // i_sp_y = 256'd0;
    // i_sp_i =  10'd0;

    // interrupt calculate
    // i_sp_x = 256'd4405413365422220568237000915304400287543352561343753572223565637763382054477 ;
    // i_sp_y = 256'd2204662042624091946242497476583881364078081899192253257555670568450074315326 ;
    // i_sp_i =  10'd1                                                                            ;// from 1
    // i_sp_x = 256'd1761186298900649843069322778584613435914314043114650989642420662779088182365 ;
    // i_sp_y = 256'd6813375450167789555309386881032656901070874846219967010753553330292003989495 ;
    // i_sp_i =  10'd2                                                                            ;
    // i_sp_x = 256'd2712295457159051386866215581842035684006238966120328869620376816021343262421 ;
    // i_sp_y = 256'd6403614833453274187828499087343091535479781208726980600230024591582018800836 ;
    // i_sp_i =  10'd3                                                                            ;
    // i_sp_x = 256'd7539827211807812640588073995985862694710181606199261327909835760242386212513 ;// /bhp_with_lossy_tb/uut/uut_bhp_256_top/u_bhp_256/u_montgomery_add_lookup/sum_x
    // i_sp_y = 256'd4785478201797595594823195618693701038564393637142573479503580808304613575375 ;// /bhp_with_lossy_tb/uut/uut_bhp_256_top/u_bhp_256/u_montgomery_add_lookup/sum_y
    // i_sp_i =  10'd56                                                                           ;// /bhp_with_lossy_tb/uut/uut_bhp_256_top/u_bhp_256/u_montgomery_add_lookup/MG_j 的最后一个时钟周期对应的值↑
    i_sp_x = 256'd7126799769708027016315449572891096098166498552937892718894893847957882327955;
    i_sp_y = 256'd3917582819500725305888864628750270963250772406962484286785793128550891813719;
    i_sp_i =  10'd57;
    // below cuo
    // i_sp_x = 256'd2247072807337601653543811618730783261848051356052633950014627658601517764396;
    // i_sp_y = 256'd3348014061766390571163074312561919436418630525919981092018474803787889514670;
    // i_sp_i =  10'd58;
    // i_sp_x = 256'd755638432885475964074442434872566288590038231987479213049738002050849909859  ;
    // i_sp_y = 256'd5003478838945884235464731887834196301181106531947846961460406073321199736998 ;
    // i_sp_i =  10'd64                                                                           ;

    FRAME_i_start = i_sp_i;
    XDATA_FILE = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\X_171_x1x2x3x4.txt";
    YDATA_FILE = "E:\\project\\BHP256\\p6\\p6\\p6.srcs\\sim_1\\Y_171_x1x2x3x4.txt";
    // 调用加载任务
    load_xmem_from_decimal_txt;
    load_ymem_from_decimal_txt;
    xymem_showtest;
    // $display("i_sp_i = %0d", FRAME_i_start);
    // $display("i_sp_x = %0d", xmem[FRAME_i_start-1]);
    // $display("i_sp_i = %0d", ymem[FRAME_i_start-1]);
      // 初始化输出信号
      frame_data_out = 32'b0;
      frame_valid_out = 1'b0;
      ID    = 0;
      FRAME = 0;
      FRAMEX1 = 0;
      FRAMEX2 = 0;
      FRAMEX3 = 0;
      FRAMEX4 = 0;
      FRAMEY1 = 0;
      FRAMEY2 = 0;
      FRAMEY3 = 0;
      FRAMEY4 = 0;
      frame_id = 0;
      #100;
    // ID
    // x的1倍2倍3倍4倍: xmem[0],xmem[1],xmem[2],xmem[3]
    // y的1倍2倍3倍4倍: ymem[0],ymem[1],ymem[2],ymem[3]
    // FRAME = {32'd15,256'd1,256'd2,256'd3,256'd4,256'd5,256'd6,256'd7,256'd8};
    // FRAME = {32'h01,32'h02,32'h03,32'h04,32'h05,32'h06,32'h07,32'h08,32'h09,32'h0A,32'h0B,32'h0C,32'h0D,32'h0E,32'h0F,32'h10,32'h11,32'h12,32'h13,32'h14,32'h15,32'h16,32'h17,32'h18,32'h19,32'h1A,32'h1B,32'h1C,32'h1D,32'h1E,32'h1F,32'h20,32'h21,32'h22,32'h23,32'h24,32'h25,32'h26,32'h27,32'h28,32'h29,32'h2A,32'h2B,32'h2C,32'h2D,32'h2E,32'h2F,32'h30,32'h31,32'h32,32'h33,32'h34,32'h35,32'h36,32'h37,32'h38,32'h39,32'h3A,32'h3B,32'h3C,32'h3D,32'h3E,32'h3F,32'h40,32'h41};



    while (1) begin
        // RUN_ONCE: begin         // 命名块：被 o_res_vld 打断时可整体退出
        begin
            // START
            ID = {1'b1,21'b0,i_sp_i};
            FRAMEX1 = i_sp_x; FRAMEY1 = i_sp_y;
            FRAMEX2 = 0; FRAMEY2 = 0;
            FRAMEX3 = 0; FRAMEY3 = 0;
            FRAMEX4 = 0; FRAMEY4 = 0;
            FRAME = {ID,FRAMEX1,FRAMEY1,FRAMEX2,FRAMEY2,FRAMEX3,FRAMEY3,FRAMEX4,FRAMEY4};
            #100;
            @(posedge top_request);
            output_frame;
            // $display("output_frame_start",);
            // LOOP
            for (FRAME_i = FRAME_i_start; FRAME_i < 171; FRAME_i = FRAME_i + 1) begin
                // 等待 “发起请求” 或 “结果有效”
                @(posedge top_request or posedge o_res_vld);
                // 若在中途出现 o_res_vld 上升沿——立即重启整轮 for
                if (o_res_vld) begin
                    // 可选：打一拍，避免立刻再撞上同一个高电平
                    // @(negedge o_res_vld);
                    // disable RUN_ONCE;  // 退出命名块，while 会立刻开始新一轮
                    FRAME_i = 171;
                end
                // 正常执行这一帧
                frame_id = FRAME_i;
                ID = frame_id;
                FRAMEX1 = xmem[frame_id * 4 + 0]; FRAMEY1 = ymem[frame_id * 4 + 0];
                FRAMEX2 = xmem[frame_id * 4 + 1]; FRAMEY2 = ymem[frame_id * 4 + 1];
                FRAMEX3 = xmem[frame_id * 4 + 2]; FRAMEY3 = ymem[frame_id * 4 + 2];
                FRAMEX4 = xmem[frame_id * 4 + 3]; FRAMEY4 = ymem[frame_id * 4 + 3];
                FRAME = {ID,FRAMEX1,FRAMEY1,FRAMEX2,FRAMEY2,FRAMEX3,FRAMEY3,FRAMEX4,FRAMEY4};
                #100;
                output_frame;
            end
        end
        // 走到这里有两种情况：
        // 1) for 正常跑完；2) 被 o_res_vld 打断 disable RUN_ONCE。
        // 两种情况下都会立即回到 while 顶部，重新开始新一轮 RUN_ONCE。
    end
    #10 $finish;
  end


always @(posedge clk) begin
    if (i_lvs_rdy && o_lvs_vld) begin
      // %064h：固定宽度 64 个十六进制字符，前导 0 补齐，MSB 在左
      if(lvs_test != 0)
        $fdisplay(fd_lvs, "%064d", o_lvs);
    end
end


reg [255:0] frame_lvs_cnt;
reg [255:0] frame_lvs_cnt_1d;
reg [255:0] frame_lvs_cnt_max;
always @(posedge clk) begin
    if(i_lvs_rdy && o_lvs_vld)
        frame_lvs_cnt <= frame_lvs_cnt + 1;
        // $display("frame_lvs_cnt: %0d", frame_lvs_cnt + 1);
    else
        frame_lvs_cnt <= 0;
end
always @(posedge clk)
    frame_lvs_cnt_1d <= frame_lvs_cnt;
always @(posedge clk)
    if(frame_lvs_cnt > frame_lvs_cnt_max)
        frame_lvs_cnt_max <= frame_lvs_cnt;
always @(posedge clk)
    if(data_count > data_count_max)
        data_count_max <= data_count;
always @(posedge clk) begin
    // if (i_res_rdy && o_res_vld) begin// res 反压
    if (o_res_vld) begin// 没有反压
        cur_res <= o_res;
    end
end

reg [255:0] zzt_testcase_cnt;
always @(posedge clk) begin
    if (zzt_testcase_r) begin// 没有反压
        zzt_testcase_cnt <= zzt_testcase_cnt +1;
    end
end

reg [255:0] zzt_testcase_cnt_max;
reg [255:0] zzt_testcase_cnt___8_max;
reg [255:0] zzt_testcase_cnt__16_max;
reg [255:0] zzt_testcase_cnt__32_max;
reg [255:0] zzt_testcase_cnt__64_max;
reg [255:0] zzt_testcase_cnt_128_max;
always @(posedge clk) begin
    if (zzt_testcase_r) begin// 没有反压
        if(zzt_testcase_cnt_max <= zzt_testcase_cnt)
            zzt_testcase_cnt_max <= zzt_testcase_cnt;
    end
end







task  reverse_part;
    input [2:0]    task_size_in;
    input [127:0]  task_data_in;
    begin
        if      (task_size_in == B8  )  i_a <= { task_data_in[127:8],  {
                                                                task_data_in[0], task_data_in[1], task_data_in[2], task_data_in[3],
                                                                task_data_in[4], task_data_in[5], task_data_in[6], task_data_in[7] } };

        else if (task_size_in == B16 )  i_a <= { task_data_in[127:16], {
                                                                task_data_in[0],  task_data_in[1],  task_data_in[2],  task_data_in[3],
                                                                task_data_in[4],  task_data_in[5],  task_data_in[6],  task_data_in[7],
                                                                task_data_in[8],  task_data_in[9],  task_data_in[10], task_data_in[11],
                                                                task_data_in[12], task_data_in[13], task_data_in[14], task_data_in[15] } };

        else if (task_size_in == B32 )  i_a <= { task_data_in[127:32], {
                                                                task_data_in[0],  task_data_in[1],  task_data_in[2],  task_data_in[3],
                                                                task_data_in[4],  task_data_in[5],  task_data_in[6],  task_data_in[7],
                                                                task_data_in[8],  task_data_in[9],  task_data_in[10], task_data_in[11],
                                                                task_data_in[12], task_data_in[13], task_data_in[14], task_data_in[15],
                                                                task_data_in[16], task_data_in[17], task_data_in[18], task_data_in[19],
                                                                task_data_in[20], task_data_in[21], task_data_in[22], task_data_in[23],
                                                                task_data_in[24], task_data_in[25], task_data_in[26], task_data_in[27],
                                                                task_data_in[28], task_data_in[29], task_data_in[30], task_data_in[31] } };

        else if (task_size_in == B64 )  i_a <= { task_data_in[127:64], {
                                                                task_data_in[0],  task_data_in[1],  task_data_in[2],  task_data_in[3],
                                                                task_data_in[4],  task_data_in[5],  task_data_in[6],  task_data_in[7],
                                                                task_data_in[8],  task_data_in[9],  task_data_in[10], task_data_in[11],
                                                                task_data_in[12], task_data_in[13], task_data_in[14], task_data_in[15],
                                                                task_data_in[16], task_data_in[17], task_data_in[18], task_data_in[19],
                                                                task_data_in[20], task_data_in[21], task_data_in[22], task_data_in[23],
                                                                task_data_in[24], task_data_in[25], task_data_in[26], task_data_in[27],
                                                                task_data_in[28], task_data_in[29], task_data_in[30], task_data_in[31],
                                                                task_data_in[32], task_data_in[33], task_data_in[34], task_data_in[35],
                                                                task_data_in[36], task_data_in[37], task_data_in[38], task_data_in[39],
                                                                task_data_in[40], task_data_in[41], task_data_in[42], task_data_in[43],
                                                                task_data_in[44], task_data_in[45], task_data_in[46], task_data_in[47],
                                                                task_data_in[48], task_data_in[49], task_data_in[50], task_data_in[51],
                                                                task_data_in[52], task_data_in[53], task_data_in[54], task_data_in[55],
                                                                task_data_in[56], task_data_in[57], task_data_in[58], task_data_in[59],
                                                                task_data_in[60], task_data_in[61], task_data_in[62], task_data_in[63] } };

        else if (task_size_in == B128)  i_a <= {
                                                                task_data_in[0],   task_data_in[1],   task_data_in[2],   task_data_in[3],
                                                                task_data_in[4],   task_data_in[5],   task_data_in[6],   task_data_in[7],
                                                                task_data_in[8],   task_data_in[9],   task_data_in[10],  task_data_in[11],
                                                                task_data_in[12],  task_data_in[13],  task_data_in[14],  task_data_in[15],
                                                                task_data_in[16],  task_data_in[17],  task_data_in[18],  task_data_in[19],
                                                                task_data_in[20],  task_data_in[21],  task_data_in[22],  task_data_in[23],
                                                                task_data_in[24],  task_data_in[25],  task_data_in[26],  task_data_in[27],
                                                                task_data_in[28],  task_data_in[29],  task_data_in[30],  task_data_in[31],
                                                                task_data_in[32],  task_data_in[33],  task_data_in[34],  task_data_in[35],
                                                                task_data_in[36],  task_data_in[37],  task_data_in[38],  task_data_in[39],
                                                                task_data_in[40],  task_data_in[41],  task_data_in[42],  task_data_in[43],
                                                                task_data_in[44],  task_data_in[45],  task_data_in[46],  task_data_in[47],
                                                                task_data_in[48],  task_data_in[49],  task_data_in[50],  task_data_in[51],
                                                                task_data_in[52],  task_data_in[53],  task_data_in[54],  task_data_in[55],
                                                                task_data_in[56],  task_data_in[57],  task_data_in[58],  task_data_in[59],
                                                                task_data_in[60],  task_data_in[61],  task_data_in[62],  task_data_in[63],
                                                                task_data_in[64],  task_data_in[65],  task_data_in[66],  task_data_in[67],
                                                                task_data_in[68],  task_data_in[69],  task_data_in[70],  task_data_in[71],
                                                                task_data_in[72],  task_data_in[73],  task_data_in[74],  task_data_in[75],
                                                                task_data_in[76],  task_data_in[77],  task_data_in[78],  task_data_in[79],
                                                                task_data_in[80],  task_data_in[81],  task_data_in[82],  task_data_in[83],
                                                                task_data_in[84],  task_data_in[85],  task_data_in[86],  task_data_in[87],
                                                                task_data_in[88],  task_data_in[89],  task_data_in[90],  task_data_in[91],
                                                                task_data_in[92],  task_data_in[93],  task_data_in[94],  task_data_in[95],
                                                                task_data_in[96],  task_data_in[97],  task_data_in[98],  task_data_in[99],
                                                                task_data_in[100], task_data_in[101], task_data_in[102], task_data_in[103],
                                                                task_data_in[104], task_data_in[105], task_data_in[106], task_data_in[107],
                                                                task_data_in[108], task_data_in[109], task_data_in[110], task_data_in[111],
                                                                task_data_in[112], task_data_in[113], task_data_in[114], task_data_in[115],
                                                                task_data_in[116], task_data_in[117], task_data_in[118], task_data_in[119],
                                                                task_data_in[120], task_data_in[121], task_data_in[122], task_data_in[123],
                                                                task_data_in[124], task_data_in[125], task_data_in[126], task_data_in[127] };
        else  i_a <= task_data_in;
    end
endtask


task zzt_testcase_pause;
    input [2:0]    task_size_in;
    input          task_signed_in;
    input [127:0]  task_data_in;
    input integer  x;
    input [255:0]  task_out;
    input [255:0]  y;
    begin
        zzt_testcase_r <= 0;
        zzt_testcase_cnt <= 0;
        // $display("Test case %03d", index);
        wait (o_rdy);
        @(posedge clk);
        // i_signed = 1 => I 1:8;  2:16;  3:32;   4:64;   5:128
        // i_signed = 0 => U 6:8;  7:16;  8:32;   9:64;  10:128
        i_size   <= task_size_in;
        i_signed <= task_signed_in;
        if (reverse == 1) begin
            i_a   <= task_data_in;
            // $display("not reverse_part opreation");
        end else begin
            reverse_part(task_size_in,task_data_in);
            // $display("reverse_part opreation");
        end
        out      <= task_out;
        i_vld <= 1;#10;
        i_vld <= 0;
        i_lvs_rdy <= 0;
        // cur_res <= o_res;
        #200;
        // $display("begin : send_i_lvs_rdy_pause...");
        begin : send_i_lvs_rdy_pause
            forever begin
                wait(o_lvs_vld == 1);
                repeat (y) @(posedge clk);

                //
                i_lvs_rdy <= 1;
                i_res_rdy <= 1;
                @(posedge clk);//1
                i_lvs_rdy <= 0;
                i_res_rdy <= 0;
                @(posedge clk);//0
                i_lvs_rdy <= 1;
                i_res_rdy <= 1;
                @(posedge clk);//1
                @(posedge clk);//1
                i_lvs_rdy <= 0;
                i_res_rdy <= 0;
                @(posedge clk);//0
                @(posedge clk);//0
                i_lvs_rdy <= 1;
                i_res_rdy <= 1;
                @(posedge clk);//1
                i_lvs_rdy <= 0;
                i_res_rdy <= 0;
                @(posedge clk);//0
                @(posedge clk);//0
                @(posedge clk);//0
                //

                i_lvs_rdy <= 1;
                i_res_rdy <= 1;
                wait(o_lvs_vld == 0);//1111111111
                i_lvs_rdy <= 0;
                i_res_rdy <= 0;
                @(posedge clk);
                if (o_rdy) disable send_i_lvs_rdy_pause;  // ??o_rdy???????
                // else       $display("not disable send_i_lvs_rdy_pause;...");
                #100;
                if (o_rdy) disable send_i_lvs_rdy_pause;  // ??o_rdy???????
                // else       $display("not disable send_i_lvs_rdy_pause;...");
            end
        end
        // $display("wait(o_rdy);...");
        wait(o_rdy);
        i_res_rdy <= 1;
        i_lvs_rdy <= 1;
        #20;
        case ({i_size,i_signed})
            {B8  ,I}: if(signed_res_8   == out[8  -1:0] ) $display("Test case %03d :I8   : dui", index);else begin $display("Test case %03d :I8   : cuo", index); error = error + 1; end
            {B16 ,I}: if(signed_res_16  == out[16 -1:0] ) $display("Test case %03d :I16  : dui", index);else begin $display("Test case %03d :I16  : cuo", index); error = error + 1; end
            {B32 ,I}: if(signed_res_32  == out[32 -1:0] ) $display("Test case %03d :I32  : dui", index);else begin $display("Test case %03d :I32  : cuo", index); error = error + 1; end
            {B64 ,I}: if(signed_res_64  == out[64 -1:0] ) $display("Test case %03d :I64  : dui", index);else begin $display("Test case %03d :I64  : cuo", index); error = error + 1; end
            {B128,I}: if(signed_res_128 == out[128-1:0] ) $display("Test case %03d :I128 : dui", index);else begin $display("Test case %03d :I128 : cuo", index); error = error + 1; end
            {B8  ,U}: if(unsign_res_8   == out[8  -1:0] ) $display("Test case %03d :U8   : dui", index);else begin $display("Test case %03d :U8   : cuo", index); error = error + 1; end
            {B16 ,U}: if(unsign_res_16  == out[16 -1:0] ) $display("Test case %03d :U16  : dui", index);else begin $display("Test case %03d :U16  : cuo", index); error = error + 1; end
            {B32 ,U}: if(unsign_res_32  == out[32 -1:0] ) $display("Test case %03d :U32  : dui", index);else begin $display("Test case %03d :U32  : cuo", index); error = error + 1; end
            {B64 ,U}: if(unsign_res_64  == out[64 -1:0] ) $display("Test case %03d :U64  : dui", index);else begin $display("Test case %03d :U64  : cuo", index); error = error + 1; end
            {B128,U}: if(unsign_res_128 == out[128-1:0] ) $display("Test case %03d :U128 : dui", index);else begin $display("Test case %03d :U128 : cuo", index); error = error + 1; end
            default :                                     $display("Test case %03d :default   ", index);
        endcase
        #20;
        index <= index + 1;
        #200;
    end
endtask



task check_file_diff;
  input [1023:0] fileA_path;
  input [1023:0] fileB_path;

  integer fdA, fdB;
  integer countA, countB;
  reg [1023:0] lineA, lineB;
  integer diff_count, same_count;
  integer i;

  begin
    fdA = $fopen(fileA_path, "r");
    fdB = $fopen(fileB_path, "r");

    if (fdA == 0 || fdB == 0) begin
      $display("ERROR: Cannot open one of the files!");
      disable check_file_diff;
    end

    // 统计 A 文件行数
    countA = 0;
    while (!$feof(fdA)) begin
      if ($fgets(lineA, fdA))
        countA = countA + 1;
    end

    // 统计 B 文件行数
    countB = 0;
    while (!$feof(fdB)) begin
      if ($fgets(lineB, fdB))
        countB = countB + 1;
    end

    // 检查是否 A 比 B 多 2 行
    if (countA - countB != 2) begin
      $display("FAIL: File A has %0d lines, File B has %0d lines (not +2).", countA, countB);
    end

    // 重新打开文件用于逐行比较
    $fclose(fdA);
    $fclose(fdB);
    fdA = $fopen(fileA_path, "r");
    fdB = $fopen(fileB_path, "r");

    diff_count = 0;
    same_count = 0;

    for (i = 0; i < countB; i = i + 1) begin
      if ($fgets(lineA, fdA) && $fgets(lineB, fdB)) begin
        if (lineA != lineB) begin
          diff_count = diff_count + 1;
          // $display("A: %80d and B:%80d.", lineA,lineB);
          $display("FAIL: %0d lines differ between A and B.", i);
        end else
          same_count = same_count + 1;
      end
    end

    if (diff_count == 0)
      $display("PASS: File A has two extra lines and all others match.");
    else
      $display("FAIL: total %0d lines differ between A and B.", diff_count);

    $fclose(fdA);
    $fclose(fdB);
  end
endtask


task zzt_testcase;
    input [2:0]    task_size_in;
    input          task_signed_in;
    input [127:0]  task_data_in;
    input integer  x;
    input [255:0]  task_out;
    begin
        // $display("Test case %03d", index);
        zzt_testcase_cnt <= 0;
        zzt_testcase_cnt_max <= 0;
        #100;
        wait (o_rdy);
        zzt_testcase_r <= 1;
        @(posedge clk);
        // i_signed = 1 => I 1:8;  2:16;  3:32;   4:64;   5:128
        // i_signed = 0 => U 6:8;  7:16;  8:32;   9:64;  10:128
        i_size   <= task_size_in;
        i_signed <= task_signed_in;
        if (reverse == 1) begin
            i_a   <= task_data_in;
            // $display("not reverse_part opreation");
        end else begin
            reverse_part(task_size_in,task_data_in);
            // $display("reverse_part opreation");
        end
        out      <= task_out;
        i_vld <= 1;#10;
        i_vld <= 0;
        i_lvs_rdy <= 1;
        wait(cur_state == ST_OUTPUT);
        #600;i_res_rdy <= 1;
        // cur_res <= o_res;
        #200;
        begin : send_i_lvs_rdy
            forever begin
                i_lvs_rdy <= 1;
                @(posedge clk);
                if(x!=0) begin
                    i_lvs_rdy <= 0;
                    repeat (x) @(posedge clk);
                end
                if (o_rdy) disable send_i_lvs_rdy;  // ??o_rdy???????
            end
        end
        wait(o_rdy);
        zzt_testcase_r <= 0;
        #40;
        case ({i_size,i_signed})
            {B8  ,I}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt___8_max) zzt_testcase_cnt___8_max <= zzt_testcase_cnt_max; end
            {B16 ,I}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt__16_max) zzt_testcase_cnt__16_max <= zzt_testcase_cnt_max; end
            {B32 ,I}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt__32_max) zzt_testcase_cnt__32_max <= zzt_testcase_cnt_max; end
            {B64 ,I}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt__64_max) zzt_testcase_cnt__64_max <= zzt_testcase_cnt_max; end
            {B128,I}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt_128_max) zzt_testcase_cnt_128_max <= zzt_testcase_cnt_max; end
            {B8  ,U}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt___8_max) zzt_testcase_cnt___8_max <= zzt_testcase_cnt_max; end
            {B16 ,U}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt__16_max) zzt_testcase_cnt__16_max <= zzt_testcase_cnt_max; end
            {B32 ,U}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt__32_max) zzt_testcase_cnt__32_max <= zzt_testcase_cnt_max; end
            {B64 ,U}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt__64_max) zzt_testcase_cnt__64_max <= zzt_testcase_cnt_max; end
            {B128,U}: begin if(zzt_testcase_cnt_max>=zzt_testcase_cnt_128_max) zzt_testcase_cnt_128_max <= zzt_testcase_cnt_max; end
            default : begin $display("Test case %03d :default   ", index ,zzt_testcase_cnt_max); end
        endcase
        zzt_testcase_cnt <= 0;
        zzt_testcase_cnt_max <= 0;
        i_res_rdy <= 0;
        i_lvs_rdy <= 0;
        #20;
        case ({i_size,i_signed})
            {B8  ,I}: if(signed_res_8   == out[8  -1:0] ) $display("Test case %03d :I8   : dui", index);else begin $display("Test case %03d :I8   : cuo", index); error = error + 1; end
            {B16 ,I}: if(signed_res_16  == out[16 -1:0] ) $display("Test case %03d :I16  : dui", index);else begin $display("Test case %03d :I16  : cuo", index); error = error + 1; end
            {B32 ,I}: if(signed_res_32  == out[32 -1:0] ) $display("Test case %03d :I32  : dui", index);else begin $display("Test case %03d :I32  : cuo", index); error = error + 1; end
            {B64 ,I}: if(signed_res_64  == out[64 -1:0] ) $display("Test case %03d :I64  : dui", index);else begin $display("Test case %03d :I64  : cuo", index); error = error + 1; end
            {B128,I}: if(signed_res_128 == out[128-1:0] ) $display("Test case %03d :I128 : dui", index);else begin $display("Test case %03d :I128 : cuo", index); error = error + 1; end
            {B8  ,U}: if(unsign_res_8   == out[8  -1:0] ) $display("Test case %03d :U8   : dui", index);else begin $display("Test case %03d :U8   : cuo", index); error = error + 1; end
            {B16 ,U}: if(unsign_res_16  == out[16 -1:0] ) $display("Test case %03d :U16  : dui", index);else begin $display("Test case %03d :U16  : cuo", index); error = error + 1; end
            {B32 ,U}: if(unsign_res_32  == out[32 -1:0] ) $display("Test case %03d :U32  : dui", index);else begin $display("Test case %03d :U32  : cuo", index); error = error + 1; end
            {B64 ,U}: if(unsign_res_64  == out[64 -1:0] ) $display("Test case %03d :U64  : dui", index);else begin $display("Test case %03d :U64  : cuo", index); error = error + 1; end
            {B128,U}: if(unsign_res_128 == out[128-1:0] ) $display("Test case %03d :U128 : dui", index);else begin $display("Test case %03d :U128 : cuo", index); error = error + 1; end
            default :                                     $display("Test case %03d :default   ", index);
        endcase
        #20;
        index <= index + 1;
        #200;
    end
endtask



  task output_frame;
    integer i;
    begin
      // 初始化输出信号
      frame_data_out = 32'b0;
      frame_valid_out = 1'b0;
      // 遍历FRAME，从最高32位开始输出
      for (i = (32+WIDTH*8)/32 - 1; i >= 0; i = i - 1) begin
        // 等待时钟上升沿
        @(posedge clk);
        // 输出当前32位数据
        frame_data_out = FRAME[i*32 +: 32];  // 从第i*32位开始取32位
        frame_valid_out = 1'b1;
        // 可选：等待一个时钟周期，保持输出稳定
        // @(posedge clk);
      end
      // 最后一个数据输出后，在下一个时钟沿关闭有效信号
      @(posedge clk);
      frame_valid_out = 1'b0;
      frame_data_out = 32'b0;
    end
  endtask


  task xymem_showtest;
    begin
      // 简单验证打印：前 2 行与最后 2 行
      $display("--------------------------------------------------");
      $display("xmem[0]   = %0d", xmem[0]);
      $display("xmem[1]   = %0d", xmem[1]);
      $display("xmem[%0d] = %0d", DEPTH-2, xmem[DEPTH-2]);
      $display("xmem[%0d] = %0d", DEPTH-1, xmem[DEPTH-1]);
      $display("--------------------------------------------------");
      $display("ymem[0]   = %0d", ymem[0]);
      $display("ymem[1]   = %0d", ymem[1]);
      $display("ymem[%0d] = %0d", DEPTH-2, ymem[DEPTH-2]);
      $display("ymem[%0d] = %0d", DEPTH-1, ymem[DEPTH-1]);
      $display("--------------------------------------------------");
    end
  endtask

  // 任务：从十进制 TXT 逐行读入到 xmem[]
  task load_xmem_from_decimal_txt;
    begin
      fd = $fopen(XDATA_FILE, "r");
      if (fd == 0) begin
        $display("[%0t] ERROR: cannot open file: %0s", $time, XDATA_FILE);
        $finish;
      end

      for (i = 0; i < DEPTH; i = i + 1) begin
        xmem[i] = {WIDTH{1'b0}};
      end

      // 一行一行读取十进制到 256-bit 向量
      for (i = 0; i < DEPTH; i = i + 1) begin
        // %d 读取十进制；\n 允许按行
        read_items = $fscanf(fd, "%d\n", xmem[i]);
        if (read_items != 1) begin
          $display("[%0t] ERROR: read failed at line %0d (index %0d). read_items=%0d",
                   $time, i+1, i, read_items);
          $fclose(fd);
          $finish;
        end
      end
      $fclose(fd);
    end
  endtask
  task load_ymem_from_decimal_txt;
    begin
      fd = $fopen(YDATA_FILE, "r");
      if (fd == 0) begin
        $display("[%0t] ERROR: cannot open file: %0s", $time, YDATA_FILE);
        $finish;
      end

      for (i = 0; i < DEPTH; i = i + 1) begin
        ymem[i] = {WIDTH{1'b0}};
      end

      // 一行一行读取十进制到 256-bit 向量
      for (i = 0; i < DEPTH; i = i + 1) begin
        // %d 读取十进制；\n 允许按行
        read_items = $fscanf(fd, "%d\n", ymem[i]);
        if (read_items != 1) begin
          $display("[%0t] ERROR: read failed at line %0d (index %0d). read_items=%0d",
                   $time, i+1, i, read_items);
          $fclose(fd);
          $finish;
        end
      end
      $fclose(fd);
    end
  endtask










endmodule




/*
Executing instruction (hash.bhp256 r35 into r60 as i8;)
    r35 = 22i8
    r60 = -119i8

    ??? ?1?: Executing instruction (hash.bhp256 r23 into r49 as u16;)
    ??? ?2?: r23 = 23735u16
    ??? ?3?: r49 = 55547u16

    ??? ?1?: Executing instruction (hash.bhp256 r25 into r57 as u32;)
    ??? ?2?: r25 = 89873591u32
    ??? ?3?: r57 = 464081867u32

    ??? ?1?: Executing instruction (hash.bhp256 r38 into r63 as i64;)
    ??? ?2?: r38 = 7349275015491596769i64
    ??? ?3?: r63 = -3757354933473194135i64

    ??? ?1?: Executing instruction (hash.bhp256 r67 into r72 as u128;)
    ??? ?2?: r67 = 192090668717744200663610170445986434448u128
    ??? ?3?: r72 = 240735502027167243905959988592635201365u128

    ??? ?1?: Executing instruction (hash.bhp256 r35 into r106 as i8;)
    ??? ?2?: r35 = -127i8
    ??? ?3?: r106 = -108i8

    ??? ?1?: Executing instruction (hash.bhp256 r73 into r84 as u8;)
    ??? ?2?: r73 = 86u8
    ??? ?3?: r84 = 124u8

    ??? ?1?: Executing instruction (hash.bhp256 r36 into r53 as i16;)
    ??? ?2?: r36 = -30902i16
    ??? ?3?: r53 = -5436i16

    ??? ?7?: Executing instruction (hash.bhp256 r23 into r49 as u16;)
    ??? ?8?: r23 = 39939u16
    ??? ?9?: r49 = 65180u16

    ??? ?1?: Executing instruction (hash.bhp256 r25 into r88 as u32;)
    ??? ?2?: r25 = 802929591u32
    ??? ?3?: r88 = 44175768u32

    ??? ?1?: Executing instruction (hash.bhp256 r37 into r101 as i32;)
    ??? ?2?: r37 = -1011790862i32
    ??? ?3?: r101 = 1204778383i32

    ??? ?1?: Executing instruction (hash.bhp256 r62 into r74 as u32;)
    ??? ?2?: r62 = 1858718550u32
    ??? ?3?: r74 = 4190545906u32

    ??? ?1?: Executing instruction (hash.bhp256 r38 into r52 as i64;)
    ??? ?2?: r38 = -9090623647574692322i64
    ??? ?3?: r52 = -4141294807192883151i64

    ??? ?1?: Executing instruction (hash.bhp256 r43 into r129 as i128;)
    ??? ?2?: r43 = -58129452728141601913315296611871496315i128
    ??? ?3?: r129 = -90688762945525946560039629278205026328i128

    ??? ?1?: Executing instruction (hash.bhp256 r72 into r101 as u128;)
    ??? ?2?: r72 = 240735502027167243905959988592635201365u128
    ??? ?3?: r101 = 61796151080661114844789465080232536318u128

    ??? ?1?: Executing instruction (hash.bhp256 r59 into r108 as i128;)
    ??? ?2?: r59 = 133628952285256420965695742983782959519i128
    ??? ?3?: r108 = 21937996922040675612839171161438846618i128

    ??? ?7?: Executing instruction (hash.bhp256 r59 into r108 as i128;)
    ??? ?8?: r59 = -49268328380429069828539320563432294990i128
    ??? ?9?: r108 = -17769464564413354883854205372395042579i128

Executing instruction (hash.bhp256 r100 into r101 as u64;)
    r100 = 7843971993126053774u64
    r101 = 13939859218897041345u64

Executing instruction (hash.bhp256 r100 into r101 as u64;)
    r100 = 7657389525338381738u64
    r101 = 15797984249017069009u64

Executing instruction (hash.bhp256 r100 into r101 as u64;)
    r100 = 2261433195024223466u64
    r101 = 2124715295645252764u64

Executing instruction (hash.bhp256 r100 into r101 as u64;)
    r100 = 9563632776832309056u64
    r101 = 9611865768901920898u64

*/








