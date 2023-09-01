module DT(
	input 				clk, 
	input				reset,
	output	reg			done ,
	output	reg			sti_rd ,
	output	reg [9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg			res_wr ,
	output	reg			res_rd ,
	output	reg [13:0]	res_addr ,
	output	reg [7:0]	res_do,
	input		[7:0]	res_di
	);


reg [1:0] state, next_state;
reg [3:0] sub_state, next_sub_state;
reg [3:0] counter;

parameter READ = 0;
parameter FOR  = 1;
parameter BACK = 2;
parameter DONE = 3;

parameter Middle    = 4;
parameter NW        = 5;
parameter N         = 6;
parameter NE        = 7;
// parameter W      = 8;
parameter DONE_For  = 8;
			     
parameter SE        = 9;
parameter S         = 10;
parameter SW        = 11;
// parameter E      = 12;
parameter DONE_BACK = 12;


always@(posedge clk or negedge reset) begin
	if(!reset) begin
		done 	   <= 1'd0;
		sti_rd     <= 1'd1;
		sti_addr   <= 10'd0;
		res_wr     <= 1'd1;
		res_addr   <= 14'd16383;
		res_do     <= 8'd0;
		counter    <= 4'd0;
		next_state <= READ;
		next_sub_state <= Middle;
	end
	else begin
		state 	  <= next_state;
		sub_state <= next_sub_state;
		case(state)
			READ : begin
					res_do   <= sti_di[4'd15 - counter];
					res_addr <= res_addr + 14'd1;
					counter  <= counter + 4'd1;
					if(counter == 4'd15) begin
						sti_addr <= sti_addr + 10'd1;
						if(sti_addr == 10'd1023) begin
							res_addr <= 14'd129;
						end
					end
			end
			FOR : begin
					case(sub_state)
						Middle : begin
							if(res_di == 0) begin
								res_addr <= res_addr + 14'd1;
								res_do   <= 8'd0;
							end
							else begin
								res_addr <= res_addr - 14'd129;
							end
						end
						NW : begin
								res_addr <= res_addr + 14'd1;
								res_do   <= (res_di < res_do)? res_di : res_do;
						end
						N : begin
								res_addr <= res_addr + 14'd1;
								res_do   <= (res_di < res_do)? res_di : res_do;
						end
						NE : begin
								res_addr <= res_addr + 14'd127; // return to Middle
								res_do   <= (res_di < res_do)? res_di + 1 : res_do + 1;
						end
						DONE_For : begin
								res_addr <= res_addr + 14'd1; // return to next Middle
						end
					endcase	
			end
			BACK : begin
					case(sub_state)
						Middle : begin
							if(res_di == 0) begin
								res_addr <= res_addr - 14'd1;
								res_do   <= 8'd0;
							end
							else begin
								res_addr <= res_addr + 14'd129;
								res_do   <= (res_di < res_do + 1) ? res_di : res_do + 8'd1;
							end
						end
						SE : begin
								res_addr <= res_addr - 14'd1;
								res_do   <= (res_di + 1 < res_do) ? res_di + 8'd1 : res_do;
						end
						S : begin
								res_addr <= res_addr - 14'd1;
								res_do   <= (res_di + 1 < res_do) ? res_di + 8'd1 : res_do;
						end
						SW : begin
								res_addr <= res_addr - 14'd127; // return to Middle
								res_do   <= (res_di + 1 < res_do) ? res_di + 8'd1 : res_do;
						end
						DONE_BACK : begin
								res_addr <= res_addr - 14'd1; // return to next Middle
						end
					endcase	
			end
		endcase
	end
end


always@(*) begin
	case(state)
		READ : begin
				if(sti_addr == 1023 && counter == 4'd15) begin
					next_state = FOR;
					res_wr     = 1'd0;
					res_rd     = 1'b1;
				end		
		end
		FOR  : begin
				if(res_addr == 14'd16255)
					next_state = BACK;
				res_wr = (sub_state == DONE_For) ? 1 : 0; 
		end
		BACK : begin
				if(res_addr == 14'd128)
					next_state = DONE;
				res_wr = (sub_state == DONE_BACK) ? 1 : 0; 	
		end
	endcase
end


always@(*) begin
	case(state)
		FOR  : begin
				case(sub_state)
					Middle   : if(res_di != 0) next_sub_state = NW; else next_sub_state = Middle;
					NW 		 : next_sub_state  = N;
					N 		 : next_sub_state  = NE;
					NE 	     : next_sub_state  = DONE_For;
					DONE_For : next_sub_state  = Middle;
					default  : next_sub_state  = Middle;
				endcase
		end		
		BACK : begin
				case(sub_state)
						Middle    : if(res_di != 0) next_sub_state = SE; else next_sub_state = Middle;
						SE        : next_sub_state = S;
						S         : next_sub_state = SW;
						SW 		  : next_sub_state = DONE_BACK;
						DONE_BACK : next_sub_state = Middle;
						default   : next_sub_state = Middle;
				endcase
		end
		DONE : done = 1;
	endcase
end

endmodule
