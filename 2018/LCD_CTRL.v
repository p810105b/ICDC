module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input 	    clk;
input 	    reset;
input [3:0] cmd;
input       cmd_valid;
input [7:0] IROM_Q;

output reg 		 IROM_rd;
output reg [5:0] IROM_A;
output reg 		 IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg       busy;
output reg       done;

//---------  cmd state  ---------//
parameter cmd_Write 		 = 4'b0000;
parameter cmd_Shift_Up       = 4'b0001;
parameter cmd_Shift_Down     = 4'b0010;
parameter cmd_Shift_Left     = 4'b0011;
parameter cmd_Shift_Right    = 4'b0100;
parameter cmd_Max            = 4'b0101;
parameter cmd_Min            = 4'b0110;
parameter cmd_Average		 = 4'b0111;
parameter cmd_Counter_Rotate = 4'b1000;
parameter cmd_Clock_Rotate   = 4'b1001;
parameter cmd_Mirror_X	     = 4'b1010;
parameter cmd_Mirror_Y   	 = 4'b1011;

//---------  state  ---------//
parameter Read  = 0;
parameter CMD   = 1;
parameter OP    = 2;
parameter Write = 3;

reg [5:0] op_point; // 0~54, 7+8*5+7=54
reg [5:0] counter;  // 0~63
reg [3:0] cmd_reg;
reg [7:0] LCD_CTRL_RAM [0:63];

reg [1:0] state, next_state;

wire [5:0] max_index, min_index;
wire [5:0] op_point_1, op_point_2, op_point_3, op_point_4;
wire [7:0] data_1, data_2, data_3, data_4;
wire [9:0] sum;
wire [7:0] avg;

//---------- FSM ----------//
always@(posedge clk or posedge reset) begin
	if(reset) 
		state <= Read;
	else
		state <= next_state;
end

//------- next state logic -------//
always@(*) begin
	case(state)
		Read  : if(IROM_A == 63) next_state = CMD; else next_state = Read;
		CMD	  : begin
			if(cmd_valid == 1 && cmd == cmd_Write) 
				next_state = Write; 
			else if(cmd_valid == 1 && cmd != cmd_Write)
				next_state = OP; 
			else 
				next_state = CMD;
		end
		OP    : next_state = CMD;
		Write : next_state = Write;
		default : next_state = Read;
	endcase
end


//------- control singal -------//
always@(*) begin
	case(state)
		Read : begin
			IROM_rd    = 1'd1;
			IRAM_valid = 1'd0;
			busy       = 1'd1;
		end
		CMD : begin
			IROM_rd    = 1'd0;
			IRAM_valid = 1'd0;
			busy       = 1'd0;
		end
		OP : begin
			IROM_rd    = 1'd0;
			IRAM_valid = 1'd0;
			busy       = 1'd1;
		end
		Write : begin
			IROM_rd    = 1'd0;
			IRAM_valid = 1'd1;
			busy       = 1'd1;
		end
	endcase
end


integer i;
//------- Read IROM_Q -------//
always@(posedge clk or posedge reset) begin
	if(reset) begin
		IROM_A <= 6'd0;
		for(i = 0 ; i < 64 ; i = i + 1) begin
			LCD_CTRL_RAM[i] <= 8'd0;
		end
    end
	else if(state == Read) begin
		IROM_A 			     <= IROM_A + 1;
		LCD_CTRL_RAM[IROM_A] <= IROM_Q;
	end
end


//------- CMD -------//
always@(posedge clk or posedge reset) begin
	if(reset) 
		cmd_reg  <= 4'bzzzz;
	else if(cmd_valid) 
		cmd_reg <= cmd; 
end


