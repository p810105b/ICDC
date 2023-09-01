module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output  Valid );

parameter IDLE 			= 0;
parameter GET_NEXT_PERM = 1;
parameter COUNT_COST    = 2;
parameter DONE		    = 3;

reg [1:0] state, next_state;

reg [2:0] current_perm [0:7];
reg [2:0] next_perm    [0:7];
reg [2:0] temp_array   [0:7];

wire [2:0] replace_point;	  // 0 ~ 7	
wire [2:0] exchanged_point;	  // 0 ~ 7	
wire [2:0] distance;		  // the distance between replace_point and exchanged_point

reg [6:0] cost_array [0:7];   // the costs for each workers
reg [9:0] cost_total;		  // cost_total = cost_array[0] + cost_array[1] + ... + cost_array[7] 
reg [15:0] perm_count;

// Step 1 : exchanged_point
assign replace_point = (current_perm[6] < current_perm[7]) ? 6 :
					   (current_perm[5] < current_perm[6]) ? 5 :
					   (current_perm[4] < current_perm[5]) ? 4 :
					   (current_perm[3] < current_perm[4]) ? 3 :
					   (current_perm[2] < current_perm[3]) ? 2 :
					   (current_perm[1] < current_perm[2]) ? 1 : 0;
	
// Step 2 : the min value that larger than exchanged_point value
always@(*)begin
	if(0 > replace_point && current_perm[0] > current_perm[replace_point])
		temp_array[0] = current_perm[0] - 1;
	else 
		temp_array[0] = 7;
end

always @(*) begin
	if(1 > replace_point && current_perm[1] > current_perm[replace_point])
		temp_array[1] = current_perm[1] - 1;
	else 
		temp_array[1] = 7;
end

always @(*) begin	
	if(2 > replace_point && current_perm[2] > current_perm[replace_point])
		temp_array[2] = current_perm[2] - 1;
	else 
		temp_array[2] = 7;
end

always @(*) begin
	if(3 > replace_point && current_perm[3] > current_perm[replace_point])
		temp_array[3] = current_perm[3] - 1;
	else 
		temp_array[3] = 7;	
end

always @(*) begin		
	if(4 > replace_point && current_perm[4] > current_perm[replace_point])
		temp_array[4] = current_perm[4] - 1;
	else 
		temp_array[4] = 7;
end

always @(*) begin
	if(5 > replace_point && current_perm[5] > current_perm[replace_point])
		temp_array[5] = current_perm[5] - 1;
	else 
		temp_array[5] = 7;
end

always @(*) begin
	if(6 > replace_point && current_perm[6] > current_perm[replace_point])
		temp_array[6] = current_perm[6] - 1;
	else 
		temp_array[6] = 7;
end

always @(*) begin
	if(7 > replace_point && current_perm[7] > current_perm[replace_point])
		temp_array[7] = current_perm[7] - 1;
	else 
		temp_array[7] = 7;
end


assign exchanged_point = (temp_array[6] > temp_array[7]) ? 7 :
						 (temp_array[5] > temp_array[6]) ? 6 :
						 (temp_array[4] > temp_array[5]) ? 5 :
						 (temp_array[3] > temp_array[4]) ? 4 :
						 (temp_array[2] > temp_array[3]) ? 3 :
						 (temp_array[1] > temp_array[2]) ? 2 :
						 (temp_array[0] > temp_array[1]) ? 1 : 0;


// Step 3 : exchanged and flip
assign distance = exchanged_point - replace_point;

always @(*) begin
	if(replace_point == 0) 		
		next_perm[0] = current_perm[exchanged_point];
	else if (replace_point > 0) 
		next_perm[0] = current_perm[0];
end

always @(*) begin
	if(replace_point == 1) 		
		next_perm[1] = current_perm[exchanged_point];
	else if (replace_point > 1) 
		next_perm[1] = current_perm[1];
	else if(distance == 7) 	 	
		next_perm[1] = current_perm[replace_point];
	else 			  			
		next_perm[1] = current_perm[7 + replace_point];
end

always @(*) begin
	if(replace_point == 2) 		
		next_perm[2] = current_perm[exchanged_point];
	else if (replace_point > 2) 
		next_perm[2] = current_perm[2];
	else if(distance == 6) 	 	
		next_perm[2] = current_perm[replace_point];
	else 			  			
		next_perm[2] = current_perm[6 + replace_point];
end


