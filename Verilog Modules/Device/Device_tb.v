`timescale 1ns / 1ps

module MasterDevice_tb();


wire Frame, TRDY, IRDY, cmd;
wire [31:0] addr_data;

reg clk, gnt;
reg force_req;
reg test_cmd;
reg [4:0]AddressToContact;
reg [0:31] dataToWrite;
reg [3:0] dataPhaseCount;

reg Frame_reg, TRDY_reg, IRDY_reg, cmd_reg;

assign Frame 	= Frame_reg;
assign TRDY 	= TRDY_reg;
assign IRDY		= IRDY_reg;
assign cmd 		= cmd_reg;

always @(Frame, TRDY, IRDY ,selDev)
begin
	if (Frame === 1'bx) 	Frame_reg <= 1'bz;	else if (Frame === 1'bz) Frame_reg	<= 1;
	if (TRDY === 1'bx) 	TRDY_reg	 <= 1'bz;	else if (TRDY === 1'bz)	TRDY_reg		<= 1;
	if (IRDY === 1'bx)		IRDY_reg  <= 1'bz;	else if (IRDY === 1'bz)	IRDY_reg 	<= 1;
	if (cmd === 1'bx) 		cmd_reg 	 <= 1'bz;	else if (cmd === 1'bz)	cmd_reg 		<= 1;
end

always
begin
#10 clk = ~clk;
end

initial
begin
	gnt 	<= 1;
	clk	<= 0;
	
	force_req 			<= 1;
	test_cmd				<= 0;
	AddressToContact 	<= 5'b10111;
	dataToWrite 		<= 8'hAAAA_AAAA;
	dataPhaseCount		<= 3;
	
	#25 //assert force_req for 1 posedge cycle so number of transactions is 1
	
	force_req 	<= 0;
	TRDY_reg		<= 0;
	#10
	
	gnt			<= 0;
	wait (Frame == 0)	repeat(1) @(negedge clk) gnt <= 1; 
end


Device Master (dataPhaseCount,force_req,req,gnt,selDev,addr_data,AddressToContact,cmd,test_cmd,Frame,TRDY,IRDY,clk ,slotSel ,dataToWrite);

endmodule


module TargetDevice_tb();


wire Frame, TRDY, IRDY, cmd;
wire [31:0] addr_data;

reg clk, gnt;
reg force_req;
reg test_cmd;
reg [4:0]AddressToContact;
reg [0:31] dataToWrite;
reg [3:0] dataPhaseCount;

reg Frame_reg, TRDY_reg, IRDY_reg, cmd_reg;

assign Frame 	= Frame_reg;
assign TRDY 	= TRDY_reg;
assign IRDY		= IRDY_reg;
assign cmd 		= cmd_reg;

always @(Frame, TRDY, IRDY ,selDev)
begin
	if (Frame === 1'bx) 	Frame_reg <= 1'bz;	else if (Frame === 1'bz) Frame_reg	<= 1;
	if (TRDY === 1'bx) 	TRDY_reg	 <= 1'bz;	else if (TRDY === 1'bz)	TRDY_reg		<= 1;
	if (IRDY === 1'bx)		IRDY_reg  <= 1'bz;	else if (IRDY === 1'bz)	IRDY_reg 	<= 1;
	if (cmd === 1'bx) 		cmd_reg 	 <= 1'bz;	else if (cmd === 1'bz)	cmd_reg 		<= 1;
end

always
begin
#10 clk = ~clk;
end

initial
begin
	

end


Device Target (dataPhaseCount,force_req,req,gnt,selDev,addr_data,AddressToContact,cmd,test_cmd,Frame,TRDY,IRDY,clk ,slotSel ,dataToWrite);

endmodule