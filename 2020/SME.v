module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;


localparam READ_DATA 	= 3'd0;
localparam SEARCH_HEAD 	= 3'd1;
localparam COMPARE_BODY = 3'd2;
localparam DATA_OUT 	= 3'd3;

reg [2:0] state, next_state;

reg [7:0] string_buffer  [0:31];
reg [7:0] pattern_buffer [0:7];

reg [4:0] string_length;
reg [2:0] pattern_length;
reg [4:0] string_head_addr;
reg [2:0] pattern_addr;
reg [2:0] match_count;

wire [4:0] string_addr;
wire head_sign;
wire tail_sign;
wire addr_match;
wire compare_done;
wire match_flag;

assign string_addr = match_count + string_head_addr;
assign head_sign = (pattern_buffer[0] 			   == 8'd94) ? 1'b1 : 1'b0;
assign tail_sign = (pattern_buffer[pattern_length] == 8'd36) ? 1'b1 : 1'b0;
assign addr_match = (string_buffer[string_addr] == pattern_buffer[pattern_addr]) ? 1'b1 : 1'b0;
assign compare_done = (string_length - string_addr < pattern_length) ? 1'b1 : 1'b0;
assign match_flag = (pattern_addr == pattern_length - 3'd1) && addr_match ? 1'b1 : 1'b0;

// FSM
always@(posedge clk or posedge reset) begin
	if(reset) begin
		state <= READ_DATA;
	end
	else begin
		state <= next_state;
	end
end

// next state logic
always@(*) begin
	case(state)
		READ_DATA 	: next_state = (isstring || ispattern) ? READ_DATA : SEARCH_HEAD;	
		SEARCH_HEAD : next_state = compare_done ? DATA_OUT : (addr_match ? COMPARE_BODY : SEARCH_HEAD);	
		COMPARE_BODY: next_state = (match_flag) ? DATA_OUT : (addr_match ? COMPARE_BODY : SEARCH_HEAD);	
		DATA_OUT 	: next_state = READ_DATA;
		default   	: next_state = READ_DATA;
	endcase
end

// design
integer i;

always@(posedge clk or posedge reset) begin
	if(reset) begin
		for(i=0; i<32; i=i+1) begin
			string_buffer[i] <= 8'd0;
		end
		string_length <= 5'd0;
	end
	else if(isstring)begin
		string_buffer[string_addr] <= chardata;
		string_length <= string_length + 5'd1;
	end
	/*else if(state == DATA_OUT) begin
		for(i=0; i<32; i=i+1) begin
			string_buffer[i] <= 8'd0;
		end
		string_length <= 5'd0;
	end*/
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		string_head_addr <= 5'd0;
	end
	else if(isstring)begin
		string_head_addr <= string_head_addr + 5'd1;
	end
	else if(state == SEARCH_HEAD) begin
		string_head_addr <= string_head_addr + 5'd1;
	end
	else if(state == COMPARE_BODY) begin
		string_head_addr <= string_head_addr;
	end
	else begin
		string_head_addr <= 5'd0;
	end
end


always@(posedge clk or posedge reset) begin
	if(reset) begin
		for(i=0; i<8; i=i+1) begin
			pattern_buffer[i] <= 8'd0;
		end
		pattern_length <= 3'd0;
	end
	else if(ispattern)begin
		pattern_buffer[pattern_addr] <= chardata;
		pattern_length <= pattern_length + 3'd1;
	end
	else if(match_flag || compare_done) begin
		for(i=0; i<32; i=i+1) begin
			pattern_buffer[i] <= 8'd0;
		end
		pattern_length <= 3'd0;
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		pattern_addr <= 3'd0;
	end
	else if(ispattern)begin
		pattern_addr <= pattern_addr + 3'd1;
	end
	else if(state == SEARCH_HEAD) begin
		pattern_addr <= addr_match ? (head_sign ? 3'd2 : 3'd1) : (head_sign ? 3'd1 : 3'd0);
	end
	else if(state == COMPARE_BODY) begin
		pattern_addr <= pattern_addr + 3'd1;
	end
	else begin
		pattern_addr <= 3'd0;
	end
end

always@(posedge clk or posedge reset) begin
	if(reset) begin
		match_count <= 3'd0;
	end
	else if(state == SEARCH_HEAD) begin
		match_count <= 3'd0;
	end
	else if(state == COMPARE_BODY) begin
		match_count <= match_count + 3'd1;
	end
	else begin
		match_count <= 3'd0;
	end
end


reg match_reg;

assign valid 		= (state == DATA_OUT) ? 1'b1 : 1'b0;
assign match 		= (state == DATA_OUT) ? match_reg : 1'b0;
assign match_index 	= (state == DATA_OUT) ? string_head_addr-5'd1 : 5'd0;

always@(posedge clk or posedge reset) begin
	if(reset) begin
		match_reg <= 1'b0;
	end
	else begin
		match_reg <= match_flag;
	end
end



// NOT FINISH






endmodule
