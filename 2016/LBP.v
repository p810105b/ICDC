`timescale 1ns/10ps
module LBP(clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   		  clk;
input   		  reset;
output reg [13:0] gray_addr;  
output reg        gray_req;   
input   	 	  gray_ready; 
input   	[7:0] gray_data;
output reg [13:0] lbp_addr;   
output reg 	  	  lbp_valid;  
output reg [7:0]  lbp_data;
output reg 	  	  finish;
//====================================================================

parameter Middle    = 0;
parameter LeftUp    = 1;
parameter MidUp     = 2;
parameter RightUp   = 3;
parameter Left 	    = 4;
parameter Right	    = 5;
parameter LeftDown  = 6;
parameter MidDown   = 7;
parameter RightDown = 8;
parameter DONE  	= 9;

reg [3:0]  state, next_state;
reg [13:0] addr_temp;
reg [7:0]  mid_value;


always@(posedge clk or posedge reset) begin
	if(reset) begin
		gray_addr <= 14'd129; // [1:1]
		gray_req  <= 1'd1;
		lbp_addr  <= 14'd129;
		lbp_valid <= 1'd0;
		lbp_data  <= 8'd0;
		finish	  <= 1'd0;
		addr_temp <= 14'd129;
		mid_value <= 8'd0;
		state 	  <= Middle;
	end
	else begin
		if(gray_ready) begin
			state <= next_state;
			case(state)
				Middle: begin
							mid_value <= gray_data;
							gray_addr <= gray_addr - 129; //pixel : [0:0] (0)
						end
				LeftUp: begin
							if(gray_data >= mid_value)
								lbp_data[0] <= 1'b1;
							else
								lbp_data[0] <= 1'b0;
							gray_addr <= gray_addr + 1; //pixel : [0:1] (1)
						end
				MidUp : begin
							if(gray_data >= mid_value)
								lbp_data[1] <= 1'b1;
							else
								lbp_data[1] <= 1'b0;
							gray_addr <= gray_addr + 1; //pixel : [0:2] (2)
						end
				RightUp:begin
							if(gray_data >= mid_value)
								lbp_data[2] <= 1'b1;
							else
								lbp_data[2] <= 1'b0;
							gray_addr <= gray_addr + 126; //pixel : [1:0] (128)
						end
				Left  : begin
							if(gray_data >= mid_value)
								lbp_data[3] <= 1'b1;
							else
								lbp_data[3] <= 1'b0;
							gray_addr <= gray_addr + 2; //pixel : [1:2] (130)
						end		
				Right : begin
							if(gray_data >= mid_value)
								lbp_data[4] <= 1'b1;
							else
								lbp_data[4] <= 1'b0;
							gray_addr <= gray_addr + 126; //pixel : [2:0] (256)
						end	
				LeftDown:begin
							if(gray_data >= mid_value)
								lbp_data[5] <= 1'b1;
							else
								lbp_data[5] <= 1'b0;
							gray_addr <= gray_addr + 1; //pixel : [2:1] (257)
						end			
				MidDown:begin
							if(gray_data >= mid_value)
								lbp_data[6] <= 1'b1;
							else
								lbp_data[6] <= 1'b0;
							gray_addr <= gray_addr + 1; //pixel : [2:2] (258)
						end	
				RightDown:begin
							if(gray_data >= mid_value)
								lbp_data[7] <= 1'b1;
							else
								lbp_data[7] <= 1'b0;
							if (addr_temp < 16255) 
								lbp_valid <= 1'b1;
							lbp_addr <= addr_temp;
						  end	
				DONE  : begin
							if(addr_temp >= 16254) begin 
								gray_req <= 1'b0;
								finish   <= 1'b1;
							end
							else begin
								lbp_valid <= 0;
								lbp_data  <= 0;
								if(addr_temp[6:0] == 7'd126) begin
									addr_temp <= addr_temp + 3;
									gray_addr <= addr_temp + 3;
								end
								else begin
									addr_temp <= addr_temp + 1;
									gray_addr <= addr_temp + 1;
								end
							end	
						end
				default : begin
							lbp_data  <= 8'b0000_0000;
							lbp_addr  <= lbp_addr;
							gray_addr <= gray_addr;
							addr_temp <= addr_temp;
						  end
			endcase
		end
	end
end

always@(*) begin
	case(state)
		Middle    : next_state = LeftUp;
		LeftUp    : next_state = MidUp;
		MidUp     : next_state = RightUp;
		RightUp   : next_state = Left;
		Left      : next_state = Right;
		Right     : next_state = LeftDown;
		LeftDown  : next_state = MidDown;
		MidDown   : next_state = RightDown;
		RightDown : next_state = DONE;
		DONE      : begin
			      		if(addr_temp >= 16254)
			      			next_state = DONE;
			      		else 
			      			next_state = Middle;
			      	end
		default   : next_state = Middle;
	endcase
end

//====================================================================
endmodule