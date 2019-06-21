/*
 SW8 (GLOBAL RESET) resets LCD
ENTITY LCD_Display IS
-- Enter number of live Hex hardware data values to display
-- (do not count ASCII character constants)
    GENERIC(Num_Hex_Digits: Integer:= 2); 
-----------------------------------------------------------------------
-- LCD Displays 16 Characters on 2 lines
-- LCD_display string is an ASCII character string entered in hex for 
-- the two lines of the  LCD Display   (See ASCII to hex table below)
-- Edit LCD_Display_String entries above to modify display
-- Enter the ASCII character's 2 hex digit equivalent value
-- (see table below for ASCII hex values)
-- To display character assign ASCII value to LCD_display_string(x)
-- To skip a character use 8'h20" (ASCII space)
-- To dislay "live" hex values from hardware on LCD use the following: 
--   make array element for that character location 8'h0" & 4-bit field from Hex_Display_Data
--   state machine sees 8'h0" in high 4-bits & grabs the next lower 4-bits from Hex_Display_Data input
--   and performs 4-bit binary to ASCII conversion needed to print a hex digit
--   Num_Hex_Digits must be set to the count of hex data characters (ie. "00"s) in the display
--   Connect hardware bits to display to Hex_Display_Data input
-- To display less than 32 characters, terminate string with an entry of 8'hFE"
--  (fewer characters may slightly increase the LCD's data update rate)
------------------------------------------------------------------- 
--                        ASCII HEX TABLE
--  Hex                        Low Hex Digit
-- Value  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
------\----------------------------------------------------------------
--H  2 |  SP  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
--i  3 |  0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
--g  4 |  @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
--h  5 |  P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
--   6 |  `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
--   7 |  p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~ DEL
-----------------------------------------------------------------------
-- Example "A" is row 4 column 1, so hex value is 8'h41"
-- *see LCD Controller's Datasheet for other graphics characters available
*/
        
module LCD_Display(iCLK_50MHZ, iRST_N, 
    LCD_RS,LCD_E,LCD_RW,DATA_BUS,
	 ESTADO,FLAG_MUDANCA_LCD, OPCODE);
	 

input [4:0] OPCODE;	 
input [21:0] ESTADO;
input FLAG_MUDANCA_LCD;

	 
input iCLK_50MHZ, iRST_N;
output LCD_RS, LCD_E, LCD_RW;
inout [7:0] DATA_BUS;

parameter
HOLD = 4'h0,
FUNC_SET = 4'h1,
DISPLAY_ON = 4'h2,
MODE_SET = 4'h3,
Print_String = 4'h4,
LINE2 = 4'h5,
RETURN_HOME = 4'h6,
DROP_LCD_E = 4'h7,
RESET1 = 4'h8,
RESET2 = 4'h9,
RESET3 = 4'ha,
DISPLAY_OFF = 4'hb,
DISPLAY_CLEAR = 4'hc;

reg [3:0] state, next_command;
// Enter new ASCII hex data above for LCD Display
reg [7:0] DATA_BUS_VALUE;
wire [7:0] Next_Char;
reg [19:0] CLK_COUNT_400HZ;
reg [4:0] CHAR_COUNT;
reg CLK_400HZ, LCD_RW_INT, LCD_E, LCD_RS;