//------- OP -------//
always@(posedge clk or posedge reset) begin	
	if(reset)
		op_point <= 6'd27; // 3*8+3=27
	else if(state == CMD) begin
		case(cmd_reg)
			cmd_Shift_Up : begin 
				if(op_point > 7) 
					op_point <= op_point - 8; 
				else 
					op_point <= op_point;
			end
			cmd_Shift_Down : begin 
				if(op_point < 48) // 7+8*5=47
					op_point <= op_point + 8; 
				else 
					op_point <= op_point;
			end   
			cmd_Shift_Left : begin 
				if(op_point == 6'h0 || op_point == 6'h8 || op_point == 6'h10 || op_point == 6'h18 || op_point == 6'h20 || op_point == 6'h28 || op_point == 6'h30 || op_point == 6'h38) 
					op_point <= op_point; 
				else 
					op_point <= op_point - 1;
			end    
			cmd_Shift_Right : begin 
				if(op_point == 6'h6 || op_point == 6'he || op_point == 6'h16 || op_point == 6'h1e || op_point == 6'h26 || op_point == 6'h2e || op_point == 6'h36 || op_point == 6'h3e) 
					op_point <= op_point; 
				else 
					op_point <= op_point + 1;
			end   
			cmd_Max : begin 
				LCD_CTRL_RAM[op_point_1] <= LCD_CTRL_RAM[max_index];
				LCD_CTRL_RAM[op_point_2] <= LCD_CTRL_RAM[max_index];
				LCD_CTRL_RAM[op_point_3] <= LCD_CTRL_RAM[max_index];
				LCD_CTRL_RAM[op_point_4] <= LCD_CTRL_RAM[max_index];
			end             
			cmd_Min : begin 
				LCD_CTRL_RAM[op_point_1] <= LCD_CTRL_RAM[min_index];
				LCD_CTRL_RAM[op_point_2] <= LCD_CTRL_RAM[min_index];
				LCD_CTRL_RAM[op_point_3] <= LCD_CTRL_RAM[min_index];
				LCD_CTRL_RAM[op_point_4] <= LCD_CTRL_RAM[min_index];
			end           
			cmd_Average : begin 
				LCD_CTRL_RAM[op_point_1] <= avg;
				LCD_CTRL_RAM[op_point_2] <= avg;
				LCD_CTRL_RAM[op_point_3] <= avg;
				LCD_CTRL_RAM[op_point_4] <= avg;
			end 
			cmd_Counter_Rotate : begin 
				LCD_CTRL_RAM[op_point_1] <= LCD_CTRL_RAM[op_point_2];			// 1 2
				LCD_CTRL_RAM[op_point_2] <= LCD_CTRL_RAM[op_point_3];			// 4 3
				LCD_CTRL_RAM[op_point_3] <= LCD_CTRL_RAM[op_point_4];		
				LCD_CTRL_RAM[op_point_4] <= LCD_CTRL_RAM[op_point_1];
			end 
			cmd_Clock_Rotate : begin 
				LCD_CTRL_RAM[op_point_1] <= LCD_CTRL_RAM[op_point_4];
				LCD_CTRL_RAM[op_point_2] <= LCD_CTRL_RAM[op_point_1];
				LCD_CTRL_RAM[op_point_3] <= LCD_CTRL_RAM[op_point_2];
				LCD_CTRL_RAM[op_point_4] <= LCD_CTRL_RAM[op_point_3];
			end   
			cmd_Mirror_X : begin 
				LCD_CTRL_RAM[op_point_1] <= LCD_CTRL_RAM[op_point_4];
				LCD_CTRL_RAM[op_point_2] <= LCD_CTRL_RAM[op_point_3];
				LCD_CTRL_RAM[op_point_3] <= LCD_CTRL_RAM[op_point_2];
				LCD_CTRL_RAM[op_point_4] <= LCD_CTRL_RAM[op_point_1];
			end 	    
			cmd_Mirror_Y : begin 
				LCD_CTRL_RAM[op_point_1] <= LCD_CTRL_RAM[op_point_2];
				LCD_CTRL_RAM[op_point_2] <= LCD_CTRL_RAM[op_point_1];
				LCD_CTRL_RAM[op_point_3] <= LCD_CTRL_RAM[op_point_4];
				LCD_CTRL_RAM[op_point_4] <= LCD_CTRL_RAM[op_point_3];
			end    
			default : begin
				op_point <= op_point;
				LCD_CTRL_RAM[op_point_1] <= LCD_CTRL_RAM[op_point_1];
				LCD_CTRL_RAM[op_point_2] <= LCD_CTRL_RAM[op_point_2];
				LCD_CTRL_RAM[op_point_3] <= LCD_CTRL_RAM[op_point_3];
				LCD_CTRL_RAM[op_point_4] <= LCD_CTRL_RAM[op_point_4];
			end
		endcase
	end
end

assign op_point_1 = op_point;
assign op_point_2 = op_point + 1;
assign op_point_3 = op_point + 9;
assign op_point_4 = op_point + 8;

assign data_1 = LCD_CTRL_RAM[op_point_1];
assign data_2 = LCD_CTRL_RAM[op_point_2];
assign data_3 = LCD_CTRL_RAM[op_point_3];
assign data_4 = LCD_CTRL_RAM[op_point_4];

assign max_index = ((data_1 >= data_2) && (data_1 >= data_3) && (data_1 >= data_4)) ? op_point_1 :
				   ((data_2 >= data_1) && (data_2 >= data_3) && (data_2 >= data_4)) ? op_point_2 :
				   ((data_3 >= data_1) && (data_3 >= data_2) && (data_3 >= data_4)) ? op_point_3 : op_point_4;

assign min_index = ((data_1 <= data_2) && (data_1 <= data_3) && (data_1 <= data_4)) ? op_point_1 :
				   ((data_2 <= data_1) && (data_2 <= data_3) && (data_2 <= data_4)) ? op_point_2 :
				   ((data_3 <= data_1) && (data_3 <= data_2) && (data_3 <= data_4)) ? op_point_3 : op_point_4;

assign sum = data_1 + data_2 + data_3 + data_4;
assign avg = sum >> 2;

//------- write into IRAM_D -------//
always@(posedge clk or posedge reset)begin
	if(reset) begin 
		IRAM_D  <= 8'd0;
		IRAM_A  <= 6'd0;
		counter <= 6'd0;
	end
	else if(state == Write && IRAM_valid == 1) begin
		counter <= (counter == 63)? 63 : counter + 1;
		IRAM_D  <= LCD_CTRL_RAM[counter];
		IRAM_A  <= counter;
	end
end
 

//------- done-------//
always@(posedge clk or posedge reset) begin
	if(state == Write && IRAM_A == 63) 
		done <= 1'd1;
	else 
		done <= 1'd0;
end



endmodule



