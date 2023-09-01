module geofence (clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

parameter DATA_IN 	= 0;
parameter CROSS		= 1;
parameter SORT 		= 2;
parameter COMPUTE 	= 3;
parameter DATA_OUT	= 4;

integer i;

reg [2:0] state, next_state;

reg [9:0] buffer_X [0:6];
reg [9:0] buffer_Y [0:6];
reg [2:0] addr;
wire[2:0] addr_b0;
wire[2:0] addr_b1;

reg [2:0] count; 	// for bubble sort count
reg result; 		// single bit do AND every cycle +. detect all 1's sequence

wire signed [10:0] vecter_AX;
wire signed [10:0] vecter_AY;
			 
wire signed [10:0] vecter_BX;
wire signed [10:0] vecter_BY;

wire signed [21:0] A_CROSS_B;

wire signed [20:0] product_A;
wire signed [20:0] product_B;

reg sort_flag;

//assign sort_flag = (state == SORT ||state == CROSS_1) ? 1'b1 : 1'b0; 	// 1 for sort root, 0 for compute
assign addr_b1   = (sort_flag == 1'b1) ? 3'b001 : addr;	// 1 for sort root, 0 for compute
assign addr_b0   = ((sort_flag == 1'b0)  && addr == 3'b110) ? 3'b001 : (addr + 3'b001); // for overflow case => addr : 6 <-> 1
// In the SORT stage, the root of sorted vectors fix to sort_flag=addr_b1=1

assign vecter_AX = buffer_X[addr] - buffer_X[sort_flag];
assign vecter_AY = buffer_Y[addr] - buffer_Y[sort_flag];

assign vecter_BX = buffer_X[addr_b0] - buffer_X[addr_b1];
assign vecter_BY = buffer_Y[addr_b0] - buffer_Y[addr_b1];

assign product_A = vecter_AX*vecter_BY;
assign product_B = vecter_BX*vecter_AY;

assign A_CROSS_B = product_A - product_B;

// FSM
always@(posedge clk or posedge reset) begin
	if(reset) begin
		state <= DATA_IN;
	end
	else begin
		state <= next_state;
	end
end

// next state logic
always@(*) begin
	case(state)  
		DATA_IN  : next_state = (addr  == 3'b110) ? CROSS  : DATA_IN;
		CROSS	 : next_state = (sort_flag == 1'b1) ? SORT : COMPUTE;
		SORT 	 : next_state = CROSS;
		COMPUTE  : next_state = (addr == 3'b101) ? DATA_OUT : CROSS;
		DATA_OUT : next_state = DATA_IN;
		default  : next_state = DATA_IN; 
	endcase
end

// design
always@(posedge clk or posedge reset) begin
	if(reset) begin
		addr    <= 3'b000;
		count  <= 3'b000;
		result <= 1'b1;
		sort_flag <= 1'b1;
		for(i=0 ; i<7 ; i=i+1) begin
			buffer_X[i] <= 10'd0;
			buffer_Y[i] <= 10'd0;
		end
	end
	else begin
		case(state)
			DATA_IN : begin
				addr <= (addr == 3'd6) ? 3'b010 : (addr + 3'b001);
				sort_flag <= 1'b1;
				buffer_X[addr] <= X;
				buffer_Y[addr] <= Y;
			end
			CROSS : begin
				// dealy one cycle
			end
			SORT : begin // bubble sort
				addr    <= (addr == 3'd5-count) ? ((count == 3'd3) ? 3'b001 : 3'b010) : (addr + 3'b001);
				sort_flag <= (count == 3'd3) ? 1'b0 : 1'b1;
				count <= (addr == 3'd5-count) ? (count + 3'b001) : count; 
				if(A_CROSS_B[21] == 1'b0) begin // Vector B is on the left hand side  => exchange
					buffer_X[addr] <= buffer_X[addr+3'd1];
					buffer_Y[addr] <= buffer_Y[addr+3'd1];
					
					buffer_X[addr+3'b001] <= buffer_X[addr];
					buffer_Y[addr+3'b001] <= buffer_Y[addr];
				end
			end
			COMPUTE : begin	
				sort_flag <= 1'b0;
				addr    <= (addr    == 3'b110) ? 3'b000 : (addr    + 3'b001);
				result  <= (A_CROSS_B[21] == 1'b1) ? (1'b1 & result) : (1'b0 & result);
			end
			DATA_OUT : begin
				addr    <= 3'b000;
				sort_flag <= 1'b1;
				count  <= 3'b000;
				result <= 1'b1;
				for(i=0 ; i<7 ; i=i+1) begin
					buffer_X[i] <= 10'd0;
					buffer_Y[i] <= 10'd0;
				end
			end
			default : begin
				addr   <= addr;
				sort_flag <= 1'b1;
				count  <= count;
				result <= 1'b1;
				buffer_X[addr] <= buffer_X[addr];
				buffer_Y[addr] <= buffer_Y[addr];
				buffer_X[addr+3'b001] <= buffer_X[addr+3'b001];
				buffer_Y[addr+3'b001] <= buffer_Y[addr+3'b001];
			end
		endcase
	end
end

// output
assign valid     = (state == DATA_OUT) ? 1'b1 : 1'b0;
assign is_inside = (state == DATA_OUT) && (result == 1'b1) ? 1'b1 : 1'b0;

endmodule