// BIDIRECTIONAL TRI STATE LCD DATA BUS
assign DATA_BUS = (LCD_RW_INT? 8'bZZZZZZZZ: DATA_BUS_VALUE);

LCD_display_string u1(
.index(CHAR_COUNT),
.out(Next_Char),
.ESTADO(ESTADO),
.FLAG_MUDANCA_LCD(FLAG_MUDANCA_LCD),
.iCLK_50MHZ(iCLK_50MHZ),
.OPCODE(OPCODE)
);

assign LCD_RW = LCD_RW_INT;

always @(posedge iCLK_50MHZ or negedge iRST_N)
    if (!iRST_N)
    begin
       CLK_COUNT_400HZ <= 20'h00000;
       CLK_400HZ <= 1'b0;
    end
    else if (CLK_COUNT_400HZ < 20'h0F424)
    begin
       CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1'b1;
    end
    else
    begin
      CLK_COUNT_400HZ <= 20'h00000;
      CLK_400HZ <= ~CLK_400HZ;
    end
// State Machine to send commands and data to LCD DISPLAY

always @(posedge CLK_400HZ or negedge iRST_N)
    if (!iRST_N)
    begin
     state <= RESET1;
    end
    else
    case (state)
    RESET1:            
// Set Function to 8-bit transfer and 2 line display with 5x8 Font size
// see Hitachi HD44780 family data sheet for LCD command and timing details
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h38;
      state <= DROP_LCD_E;
      next_command <= RESET2;
      CHAR_COUNT <= 5'b00000;
    end
    RESET2:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h38;
      state <= DROP_LCD_E;
      next_command <= RESET3;
    end
    RESET3:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h38;
      state <= DROP_LCD_E;
      next_command <= FUNC_SET;
    end
// EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD

    FUNC_SET:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h38;
      state <= DROP_LCD_E;
      next_command <= DISPLAY_OFF;
    end

// Turn off Display and Turn off cursor
    DISPLAY_OFF:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h08;
      state <= DROP_LCD_E;
      next_command <= DISPLAY_CLEAR;
    end

// Clear Display and Turn off cursor
    DISPLAY_CLEAR:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h01;
      state <= DROP_LCD_E;
      next_command <= DISPLAY_ON;
    end

// Turn on Display and Turn off cursor
    DISPLAY_ON:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h0C;
      state <= DROP_LCD_E;
      next_command <= MODE_SET;
    end

// Set write mode to auto increment address and move cursor to the right
    MODE_SET:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h06;
      state <= DROP_LCD_E;
      next_command <= Print_String;
    end

// Write ASCII hex character in first LCD character location
    Print_String:
    begin
      state <= DROP_LCD_E;
      LCD_E <= 1'b1;
      LCD_RS <= 1'b1;
      LCD_RW_INT <= 1'b0;
    // ASCII character to output
      if (Next_Char[7:4] != 4'h0)
        DATA_BUS_VALUE <= Next_Char;
        // Convert 4-bit value to an ASCII hex digit
      else if (Next_Char[3:0] >9)
        // ASCII A...F
         DATA_BUS_VALUE <= {4'h4,Next_Char[3:0]-4'h9};
      else
        // ASCII 0...9
         DATA_BUS_VALUE <= {4'h3,Next_Char[3:0]};
    // Loop to send out 32 characters to LCD Display  (16 by 2 lines)
      if ((CHAR_COUNT < 31) && (Next_Char != 8'hFE))
         CHAR_COUNT <= CHAR_COUNT + 1'b1;
      else
         CHAR_COUNT <= 5'b00000; 
    // Jump to second line?
      if (CHAR_COUNT == 15)
        next_command <= LINE2;
    // Return to first line?
      else if ((CHAR_COUNT == 31) || (Next_Char == 8'hFE))
        next_command <= RETURN_HOME;
      else
        next_command <= Print_String;
    end

// Set write address to line 2 character 1
    LINE2:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'hC0;
      state <= DROP_LCD_E;
      next_command <= Print_String;
    end

// Return write address to first character postion on line 1
    RETURN_HOME:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h80;
      state <= DROP_LCD_E;
      next_command <= Print_String;
    end

// The next three states occur at the end of each command or data transfer to the LCD
// Drop LCD E line - falling edge loads inst/data to LCD controller
    DROP_LCD_E:
    begin
      LCD_E <= 1'b0;
      state <= HOLD;
    end
// Hold LCD inst/data valid after falling edge of E line                
    HOLD:
    begin
      state <= next_command;
    end
    endcase
endmodule



module LCD_display_string(iCLK_50MHZ,index,out,ESTADO,FLAG_MUDANCA_LCD,OPCODE); //,hex0,hex1);
input iCLK_50MHZ;
input [4:0] index;
output [7:0] out;
reg [7:0] out;

input [21:0] ESTADO;
input FLAG_MUDANCA_LCD;
input [4:0] OPCODE;


	localparam DATA_WIDTH = 32;
	localparam CHAR_WIDTH = 8;
	localparam LCD_WIDTH = 32;
	
	localparam	OPCODE_LCD = 10;
	
	//--------------Internal variables---------------------
	localparam [CHAR_WIDTH-1:0] ESTADO_0 = 8'd0;//0 
	localparam [CHAR_WIDTH-1:0] ESTADO_1 = 8'd1; //1
	localparam [CHAR_WIDTH-1:0] ESTADO_2 = 8'd2; //2
	localparam [CHAR_WIDTH-1:0] ESTADO_3 = 8'd3; //3
	localparam [CHAR_WIDTH-1:0] ESTADO_4 = 8'd4; //4
	localparam [CHAR_WIDTH-1:0] ESTADO_5 = 8'd5; //5
	localparam [CHAR_WIDTH-1:0] ESTADO_6 = 8'd6; //6
	localparam [CHAR_WIDTH-1:0] ESTADO_7 = 8'd7; //7
	localparam [CHAR_WIDTH-1:0] ESTADO_8 = 8'd8; //8
	localparam [CHAR_WIDTH-1:0] ESTADO_10 = 8'd10; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_11 = 8'd11; //10
	//localparam [CHAR_WIDTH-1:0] ESTADO_12 = 8'd10; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_13 = 8'd13; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_14 = 8'd14; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_15 = 8'd15; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_16 = 8'd16; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_17 = 8'd17; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_18 = 8'd18; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_19 = 8'd19; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_20 = 8'd20; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_21 = 8'd21; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_22 = 8'd22; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_23 = 8'd23; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_24 = 8'd24; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_25 = 8'd25; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_26 = 8'd26; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_27 = 8'd27; //10
	localparam [CHAR_WIDTH-1:0] ESTADO_28 = 8'd28; //10

	// Letras minusculas
	localparam	CHAR_a = 8'h61, CHAR_b = 8'h62, CHAR_c = 8'h63, CHAR_d = 8'h64;
	localparam	CHAR_e = 8'h65, CHAR_f = 8'h66, CHAR_g = 8'h67, CHAR_h = 8'h68;
	localparam	CHAR_i = 8'h69, CHAR_j = 8'h6A, CHAR_k = 8'h6B, CHAR_l = 8'h6C;
	localparam	CHAR_m = 8'h6D, CHAR_n = 8'h6E, CHAR_o = 8'h6F, CHAR_p = 8'h70;
	localparam	CHAR_q = 8'h71, CHAR_r = 8'h72, CHAR_s = 8'h73, CHAR_t = 8'h74;
	localparam	CHAR_u = 8'h75, CHAR_v = 8'h76, CHAR_w = 8'h77, CHAR_x = 8'h78;
	localparam	CHAR_y = 8'h79, CHAR_z = 8'h7A;
	
	// Letras maiusculas
	localparam	CHAR_A = 8'h41, CHAR_B = 8'h42, CHAR_C = 8'h43, CHAR_D = 8'h44;
	localparam	CHAR_E = 8'h45, CHAR_F = 8'h46, CHAR_G = 8'h47, CHAR_H = 8'h48;
	localparam	CHAR_I = 8'h49, CHAR_J = 8'h4A, CHAR_K = 8'h4B, CHAR_L = 8'h4C;
	localparam	CHAR_M = 8'h4D, CHAR_N = 8'h4E, CHAR_O = 8'h4F, CHAR_P = 8'h50;
	localparam	CHAR_Q = 8'h51, CHAR_R = 8'h52, CHAR_S = 8'h53, CHAR_T = 8'h54;
	localparam	CHAR_U = 8'h55, CHAR_V = 8'h56, CHAR_W = 8'h57, CHAR_X = 8'h58;
	localparam	CHAR_Y = 8'h59, CHAR_Z = 8'h5A;
	
	// Digitos
	localparam	CHAR_0 = 8'h30, CHAR_1 = 8'h31, CHAR_2 = 8'h32, CHAR_3 = 8'h33;
	localparam	CHAR_4 = 8'h34, CHAR_5 = 8'h35, CHAR_6 = 8'h36, CHAR_7 = 8'h37;
	localparam	CHAR_8 = 8'h38, CHAR_9 = 8'h39;
	
	// Caracteres especiais
	localparam	CHAR_SPACE = 8'h20, CHAR_LEFT_BRACKET = 8'h5B, CHAR_RIGHT_BRACKET = 8'h5D;
	localparam	CHAR_HYPHEN = 8'h2D, CHAR_HASHTAG = 8'h23, CHAR_AT = 8'h40, CHAR_PLUS = 8'h2B;
	localparam	CHAR_COLLON = 8'h3A, CHAR_DOT = 8'h2E, CHAR_EXC = 8'h20, CHAR_INT = 8'h3F;
	
	
	// Menu State Values
	wire [CHAR_WIDTH-1:0] ESTADO_0_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_1_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_2_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_3_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_4_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_5_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_6_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_7_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_8_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_10_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_11_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_13_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_14_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_15_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_16_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_17_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_18_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_19_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_20_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_21_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_22_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_23_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_24_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_25_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_26_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_27_STRING [0:LCD_WIDTH-1];
	wire [CHAR_WIDTH-1:0] ESTADO_28_STRING [0:LCD_WIDTH-1];
	
	reg [CHAR_WIDTH:0] STATE_LCD_CHANGE;
	




/*****************************************************************************************/
/******************************* ESTADOS DOS MENUS ***************************************/
/*****************************************************************************************/

	initial begin
		STATE_LCD_CHANGE=0;
	end

	/*****************************************************************************************/
	/***************************** DEFINIÇAO DOS MENUS ***************************************/
	/*****************************************************************************************/
	


	
	// Line 1
	assign ESTADO_0_STRING[5'd0] = CHAR_I;  //INICIALIZE COM 18'b100000000000000001
	assign ESTADO_0_STRING[5'd1] = CHAR_N;
	assign ESTADO_0_STRING[5'd2] = CHAR_I;
	assign ESTADO_0_STRING[5'd3] = CHAR_C;
	assign ESTADO_0_STRING[5'd4] = CHAR_I;
	assign ESTADO_0_STRING[5'd5] = CHAR_A;
	assign ESTADO_0_STRING[5'd6] = CHAR_L;
	assign ESTADO_0_STRING[5'd7] = CHAR_I;
	assign ESTADO_0_STRING[5'd8] = CHAR_Z;
	assign ESTADO_0_STRING[5'd9] = CHAR_E;
	assign ESTADO_0_STRING[5'd10] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd11] = CHAR_C;
	assign ESTADO_0_STRING[5'd12] = CHAR_O;
	assign ESTADO_0_STRING[5'd13] = CHAR_M;
	assign ESTADO_0_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_0_STRING[5'd16] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd17] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd18] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd19] = CHAR_A;
	assign ESTADO_0_STRING[5'd20] = CHAR_S;
	assign ESTADO_0_STRING[5'd21] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd22] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd23] = CHAR_C;
	assign ESTADO_0_STRING[5'd24] = CHAR_H;
	assign ESTADO_0_STRING[5'd25] = CHAR_A;
	assign ESTADO_0_STRING[5'd26] = CHAR_V;
	assign ESTADO_0_STRING[5'd27] = CHAR_E;
	assign ESTADO_0_STRING[5'd28] = CHAR_S;
	assign ESTADO_0_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_0_STRING[5'd31] = CHAR_SPACE;	
	
	// Line 1
	assign ESTADO_1_STRING[5'd0] = CHAR_C;  //ENTRE COM O NUM
	assign ESTADO_1_STRING[5'd1] = CHAR_A;
	assign ESTADO_1_STRING[5'd2] = CHAR_R;
	assign ESTADO_1_STRING[5'd3] = CHAR_R;
	assign ESTADO_1_STRING[5'd4] = CHAR_E;
	assign ESTADO_1_STRING[5'd5] = CHAR_G;
	assign ESTADO_1_STRING[5'd6] = CHAR_A;
	assign ESTADO_1_STRING[5'd7] = CHAR_N;
	assign ESTADO_1_STRING[5'd8] = CHAR_D;
	assign ESTADO_1_STRING[5'd9] = CHAR_O;
	assign ESTADO_1_STRING[5'd10] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd11] = CHAR_O;
	assign ESTADO_1_STRING[5'd12] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd13] = CHAR_S;
	assign ESTADO_1_STRING[5'd14] = CHAR_O;
	assign ESTADO_1_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_1_STRING[5'd16] = CHAR_SPACE; 
	assign ESTADO_1_STRING[5'd17] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd18] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd19] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd20] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd21] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd22] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd23] = CHAR_DOT;
	assign ESTADO_1_STRING[5'd24] = CHAR_DOT;
	assign ESTADO_1_STRING[5'd25] = CHAR_DOT;
	assign ESTADO_1_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_1_STRING[5'd31] = CHAR_SPACE;


	
	// Line 1
	assign ESTADO_2_STRING[5'd0] = CHAR_C;  //MENU
	assign ESTADO_2_STRING[5'd1] = CHAR_A;
	assign ESTADO_2_STRING[5'd2] = CHAR_R;
	assign ESTADO_2_STRING[5'd3] = CHAR_R;
	assign ESTADO_2_STRING[5'd4] = CHAR_E;
	assign ESTADO_2_STRING[5'd5] = CHAR_G;
	assign ESTADO_2_STRING[5'd6] = CHAR_A;
	assign ESTADO_2_STRING[5'd7] = CHAR_N;
	assign ESTADO_2_STRING[5'd8] = CHAR_D;
	assign ESTADO_2_STRING[5'd9] = CHAR_O;
	assign ESTADO_2_STRING[5'd10] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd11] = CHAR_O;
	assign ESTADO_2_STRING[5'd12] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd13] = CHAR_S;
	assign ESTADO_2_STRING[5'd14] = CHAR_O;
	assign ESTADO_2_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_2_STRING[5'd16] = CHAR_A; //AGUARDE
	assign ESTADO_2_STRING[5'd17] = CHAR_G;
	assign ESTADO_2_STRING[5'd18] = CHAR_U;
	assign ESTADO_2_STRING[5'd19] = CHAR_A;
	assign ESTADO_2_STRING[5'd20] = CHAR_R;
	assign ESTADO_2_STRING[5'd21] = CHAR_D;
	assign ESTADO_2_STRING[5'd22] = CHAR_E;
	assign ESTADO_2_STRING[5'd23] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_2_STRING[5'd31] = CHAR_SPACE;

	

	// Line 1
	assign ESTADO_3_STRING[5'd0] = CHAR_E;  //EXECUTANDO
	assign ESTADO_3_STRING[5'd1] = CHAR_X;
	assign ESTADO_3_STRING[5'd2] = CHAR_E;
	assign ESTADO_3_STRING[5'd3] = CHAR_C;
	assign ESTADO_3_STRING[5'd4] = CHAR_U;
	assign ESTADO_3_STRING[5'd5] = CHAR_T;
	assign ESTADO_3_STRING[5'd6] = CHAR_A;
	assign ESTADO_3_STRING[5'd7] = CHAR_N;
	assign ESTADO_3_STRING[5'd8] = CHAR_D;
	assign ESTADO_3_STRING[5'd9] = CHAR_O;
	assign ESTADO_3_STRING[5'd10] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd11] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd12] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_3_STRING[5'd16] = CHAR_P; //PROGRAMA
	assign ESTADO_3_STRING[5'd17] = CHAR_R;
	assign ESTADO_3_STRING[5'd18] = CHAR_O;
	assign ESTADO_3_STRING[5'd19] = CHAR_G;
	assign ESTADO_3_STRING[5'd20] = CHAR_R;
	assign ESTADO_3_STRING[5'd21] = CHAR_A;
	assign ESTADO_3_STRING[5'd22] = CHAR_M;
	assign ESTADO_3_STRING[5'd23] = CHAR_A;
	assign ESTADO_3_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_3_STRING[5'd31] = CHAR_SPACE;
	
	
	
	// Line 1
	assign ESTADO_4_STRING[5'd0] = CHAR_E;  //ERRO
	assign ESTADO_4_STRING[5'd1] = CHAR_R;
	assign ESTADO_4_STRING[5'd2] = CHAR_R;
	assign ESTADO_4_STRING[5'd3] = CHAR_O;
	assign ESTADO_4_STRING[5'd4] = CHAR_SPACE;
	assign ESTADO_4_STRING[5'd5] = CHAR_HYPHEN;
	assign ESTADO_4_STRING[5'd6] = CHAR_E;
	assign ESTADO_4_STRING[5'd7] = CHAR_N;
	assign ESTADO_4_STRING[5'd8] = CHAR_T;
	assign ESTADO_4_STRING[5'd9] = CHAR_R;
	assign ESTADO_4_STRING[5'd10] = CHAR_E;
	assign ESTADO_4_STRING[5'd11] = CHAR_SPACE;
	assign ESTADO_4_STRING[5'd12] = CHAR_C;
	assign ESTADO_4_STRING[5'd13] = CHAR_O;
	assign ESTADO_4_STRING[5'd14] = CHAR_M;
	assign ESTADO_4_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_4_STRING[5'd16] = CHAR_O; //PROGRAMA
	assign ESTADO_4_STRING[5'd17] = CHAR_SPACE;
	assign ESTADO_4_STRING[5'd18] = CHAR_N;
	assign ESTADO_4_STRING[5'd19] = CHAR_U;
	assign ESTADO_4_STRING[5'd20] = CHAR_M;
	assign ESTADO_4_STRING[5'd21] = CHAR_E;
	assign ESTADO_4_STRING[5'd22] = CHAR_R;
	assign ESTADO_4_STRING[5'd23] = CHAR_O;
	assign ESTADO_4_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_4_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_4_STRING[5'd26] = CHAR_1;
	assign ESTADO_4_STRING[5'd27] = CHAR_3;
	assign ESTADO_4_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_4_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_4_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_4_STRING[5'd31] = CHAR_SPACE;
	
		// Line 1
	assign ESTADO_10_STRING[5'd0] = CHAR_I;  //INICIALIZANDO O SISTEMA 
	assign ESTADO_10_STRING[5'd1] = CHAR_N;
	assign ESTADO_10_STRING[5'd2] = CHAR_I;
	assign ESTADO_10_STRING[5'd3] = CHAR_C;
	assign ESTADO_10_STRING[5'd4] = CHAR_I;
	assign ESTADO_10_STRING[5'd5] = CHAR_A;
	assign ESTADO_10_STRING[5'd6] = CHAR_L;
	assign ESTADO_10_STRING[5'd7] = CHAR_I;
	assign ESTADO_10_STRING[5'd8] = CHAR_Z;
	assign ESTADO_10_STRING[5'd9] = CHAR_A;
	assign ESTADO_10_STRING[5'd10] = CHAR_N;
	assign ESTADO_10_STRING[5'd11] = CHAR_D;
	assign ESTADO_10_STRING[5'd12] = CHAR_O;
	assign ESTADO_10_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd14] = CHAR_O;
	assign ESTADO_10_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_10_STRING[5'd16] = CHAR_S;
	assign ESTADO_10_STRING[5'd17] = CHAR_I;
	assign ESTADO_10_STRING[5'd18] = CHAR_S;
	assign ESTADO_10_STRING[5'd19] = CHAR_T;
	assign ESTADO_10_STRING[5'd20] = CHAR_E;
	assign ESTADO_10_STRING[5'd21] = CHAR_M;
	assign ESTADO_10_STRING[5'd22] = CHAR_A;
	assign ESTADO_10_STRING[5'd23] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_10_STRING[5'd31] = CHAR_SPACE;
	
			// Line 1
	assign ESTADO_11_STRING[5'd0] = CHAR_S;  //BEM VINDO
	assign ESTADO_11_STRING[5'd1] = CHAR_E;
	assign ESTADO_11_STRING[5'd2] = CHAR_L;
	assign ESTADO_11_STRING[5'd3] = CHAR_E;
	assign ESTADO_11_STRING[5'd4] = CHAR_C;
	assign ESTADO_11_STRING[5'd5] = CHAR_I;
	assign ESTADO_11_STRING[5'd6] = CHAR_O;
	assign ESTADO_11_STRING[5'd7] = CHAR_N;
	assign ESTADO_11_STRING[5'd8] = CHAR_E;
	assign ESTADO_11_STRING[5'd9] = CHAR_SPACE;
	assign ESTADO_11_STRING[5'd10] = CHAR_O;
	assign ESTADO_11_STRING[5'd11] = CHAR_P;
	assign ESTADO_11_STRING[5'd12] = CHAR_C;
	assign ESTADO_11_STRING[5'd13] = CHAR_A;
	assign ESTADO_11_STRING[5'd14] = CHAR_O;
	assign ESTADO_11_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_11_STRING[5'd16] = CHAR_1;
	assign ESTADO_11_STRING[5'd17] = CHAR_I; //1 - INSERE
	assign ESTADO_11_STRING[5'd18] = CHAR_SPACE;
	assign ESTADO_11_STRING[5'd19] = CHAR_SPACE;
	assign ESTADO_11_STRING[5'd20] = CHAR_2;
	assign ESTADO_11_STRING[5'd21] = CHAR_E; //2 EXECUTA 
	assign ESTADO_11_STRING[5'd22] = CHAR_SPACE;
	assign ESTADO_11_STRING[5'd23] = CHAR_SPACE;
	assign ESTADO_11_STRING[5'd24] = CHAR_3;
	assign ESTADO_11_STRING[5'd25] = CHAR_R; //3 RENOMEIA 
	assign ESTADO_11_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_11_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_11_STRING[5'd28] = CHAR_4;
	assign ESTADO_11_STRING[5'd29] = CHAR_D; //4 DELETA
	assign ESTADO_11_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_11_STRING[5'd31] = CHAR_SPACE;

	
	
				// Line 1
	assign ESTADO_13_STRING[5'd0] = CHAR_O;  //OPCAO : INSERIR PROGRAMA 
	assign ESTADO_13_STRING[5'd1] = CHAR_P;
	assign ESTADO_13_STRING[5'd2] = CHAR_C;
	assign ESTADO_13_STRING[5'd3] = CHAR_A;
	assign ESTADO_13_STRING[5'd4] = CHAR_O;
	assign ESTADO_13_STRING[5'd5] = CHAR_SPACE;
	assign ESTADO_13_STRING[5'd6] = CHAR_COLLON;
	assign ESTADO_13_STRING[5'd7] = CHAR_SPACE;
	assign ESTADO_13_STRING[5'd8] = CHAR_I;
	assign ESTADO_13_STRING[5'd9] = CHAR_N;
	assign ESTADO_13_STRING[5'd10] = CHAR_S;
	assign ESTADO_13_STRING[5'd11] = CHAR_E;
	assign ESTADO_13_STRING[5'd12] = CHAR_R;
	assign ESTADO_13_STRING[5'd13] = CHAR_I;
	assign ESTADO_13_STRING[5'd14] = CHAR_R;
	assign ESTADO_13_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_13_STRING[5'd16] = CHAR_P;
	assign ESTADO_13_STRING[5'd17] = CHAR_R; 
	assign ESTADO_13_STRING[5'd18] = CHAR_O;
	assign ESTADO_13_STRING[5'd19] = CHAR_G;
	assign ESTADO_13_STRING[5'd20] = CHAR_R;
	assign ESTADO_13_STRING[5'd21] = CHAR_A; 
	assign ESTADO_13_STRING[5'd22] = CHAR_M;
	assign ESTADO_13_STRING[5'd23] = CHAR_A;
	assign ESTADO_13_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_13_STRING[5'd25] = CHAR_SPACE; 
	assign ESTADO_13_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_13_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_13_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_13_STRING[5'd29] = CHAR_SPACE; 
	assign ESTADO_13_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_13_STRING[5'd31] = CHAR_SPACE;

					// Line 1
	assign ESTADO_14_STRING[5'd0] = CHAR_O;  //OPCAO : EXECUTAR PROGRAMA 
	assign ESTADO_14_STRING[5'd1] = CHAR_P;
	assign ESTADO_14_STRING[5'd2] = CHAR_C;
	assign ESTADO_14_STRING[5'd3] = CHAR_A;
	assign ESTADO_14_STRING[5'd4] = CHAR_O;
	assign ESTADO_14_STRING[5'd5] = CHAR_SPACE;
	assign ESTADO_14_STRING[5'd6] = CHAR_COLLON;
	assign ESTADO_14_STRING[5'd7] = CHAR_SPACE;
	assign ESTADO_14_STRING[5'd8] = CHAR_E;
	assign ESTADO_14_STRING[5'd9] = CHAR_X;
	assign ESTADO_14_STRING[5'd10] = CHAR_E;
	assign ESTADO_14_STRING[5'd11] = CHAR_C;
	assign ESTADO_14_STRING[5'd12] = CHAR_U;
	assign ESTADO_14_STRING[5'd13] = CHAR_T;
	assign ESTADO_14_STRING[5'd14] = CHAR_A;
	assign ESTADO_14_STRING[5'd15] = CHAR_R;
	// Line 2
	assign ESTADO_14_STRING[5'd16] = CHAR_P;
	assign ESTADO_14_STRING[5'd17] = CHAR_R; 
	assign ESTADO_14_STRING[5'd18] = CHAR_O;
	assign ESTADO_14_STRING[5'd19] = CHAR_G;
	assign ESTADO_14_STRING[5'd20] = CHAR_R;
	assign ESTADO_14_STRING[5'd21] = CHAR_A; 
	assign ESTADO_14_STRING[5'd22] = CHAR_M;
	assign ESTADO_14_STRING[5'd23] = CHAR_A;
	assign ESTADO_14_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_14_STRING[5'd25] = CHAR_SPACE; 
	assign ESTADO_14_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_14_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_14_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_14_STRING[5'd29] = CHAR_SPACE; 
	assign ESTADO_14_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_14_STRING[5'd31] = CHAR_SPACE;
	
	
						// Line 1
	assign ESTADO_15_STRING[5'd0] = CHAR_O;  //OPCAO : RENOMEAR PROGRAMA 
	assign ESTADO_15_STRING[5'd1] = CHAR_P;
	assign ESTADO_15_STRING[5'd2] = CHAR_C;
	assign ESTADO_15_STRING[5'd3] = CHAR_A;
	assign ESTADO_15_STRING[5'd4] = CHAR_O;
	assign ESTADO_15_STRING[5'd5] = CHAR_SPACE;
	assign ESTADO_15_STRING[5'd6] = CHAR_COLLON;
	assign ESTADO_15_STRING[5'd7] = CHAR_SPACE;
	assign ESTADO_15_STRING[5'd8] = CHAR_R;
	assign ESTADO_15_STRING[5'd9] = CHAR_E;
	assign ESTADO_15_STRING[5'd10] = CHAR_N;
	assign ESTADO_15_STRING[5'd11] = CHAR_O;
	assign ESTADO_15_STRING[5'd12] = CHAR_M;
	assign ESTADO_15_STRING[5'd13] = CHAR_E;
	assign ESTADO_15_STRING[5'd14] = CHAR_A;
	assign ESTADO_15_STRING[5'd15] = CHAR_R;
	// Line 2
	assign ESTADO_15_STRING[5'd16] = CHAR_P;
	assign ESTADO_15_STRING[5'd17] = CHAR_R; 
	assign ESTADO_15_STRING[5'd18] = CHAR_O;
	assign ESTADO_15_STRING[5'd19] = CHAR_G;
	assign ESTADO_15_STRING[5'd20] = CHAR_R;
	assign ESTADO_15_STRING[5'd21] = CHAR_A; 
	assign ESTADO_15_STRING[5'd22] = CHAR_M;
	assign ESTADO_15_STRING[5'd23] = CHAR_A;
	assign ESTADO_15_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_15_STRING[5'd25] = CHAR_SPACE; 
	assign ESTADO_15_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_15_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_15_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_15_STRING[5'd29] = CHAR_SPACE; 
	assign ESTADO_15_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_15_STRING[5'd31] = CHAR_SPACE;
	
	
							// Line 1
	assign ESTADO_16_STRING[5'd0] = CHAR_O;  //OPCAO : EXCLUIR PROGRAMA 
	assign ESTADO_16_STRING[5'd1] = CHAR_P;
	assign ESTADO_16_STRING[5'd2] = CHAR_C;
	assign ESTADO_16_STRING[5'd3] = CHAR_A;
	assign ESTADO_16_STRING[5'd4] = CHAR_O;
	assign ESTADO_16_STRING[5'd5] = CHAR_SPACE;
	assign ESTADO_16_STRING[5'd6] = CHAR_COLLON;
	assign ESTADO_16_STRING[5'd7] = CHAR_SPACE;
	assign ESTADO_16_STRING[5'd8] = CHAR_E;
	assign ESTADO_16_STRING[5'd9] = CHAR_X;
	assign ESTADO_16_STRING[5'd10] = CHAR_C;
	assign ESTADO_16_STRING[5'd11] = CHAR_L;
	assign ESTADO_16_STRING[5'd12] = CHAR_U;
	assign ESTADO_16_STRING[5'd13] = CHAR_I;
	assign ESTADO_16_STRING[5'd14] = CHAR_R;
	assign ESTADO_16_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_16_STRING[5'd16] = CHAR_P;
	assign ESTADO_16_STRING[5'd17] = CHAR_R; 
	assign ESTADO_16_STRING[5'd18] = CHAR_O;
	assign ESTADO_16_STRING[5'd19] = CHAR_G;
	assign ESTADO_16_STRING[5'd20] = CHAR_R;
	assign ESTADO_16_STRING[5'd21] = CHAR_A; 
	assign ESTADO_16_STRING[5'd22] = CHAR_M;
	assign ESTADO_16_STRING[5'd23] = CHAR_A;
	assign ESTADO_16_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_16_STRING[5'd25] = CHAR_SPACE; 
	assign ESTADO_16_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_16_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_16_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_16_STRING[5'd29] = CHAR_SPACE; 
	assign ESTADO_16_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_16_STRING[5'd31] = CHAR_SPACE;
	
								// Line 1
	assign ESTADO_17_STRING[5'd0] = CHAR_I;  //OPCAO : INSIRA A QUANTIDADE DE PROGRAMAS QUE DEJA EXECUTAR
	assign ESTADO_17_STRING[5'd1] = CHAR_N;
	assign ESTADO_17_STRING[5'd2] = CHAR_S;
	assign ESTADO_17_STRING[5'd3] = CHAR_I;
	assign ESTADO_17_STRING[5'd4] = CHAR_R;
	assign ESTADO_17_STRING[5'd5] = CHAR_A;
	assign ESTADO_17_STRING[5'd6] = CHAR_SPACE;
	assign ESTADO_17_STRING[5'd7] = CHAR_O;
	assign ESTADO_17_STRING[5'd8] = CHAR_SPACE;
	assign ESTADO_17_STRING[5'd9] = CHAR_N;
	assign ESTADO_17_STRING[5'd10] = CHAR_U;
	assign ESTADO_17_STRING[5'd11] = CHAR_M;
	assign ESTADO_17_STRING[5'd12] = CHAR_E;
	assign ESTADO_17_STRING[5'd13] = CHAR_R;
	assign ESTADO_17_STRING[5'd14] = CHAR_O;
	assign ESTADO_17_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_17_STRING[5'd16] = CHAR_D;
	assign ESTADO_17_STRING[5'd17] = CHAR_E; 
   assign ESTADO_17_STRING[5'd18] = CHAR_SPACE; 
	assign ESTADO_17_STRING[5'd19] = CHAR_P;
	assign ESTADO_17_STRING[5'd20] = CHAR_R;
	assign ESTADO_17_STRING[5'd21] = CHAR_O; 
	assign ESTADO_17_STRING[5'd22] = CHAR_G;
	assign ESTADO_17_STRING[5'd23] = CHAR_R;
	assign ESTADO_17_STRING[5'd24] = CHAR_A;
	assign ESTADO_17_STRING[5'd25] = CHAR_M; 
	assign ESTADO_17_STRING[5'd26] = CHAR_A;
	assign ESTADO_17_STRING[5'd27] = CHAR_S;
	assign ESTADO_17_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_17_STRING[5'd29] = CHAR_SPACE; 
	assign ESTADO_17_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_17_STRING[5'd31] = CHAR_SPACE;
	
								// Line 1
	assign ESTADO_18_STRING[5'd0] = CHAR_I;  //insira o nome do programa 
	assign ESTADO_18_STRING[5'd1] = CHAR_N;
	assign ESTADO_18_STRING[5'd2] = CHAR_S;
	assign ESTADO_18_STRING[5'd3] = CHAR_I;
	assign ESTADO_18_STRING[5'd4] = CHAR_R;
	assign ESTADO_18_STRING[5'd5] = CHAR_A;
	assign ESTADO_18_STRING[5'd6] = CHAR_SPACE;
	assign ESTADO_18_STRING[5'd7] = CHAR_O;
	assign ESTADO_18_STRING[5'd8] = CHAR_SPACE;
	assign ESTADO_18_STRING[5'd9] = CHAR_N;
	assign ESTADO_18_STRING[5'd10] = CHAR_O;
	assign ESTADO_18_STRING[5'd11] = CHAR_M;
	assign ESTADO_18_STRING[5'd12] = CHAR_E;
	assign ESTADO_18_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_18_STRING[5'd14] = CHAR_D;
	assign ESTADO_18_STRING[5'd15] = CHAR_O;
	// Line 2
	assign ESTADO_18_STRING[5'd16] = CHAR_P;
	assign ESTADO_18_STRING[5'd17] = CHAR_R; 
	assign ESTADO_18_STRING[5'd18] = CHAR_O;
	assign ESTADO_18_STRING[5'd19] = CHAR_G;
	assign ESTADO_18_STRING[5'd20] = CHAR_R;
	assign ESTADO_18_STRING[5'd21] = CHAR_A; 
	assign ESTADO_18_STRING[5'd22] = CHAR_M;
	assign ESTADO_18_STRING[5'd23] = CHAR_A;
	assign ESTADO_18_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_18_STRING[5'd25] = CHAR_SPACE; 
	assign ESTADO_18_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_18_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_18_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_18_STRING[5'd29] = CHAR_SPACE; 
	assign ESTADO_18_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_18_STRING[5'd31] = CHAR_SPACE;
	
									// Line 1
	assign ESTADO_19_STRING[5'd0] = CHAR_I;  //OPCAO : EXCLUIR PROGRAMA 
	assign ESTADO_19_STRING[5'd1] = CHAR_N;
	assign ESTADO_19_STRING[5'd2] = CHAR_S;
	assign ESTADO_19_STRING[5'd3] = CHAR_I;
	assign ESTADO_19_STRING[5'd4] = CHAR_R;
	assign ESTADO_19_STRING[5'd5] = CHAR_A;
	assign ESTADO_19_STRING[5'd6] = CHAR_SPACE;
	assign ESTADO_19_STRING[5'd7] = CHAR_O;
	assign ESTADO_19_STRING[5'd8] = CHAR_SPACE;
	assign ESTADO_19_STRING[5'd9] = CHAR_P;
	assign ESTADO_19_STRING[5'd10] = CHAR_R;
	assign ESTADO_19_STRING[5'd11] = CHAR_O;
	assign ESTADO_19_STRING[5'd12] = CHAR_G;
	assign ESTADO_19_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_19_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_19_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_19_STRING[5'd16] = CHAR_P;
	assign ESTADO_19_STRING[5'd17] = CHAR_A; 
	assign ESTADO_19_STRING[5'd18] = CHAR_R;
	assign ESTADO_19_STRING[5'd19] = CHAR_A;
	assign ESTADO_19_STRING[5'd20] = CHAR_SPACE;
	assign ESTADO_19_STRING[5'd21] = CHAR_R; 
	assign ESTADO_19_STRING[5'd22] = CHAR_E;
	assign ESTADO_19_STRING[5'd23] = CHAR_N;
	assign ESTADO_19_STRING[5'd24] = CHAR_O;
	assign ESTADO_19_STRING[5'd25] = CHAR_M; 
	assign ESTADO_19_STRING[5'd26] = CHAR_E;
	assign ESTADO_19_STRING[5'd27] = CHAR_A;
	assign ESTADO_19_STRING[5'd28] = CHAR_R;
	assign ESTADO_19_STRING[5'd29] = CHAR_SPACE; 
	assign ESTADO_19_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_19_STRING[5'd31] = CHAR_SPACE;
	
		// Line 1
	assign ESTADO_20_STRING[5'd0] = CHAR_I;  //INSIRA O NOVO NOME 
	assign ESTADO_20_STRING[5'd1] = CHAR_N;
	assign ESTADO_20_STRING[5'd2] = CHAR_S;
	assign ESTADO_20_STRING[5'd3] = CHAR_I;
	assign ESTADO_20_STRING[5'd4] = CHAR_R;
	assign ESTADO_20_STRING[5'd5] = CHAR_A;
	assign ESTADO_20_STRING[5'd6] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd7] = CHAR_O;
	assign ESTADO_20_STRING[5'd8] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd9] = CHAR_N;
	assign ESTADO_20_STRING[5'd10] = CHAR_O;
	assign ESTADO_20_STRING[5'd11] = CHAR_V;
	assign ESTADO_20_STRING[5'd12] = CHAR_O;
	assign ESTADO_20_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_20_STRING[5'd16] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd17] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd18] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd19] = CHAR_N;
	assign ESTADO_20_STRING[5'd20] = CHAR_O;
	assign ESTADO_20_STRING[5'd21] = CHAR_M;
	assign ESTADO_20_STRING[5'd22] = CHAR_E;
	assign ESTADO_20_STRING[5'd23] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_20_STRING[5'd31] = CHAR_SPACE;
	
			// Line 1
	assign ESTADO_21_STRING[5'd0] = CHAR_I;  //INISIRA O PROG A REMOVER
	assign ESTADO_21_STRING[5'd1] = CHAR_N;
	assign ESTADO_21_STRING[5'd2] = CHAR_S;
	assign ESTADO_21_STRING[5'd3] = CHAR_I;
	assign ESTADO_21_STRING[5'd4] = CHAR_R;
	assign ESTADO_21_STRING[5'd5] = CHAR_A;
	assign ESTADO_21_STRING[5'd6] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd7] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd8] = CHAR_O;
	assign ESTADO_21_STRING[5'd9] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd10] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd11] = CHAR_P;
	assign ESTADO_21_STRING[5'd12] = CHAR_R;
	assign ESTADO_21_STRING[5'd13] = CHAR_O;
	assign ESTADO_21_STRING[5'd14] = CHAR_G;
	assign ESTADO_21_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_21_STRING[5'd16] = CHAR_A;
	assign ESTADO_21_STRING[5'd17] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd18] = CHAR_R;
	assign ESTADO_21_STRING[5'd19] = CHAR_E;
	assign ESTADO_21_STRING[5'd20] = CHAR_M;
	assign ESTADO_21_STRING[5'd21] = CHAR_O;
	assign ESTADO_21_STRING[5'd22] = CHAR_V;
	assign ESTADO_21_STRING[5'd23] = CHAR_E;
	assign ESTADO_21_STRING[5'd24] = CHAR_R;
	assign ESTADO_21_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_21_STRING[5'd31] = CHAR_SPACE;
	
			// Line 1
	assign ESTADO_22_STRING[5'd0] = CHAR_P;  //PROGRAMA EXCLUIDO
	assign ESTADO_22_STRING[5'd1] = CHAR_R;
	assign ESTADO_22_STRING[5'd2] = CHAR_O;
	assign ESTADO_22_STRING[5'd3] = CHAR_G;
	assign ESTADO_22_STRING[5'd4] = CHAR_R;
	assign ESTADO_22_STRING[5'd5] = CHAR_A;
	assign ESTADO_22_STRING[5'd6] = CHAR_A;
	assign ESTADO_22_STRING[5'd7] = CHAR_M;
	assign ESTADO_22_STRING[5'd8] = CHAR_A;
	assign ESTADO_22_STRING[5'd9] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd10] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd11] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd12] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_22_STRING[5'd16] = CHAR_E;
	assign ESTADO_22_STRING[5'd17] = CHAR_X;
	assign ESTADO_22_STRING[5'd18] = CHAR_C;
	assign ESTADO_22_STRING[5'd19] = CHAR_L;
	assign ESTADO_22_STRING[5'd20] = CHAR_U;
	assign ESTADO_22_STRING[5'd21] = CHAR_I;
	assign ESTADO_22_STRING[5'd22] = CHAR_D;
	assign ESTADO_22_STRING[5'd23] = CHAR_O;
	assign ESTADO_22_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_22_STRING[5'd31] = CHAR_SPACE;
	
			// Line 1
	assign ESTADO_23_STRING[5'd0] = CHAR_SPACE;  //EXECUTANDO PROGRAMA
	assign ESTADO_23_STRING[5'd1] = CHAR_SPACE;
	assign ESTADO_23_STRING[5'd2] = CHAR_E;
	assign ESTADO_23_STRING[5'd3] = CHAR_X;
	assign ESTADO_23_STRING[5'd4] = CHAR_E;
	assign ESTADO_23_STRING[5'd5] = CHAR_C;
	assign ESTADO_23_STRING[5'd6] = CHAR_U;
	assign ESTADO_23_STRING[5'd7] = CHAR_T;
	assign ESTADO_23_STRING[5'd8] = CHAR_A;
	assign ESTADO_23_STRING[5'd9] = CHAR_N;
	assign ESTADO_23_STRING[5'd10] = CHAR_D;
	assign ESTADO_23_STRING[5'd11] = CHAR_O;
	assign ESTADO_23_STRING[5'd12] = CHAR_SPACE;
	assign ESTADO_23_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_23_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_23_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_23_STRING[5'd16] = CHAR_SPACE;
	assign ESTADO_23_STRING[5'd17] = CHAR_P;
	assign ESTADO_23_STRING[5'd18] = CHAR_R;
	assign ESTADO_23_STRING[5'd19] = CHAR_O;
	assign ESTADO_23_STRING[5'd20] = CHAR_G;
	assign ESTADO_23_STRING[5'd21] = CHAR_R;
	assign ESTADO_23_STRING[5'd22] = CHAR_A;
	assign ESTADO_23_STRING[5'd23] = CHAR_M;
	assign ESTADO_23_STRING[5'd24] = CHAR_A;
	assign ESTADO_23_STRING[5'd25] = CHAR_DOT;
	assign ESTADO_23_STRING[5'd26] = CHAR_DOT;
	assign ESTADO_23_STRING[5'd27] = CHAR_DOT;
	assign ESTADO_23_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_23_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_23_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_23_STRING[5'd31] = CHAR_SPACE;
	
					// Line 1
	assign ESTADO_24_STRING[5'd0] = CHAR_P;  //PROGRAMA NAO ENCONTRADO!
	assign ESTADO_24_STRING[5'd1] = CHAR_R;
	assign ESTADO_24_STRING[5'd2] = CHAR_O;
	assign ESTADO_24_STRING[5'd3] = CHAR_G;
	assign ESTADO_24_STRING[5'd4] = CHAR_R;
	assign ESTADO_24_STRING[5'd5] = CHAR_A;
	assign ESTADO_24_STRING[5'd6] = CHAR_M;
	assign ESTADO_24_STRING[5'd7] = CHAR_A;
	assign ESTADO_24_STRING[5'd8] = CHAR_SPACE;
	assign ESTADO_24_STRING[5'd9] = CHAR_N;
	assign ESTADO_24_STRING[5'd10] = CHAR_A;
	assign ESTADO_24_STRING[5'd11] = CHAR_O;
	assign ESTADO_24_STRING[5'd12] = CHAR_SPACE;
	assign ESTADO_24_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_24_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_24_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_24_STRING[5'd16] = CHAR_E;
	assign ESTADO_24_STRING[5'd17] = CHAR_N;
	assign ESTADO_24_STRING[5'd18] = CHAR_C;
	assign ESTADO_24_STRING[5'd19] = CHAR_O;
	assign ESTADO_24_STRING[5'd20] = CHAR_N;
	assign ESTADO_24_STRING[5'd21] = CHAR_T;
	assign ESTADO_24_STRING[5'd22] = CHAR_R;
	assign ESTADO_24_STRING[5'd23] = CHAR_A;
	assign ESTADO_24_STRING[5'd24] = CHAR_D;
	assign ESTADO_24_STRING[5'd25] = CHAR_O;
	assign ESTADO_24_STRING[5'd26] = CHAR_EXC;
	assign ESTADO_24_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_24_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_24_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_24_STRING[5'd30] = CHAR_SPACE;//EXECUTANDO PROGRAMA
	assign ESTADO_24_STRING[5'd31] = CHAR_SPACE;
	
		assign ESTADO_25_STRING[5'd0] = CHAR_E;  //ENTRADA INVALIDA
	assign ESTADO_25_STRING[5'd1] = CHAR_N;
	assign ESTADO_25_STRING[5'd2] = CHAR_T;
	assign ESTADO_25_STRING[5'd3] = CHAR_R;
	assign ESTADO_25_STRING[5'd4] = CHAR_A;
	assign ESTADO_25_STRING[5'd5] = CHAR_D;
	assign ESTADO_25_STRING[5'd6] = CHAR_A;
	assign ESTADO_25_STRING[5'd7] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd8] = CHAR_I;
	assign ESTADO_25_STRING[5'd9] = CHAR_N;
	assign ESTADO_25_STRING[5'd10] = CHAR_V;
	assign ESTADO_25_STRING[5'd11] = CHAR_A;
	assign ESTADO_25_STRING[5'd12] = CHAR_L;
	assign ESTADO_25_STRING[5'd13] = CHAR_I;
	assign ESTADO_25_STRING[5'd14] = CHAR_D;
	assign ESTADO_25_STRING[5'd15] = CHAR_A;
	// Line 2
	assign ESTADO_25_STRING[5'd16] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd17] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd18] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd19] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd20] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd21] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd22] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd23] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_25_STRING[5'd30] = CHAR_SPACE;//
	assign ESTADO_25_STRING[5'd31] = CHAR_SPACE;
	
	
		// Line 1
	assign ESTADO_26_STRING[5'd0] = CHAR_A;  //ARQUIVO JA EXISTENTE 
	assign ESTADO_26_STRING[5'd1] = CHAR_R;
	assign ESTADO_26_STRING[5'd2] = CHAR_Q;
	assign ESTADO_26_STRING[5'd3] = CHAR_U;
	assign ESTADO_26_STRING[5'd4] = CHAR_I;
	assign ESTADO_26_STRING[5'd5] = CHAR_V;
	assign ESTADO_26_STRING[5'd6] = CHAR_O;
	assign ESTADO_26_STRING[5'd7] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd8] = CHAR_J;
	assign ESTADO_26_STRING[5'd9] = CHAR_A;
	assign ESTADO_26_STRING[5'd10] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd11] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd12] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_26_STRING[5'd16] = CHAR_E; 
	assign ESTADO_26_STRING[5'd17] = CHAR_X;
	assign ESTADO_26_STRING[5'd18] = CHAR_I;
	assign ESTADO_26_STRING[5'd19] = CHAR_S;
	assign ESTADO_26_STRING[5'd20] = CHAR_T;
	assign ESTADO_26_STRING[5'd21] = CHAR_E;
	assign ESTADO_26_STRING[5'd22] = CHAR_N;
	assign ESTADO_26_STRING[5'd23] = CHAR_T;
	assign ESTADO_26_STRING[5'd24] = CHAR_E;
	assign ESTADO_26_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_26_STRING[5'd31] = CHAR_SPACE;
	
			// Line 1
	assign ESTADO_27_STRING[5'd0] = CHAR_C;  //PREEMPCAO
	assign ESTADO_27_STRING[5'd1] = CHAR_O;
	assign ESTADO_27_STRING[5'd2] = CHAR_M;
	assign ESTADO_27_STRING[5'd3] = CHAR_SPACE;
	assign ESTADO_27_STRING[5'd4] = CHAR_P;
	assign ESTADO_27_STRING[5'd5] = CHAR_R;
	assign ESTADO_27_STRING[5'd6] = CHAR_E;
	assign ESTADO_27_STRING[5'd7] = CHAR_E;
	assign ESTADO_27_STRING[5'd8] = CHAR_M;
	assign ESTADO_27_STRING[5'd9] = CHAR_P;
	assign ESTADO_27_STRING[5'd10] = CHAR_C;
	assign ESTADO_27_STRING[5'd11] = CHAR_A;
	assign ESTADO_27_STRING[5'd12] = CHAR_O;
	assign ESTADO_27_STRING[5'd13] = CHAR_INT;
	assign ESTADO_27_STRING[5'd14] = CHAR_SPACE;
	assign ESTADO_27_STRING[5'd15] = CHAR_SPACE;
	// Line 2
	assign ESTADO_27_STRING[5'd16] = CHAR_1; 
	assign ESTADO_27_STRING[5'd17] = CHAR_DOT;
	assign ESTADO_27_STRING[5'd18] = CHAR_SPACE;
	assign ESTADO_27_STRING[5'd19] = CHAR_N;
	assign ESTADO_27_STRING[5'd20] = CHAR_A;
	assign ESTADO_27_STRING[5'd21] = CHAR_O;
	assign ESTADO_27_STRING[5'd22] = CHAR_SPACE;
	assign ESTADO_27_STRING[5'd23] = CHAR_SPACE;
	assign ESTADO_27_STRING[5'd24] = CHAR_2;
	assign ESTADO_27_STRING[5'd25] = CHAR_DOT;
	assign ESTADO_27_STRING[5'd26] = CHAR_S;
	assign ESTADO_27_STRING[5'd27] = CHAR_I;
	assign ESTADO_27_STRING[5'd28] = CHAR_M;
	assign ESTADO_27_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_27_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_27_STRING[5'd31] = CHAR_SPACE;
	
			// Line 1
	assign ESTADO_28_STRING[5'd0] = CHAR_I;  //ARQUIVO JA EXISTENTE 
	assign ESTADO_28_STRING[5'd1] = CHAR_N;
	assign ESTADO_28_STRING[5'd2] = CHAR_S;
	assign ESTADO_28_STRING[5'd3] = CHAR_I;
	assign ESTADO_28_STRING[5'd4] = CHAR_R;
	assign ESTADO_28_STRING[5'd5] = CHAR_A;
	assign ESTADO_28_STRING[5'd6] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd7] = CHAR_O;
	assign ESTADO_28_STRING[5'd8] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd9] = CHAR_N;
	assign ESTADO_28_STRING[5'd10] = CHAR_O;
	assign ESTADO_28_STRING[5'd11] = CHAR_M;
	assign ESTADO_28_STRING[5'd12] = CHAR_E;
	assign ESTADO_28_STRING[5'd13] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd14] = CHAR_D;
	assign ESTADO_28_STRING[5'd15] = CHAR_O;
	// Line 2
	assign ESTADO_28_STRING[5'd16] = CHAR_P; 
	assign ESTADO_28_STRING[5'd17] = CHAR_R;
	assign ESTADO_28_STRING[5'd18] = CHAR_O;
	assign ESTADO_28_STRING[5'd19] = CHAR_G;
	assign ESTADO_28_STRING[5'd20] = CHAR_R;
	assign ESTADO_28_STRING[5'd21] = CHAR_A;
	assign ESTADO_28_STRING[5'd22] = CHAR_M;
	assign ESTADO_28_STRING[5'd23] = CHAR_A;
	assign ESTADO_28_STRING[5'd24] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd25] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd26] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd27] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd28] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd29] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd30] = CHAR_SPACE;
	assign ESTADO_28_STRING[5'd31] = CHAR_SPACE;
	
	always @ (posedge iCLK_50MHZ) begin
		if(FLAG_MUDANCA_LCD) begin
			STATE_LCD_CHANGE <= ESTADO[21:0];
		end
	end
	
	
	always @ (posedge iCLK_50MHZ) begin
		case (STATE_LCD_CHANGE)
			   ESTADO_0: begin
					out<=ESTADO_0_STRING[index];
				end
				ESTADO_1: begin
					out<=ESTADO_1_STRING[index];
				end
				ESTADO_2: begin
					out<=ESTADO_2_STRING[index];
				end
				ESTADO_3: begin
					out<=ESTADO_3_STRING[index];
				end
				ESTADO_4: begin
					out<=ESTADO_4_STRING[index];
				end
				ESTADO_10: begin
					out<=ESTADO_10_STRING[index];
				end
				ESTADO_11: begin
					out<=ESTADO_11_STRING[index];
				end
				ESTADO_13: begin
					out<=ESTADO_13_STRING[index];
				end				
				ESTADO_14: begin
					out<=ESTADO_14_STRING[index];
				end
				ESTADO_15: begin
					out<=ESTADO_15_STRING[index];
				end				
				ESTADO_16: begin
					out<=ESTADO_16_STRING[index];
				end
				ESTADO_17: begin
					out<=ESTADO_17_STRING[index];
				end				
				ESTADO_18: begin
					out<=ESTADO_18_STRING[index];
				end		
				ESTADO_19: begin
					out<=ESTADO_19_STRING[index];
				end		
				ESTADO_20: begin
					out<=ESTADO_20_STRING[index];
				end			
				ESTADO_21: begin				// Line 1

					out<=ESTADO_21_STRING[index];
				end		
				ESTADO_22: begin
					out<=ESTADO_22_STRING[index];
				end	
				ESTADO_23: begin
					out<=ESTADO_23_STRING[index];
				end				
			
				ESTADO_24: begin
					out<=ESTADO_24_STRING[index];
				end 
				
				ESTADO_25: begin
					out<=ESTADO_25_STRING[index];
				end 
				ESTADO_26: begin
					out<=ESTADO_26_STRING[index];
				end 
				ESTADO_27: begin
					out<=ESTADO_27_STRING[index];
				end 
				ESTADO_28: begin
					out<=ESTADO_28_STRING[index];
				end 
				
				default: begin
					out<=0;
				end
		endcase
	end


	
	
endmodule