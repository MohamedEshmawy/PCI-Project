`timescale 1ns / 1ps
/*
assign a wire to multiple registers
in the inital block, first, assign only 1 reg to a value and make the others high impdance
then, try to assign 2 registers values and see what happen to the wire --> the wire becomes an x (dont care)
*/

module InoutTest();

wire testWire;
reg A, B, C;

assign testWire = A;
assign testWire = B;
assign testWire = C;

initial
begin
	$monitor("wire =%b	A=%b	B=%b	C=%b", testWire, A, B, C);
	A =1'bz;
	B =1'bz;
	C =1'bz;
	
	#10
	A=1;
	
	#10
	A=1'bz;
	B=0;
	
	#10
	B=1'bz;
	C=1;
	
	#10
	
	$display ("\n Conflicts Time \n");
	A=1;
	B=0;
	
	#10
	
	A=0;
end

endmodule
