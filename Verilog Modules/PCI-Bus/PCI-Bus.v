module PCIBus(Frame_out, TRDY_out, IRDY_out, selDev_out, Frame_in, TRDY_in, IRDY_in ,selDev_in);

output reg Frame_out, TRDY_out, IRDY_out, selDev_out;
input Frame_in, TRDY_in, IRDY_in, selDev_in;

always @(Frame_in, TRDY_in, IRDY_in ,selDev_in)
begin
	if (Frame_in 	=== 1'bx) 	Frame_out 	<= 1'bz;		else if (Frame_in  === 1'bz) 	Frame_out	<= 1;
	if (TRDY_in 	=== 1'bx) 	TRDY_out	 	<= 1'bz;		else if (TRDY_in   === 1'bz)	TRDY_out		<= 1;
	if (IRDY_in		=== 1'bx)	IRDY_out  	<= 1'bz;		else if (IRDY_in   === 1'bz)	IRDY_out 	<= 1;
	if (selDev_in 	=== 1'bx) 	selDev_out	<= 1'bz;		else if (selDev_in === 1'bz)	selDev_out 	<= 1;
end

endmodule