always @(*) begin
	if(replace_point == 3) 		
		next_perm[3] = current_perm[exchanged_point];
	else if (replace_point > 3) 
		next_perm[3] = current_perm[3];
	else if(distance == 5) 	 	
		next_perm[3] = current_perm[replace_point];
	else 			  			
		next_perm[3] = current_perm[5 + replace_point];
end

always @(*) begin
	if(replace_point == 4) 		
		next_perm[4] = current_perm[exchanged_point];
	else if (replace_point > 4) 
		next_perm[4] = current_perm[4];
	else if(distance == 4) 	 	
		next_perm[4] = current_perm[replace_point];
	else 			  			
		next_perm[4] = current_perm[4 + replace_point];
end

always @(*) begin
	if(replace_point == 5) 		
		next_perm[5] = current_perm[exchanged_point];
	else if (replace_point > 5) 
		next_perm[5] = current_perm[5];
	else if(distance == 3) 	 	
		next_perm[5] = current_perm[replace_point];
	else 			  			
		next_perm[5] = current_perm[3 + replace_point];
end

always @(*) begin
	if(replace_point == 6) 		
		next_perm[6] = current_perm[exchanged_point];
	else if(distance == 2) 	 	
		next_perm[6] = current_perm[replace_point];
	else 			  			
		next_perm[6] = current_perm[2 + replace_point];

always @(*) begin
	if(distance == 1) 	 		
		next_perm[7] = current_perm[replace_point];
	else 			  			
		next_perm[7] = current_perm[1 + replace_point];
end

// FSM
always @(posedge CLK or posedge RST) begin
	if(RST) begin
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end


always @(*) begin
	case(state)
		IDLE 		  : next_state = (W == 7) ? GET_NEXT_PERM : IDLE;
		GET_NEXT_PERM : next_state = COUNT_COST;
		COUNT_COST    : next_state = DONE;
		DONE 		  : next_state = IDLE;
	endcase
end


always @(posedge CLK or posedge RST) begin
	if(RST) begin
		current_perm[0] <= 3'd0;
		current_perm[1] <= 3'd1;
		current_perm[2] <= 3'd2;
		current_perm[3] <= 3'd3;
		current_perm[4] <= 3'd4;
		current_perm[5] <= 3'd5;
		current_perm[6] <= 3'd6;
		current_perm[7] <= 3'd7;
	end
	else if(state == GET_NEXT_PERM)begin
		current_perm[0] <= next_perm[0]; 
		current_perm[1] <= next_perm[1]; 
		current_perm[2] <= next_perm[2]; 
		current_perm[3] <= next_perm[3]; 
		current_perm[4] <= next_perm[4]; 
		current_perm[5] <= next_perm[5]; 
		current_perm[6] <= next_perm[6]; 
		current_perm[7] <= next_perm[7];
	end
end

always @(posedge CLK or posedge RST) begin
	if(RST) begin
		W  <= 3'd0;
		J  <= 3'd0;
	end
	else begin
		W <= W + 1;
		J <= current_perm[W];
	end
end

always @(posedge CLK or posedge RST) begin
	if(RST) begin
		cost_array[0] <= 'd0;
		cost_array[1] <= 'd0;
		cost_array[2] <= 'd0;
		cost_array[3] <= 'd0;
		cost_array[4] <= 'd0;
		cost_array[5] <= 'd0;
		cost_array[6] <= 'd0;
		cost_array[7] <= 'd0;
	end
	else begin
		cost_array[W] <= Cost;
	end
end


always @(posedge CLK or posedge RST) begin
	if(RST) begin
		cost_total <= 'd0;
	end
	else if(state == COUNT_COST)begin
		COUNT_COST : cost_total <= cost_array[0] + cost_array[1] + cost_array[2] + cost_array[3] + 
								   cost_array[4] + cost_array[5] + cost_array[6] + cost_array[7];
	end
end


always @(posedge CLK or posedge RST) begin
	if(RST) begin
		MatchCount <= 4'd0;
		MinCost    <= 10'd1023;
	end
	else if(state == DONE)begin
		if(cost_total < MinCost) begin
			MinCost    <= cost_total;
			MatchCount <= 1;
		end
		else if(cost_total == MinCost) begin
			MinCost    <= cost_total;
			MatchCount <= MatchCount + 1;
		end 
	end
end

always @(posedge CLK or posedge RST) begin
	if(RST) begin
		perm_count <= 16'd0;
	end
	else if(state == DONE)begin
		perm_count <= perm_count + 1; 
	end
end

assign Valid = (perm_count == 40320) ? 1 : 0;

endmodule

