
`timescale 1ns/10ps

module  CONV(
	input						clk,
	input						reset,
	output	reg					busy,	
	input						ready,	
			
	output			   [11:0]	iaddr,
	input			   [19:0]	idata,	
					   
	output	reg	 	   			cwr,
	output	reg 	   [11:0]	caddr_wr,
	output	reg signed [19:0] 	cdata_wr,
	
	output	reg 				crd,
	output			   [11:0] 	caddr_rd,
	input	 		   [19:0]	cdata_rd,
					   
	output	reg 	   [2:0]	csel
	);


parameter Kernel_00 = 20'h0A89E, Kernel_01 = 20'h092D5, Kernel_02 = 20'h06D43;
parameter Kernel_10 = 20'h01004, Kernel_11 = 20'hF8F71, Kernel_12 = 20'hF6E54;
parameter Kernel_20 = 20'hFA6D7, Kernel_21 = 20'hFC834, Kernel_22 = 20'hFAC19;
parameter Bias 		= 40'h001310_0000;


localparam IDLE       = 3'd0;
localparam READ_MID	  = 3'd1;
localparam READ_SUR   = 3'd2;
localparam WRITE_MEM0 = 3'd3;
localparam READ_MEM0  = 3'd4;
localparam POOLING    = 3'd5;
localparam WRITE_MEM1 = 3'd6;
localparam DONE       = 3'd7;

reg [2:0] state, next_state;
reg [11:0] middel_pix;
reg [3:0] count;

// FSM
always@(posedge clk or posedge reset) begin
	if(reset) begin
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end

wire read_sur_done;
wire conv_done;
wire pooling_done;
wire globl_done;
assign read_sur_done = (count == 3'd7) ? 1'b1 : 1'b0;
assign conv_done = (middel_pix == 12'd4095) ? 1'b1 : 1'b0;
assign pooling_done = (count == 3'd2) ? 1'b1 : 1'b0;
assign globl_done = (middel_pix == 12'd4030) ? 1'b1 : 1'b0;

// next state logic
always@(*) begin
	case(state)
		IDLE     	: next_state = READ_MID;
		READ_MID 	: next_state = READ_SUR;
		READ_SUR 	: next_state = read_sur_done  ? WRITE_MEM0 : READ_SUR;
		WRITE_MEM0  : next_state = conv_done 	  ? READ_MEM0  : READ_MID;
		READ_MEM0   : next_state = POOLING;
		POOLING     : next_state = pooling_done   ? WRITE_MEM1 : POOLING;
		WRITE_MEM1  : next_state = globl_done	  ? DONE	   : READ_MEM0;
		DONE        : next_state = DONE;
		default     : next_state = IDLE;
	endcase
end

// design 
always@(posedge clk or posedge reset) begin
	if(reset)
		busy <= 1'b0;
	else if(state == DONE)
		busy <= 1'b0;			
	else if(busy == 1'b1)
		busy <= 1'b1;	
	else if(ready == 1'b1)
		busy <= 1'b1;
	else 
		busy <= 1'b0;
end

wire left_bound_flag;
wire right_bound_flag;
wire top_bound_flag;
wire bottom_bound_flag;

wire [12:0] mid;
wire [12:0] top;
wire [12:0] left;
wire [12:0] right;
wire [12:0] bottom;
	   
wire [12:0] left_top;
wire [12:0] right_top;
wire [12:0] left_bottom;
wire [12:0] right_bottom;

assign left_bound_flag   = (mid % 'd64 == 'd0)  ? 1'b1 : 1'b0;
assign right_bound_flag  = (mid % 'd64 == 'd63) ? 1'b1 : 1'b0;
assign top_bound_flag    = (mid < 'd64) 		? 1'b1 : 1'b0;
assign bottom_bound_flag = (mid > 'd4031) 		? 1'b1 : 1'b0;

assign mid 			= {0, middel_pix};
assign top 			= top_bound_flag 	? 13'd4096 : (mid - 13'd64);
assign left 		= left_bound_flag 	? 13'd4096 : (mid - 13'd1);
assign right 		= right_bound_flag 	? 13'd4096 : (mid + 13'd1);
assign bottom 		= bottom_bound_flag ? 13'd4096 : (mid + 13'd64);

assign left_top 	= (left_bound_flag 	|| top_bound_flag	) ? 13'd4096 : (mid - 13'd65);
assign right_top 	= (right_bound_flag || top_bound_flag	) ? 13'd4096 : (mid - 13'd63);
assign left_bottom 	= (left_bound_flag 	|| bottom_bound_flag) ? 13'd4096 : (mid + 13'd63);
assign right_bottom	= (right_bound_flag || bottom_bound_flag) ? 13'd4096 : (mid + 13'd65);

reg [12:0] scan_addr;
always@(*) begin
	if(state == READ_MID || state == READ_MEM0) begin
		scan_addr = mid;
	end	
	else if(state == READ_SUR)begin
		case(count)
			3'd0 : scan_addr = top;
			3'd1 : scan_addr = left;
			3'd2 : scan_addr = right;
			3'd3 : scan_addr = bottom;
			3'd4 : scan_addr = left_top;
			3'd5 : scan_addr = right_top;
			3'd6 : scan_addr = left_bottom;
			3'd7 : scan_addr = right_bottom;
			default : scan_addr = mid;
		endcase
	end
	else if(state == POOLING)begin
		case(count)
			3'd0 : scan_addr = right;
			3'd1 : scan_addr = bottom;
			3'd2 : scan_addr = right_bottom;
			default : scan_addr = mid;
		endcase
	end
	else begin
		scan_addr = 13'd0;
	end
end

assign iaddr = scan_addr[11:0];

wire signed [19:0] ifmap;
reg  signed [19:0] filter;
reg  signed [39:0] psum_reg; 
assign ifmap  = (scan_addr[12] == 1'b1) ? 20'd0 : idata;

always@(*) begin
	if(state == READ_MID)
		filter = Kernel_11;
	else if(state == READ_SUR) begin
		case(count)
			3'd0 : filter = Kernel_01;
			3'd1 : filter = Kernel_10;
			3'd2 : filter = Kernel_12;
			3'd3 : filter = Kernel_21;
			3'd4 : filter = Kernel_00;
			3'd5 : filter = Kernel_02;
			3'd6 : filter = Kernel_20;
			3'd7 : filter = Kernel_22;
			default : filter = Kernel_00;
		endcase
	end
end

always@(posedge clk or posedge reset) begin
	if(reset)
		count <= 3'd0;
	else if(state == READ_SUR)begin
		count <= (count == 3'd7) ? count : (count + 3'd1);
	end
	else if(state == WRITE_MEM0)begin
		count <= 3'd0;
	end
	else if(state == POOLING)begin
		count <= (count == 3'd2) ? count : (count + 3'd1);
	end
	else if(state == WRITE_MEM1)begin
		count <= 3'd0;
	end
end

always@(posedge clk or posedge reset) begin
	if(reset)
		middel_pix <= 12'd0;
	else if(state == WRITE_MEM0) begin
		middel_pix <= middel_pix + 12'd1;
	end
	else if(state == WRITE_MEM1) begin
		middel_pix <= (middel_pix % 'd64) == 'd62 ? (middel_pix + 12'd66) : (middel_pix + 12'd2);
	end
end

wire signed [38:0] psum; // 1,3,16  1,6,32 : 38bits
assign psum = ifmap * filter;

always@(posedge clk or posedge reset) begin
	if(reset)
		psum_reg <= 20'd0;
	else if(state == READ_MID || state == READ_SUR)begin
		psum_reg <= psum_reg + psum;
	end
	else if(state == WRITE_MEM0) begin
		psum_reg <= 20'd0;
	end
end

wire signed [39:0] psum_bias;
wire signed [39:0] psum_out;
wire signed [19:0] psum_round;
assign psum_bias  = psum_reg + Bias;
assign psum_out   = (psum_bias > 0) ? psum_bias : 40'd0;
assign psum_round = (psum_out[15]) ? (psum_out[35:16] + 16'd1) : psum_out[35:16];
reg signed [19:0] pooling_result;

// Layer0
always@(*) begin
	case(state)
		WRITE_MEM0 : cdata_wr = psum_round;
		WRITE_MEM1 : cdata_wr = pooling_result;
		default    : cdata_wr = 20'd0;
	endcase
end

always@(*) begin
	case(state)
		WRITE_MEM0 : csel = 3'b001;
		READ_MEM0  : csel = 3'b001;
		POOLING	   : csel = 3'b001;
		WRITE_MEM1 : csel = 3'b011;
		default    : csel = 3'b000;
	endcase
end

always@(*) begin
	case(state)
		WRITE_MEM0 : cwr = 1'b1;
		WRITE_MEM1 : cwr = 1'b1;
		default    : cwr = 1'b0;
	endcase
end

always@(posedge clk or posedge reset) begin
	if(reset)
		caddr_wr <= 12'd0;
	else if(state == WRITE_MEM0 || state == WRITE_MEM1)begin
		caddr_wr <= caddr_wr + 12'd1;
	end
end

// Layer1

assign caddr_rd = scan_addr [11:0];

always@(*) begin
	case(state)
		READ_MEM0 : crd = 1'b1;
		POOLING	  : crd = 1'b1;
		default   : crd = 1'b0;
	endcase
end

always@(posedge clk or posedge reset) begin
	if(reset)
		pooling_result <= 20'd0;
	else if(state == POOLING || state == READ_MEM0)begin
		pooling_result <= (cdata_rd > pooling_result) ? cdata_rd : pooling_result;
	end
	else if(state == WRITE_MEM1)begin
		pooling_result <= 20'd0;
	end
end


endmodule

