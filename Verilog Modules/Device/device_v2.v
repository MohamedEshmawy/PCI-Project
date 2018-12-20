module Device (force_req,req,gnt,selDev,addr_data,AddressToContact,cmd,test_cmd,Frame,TRDY,IRDY,clk ,slotSel ,dataToWrite);
//========================= pins declaration=========================
/*
//Test Pins--------------------------------------------
input force_req;         			//for testing purpouse only 
input test_cmd;           			//for testing purpouse only used in determining read or write 
input [4:0]AddressToContact;     //for testing purpouse only where msb [4] is the device ((0)for device B or (1)for device C)
input [0:31] dataToWrite;			//for testing purpouse only ised in detrimining what data to write

//PCI Pins---------------------------------------------
inout [31:0]addr_data;
inout cmd;            				 // for cmd (command) signal 1 for read and 0 for write
inout Frame, TRDY, IRDY;          //when Frame is Low and gnt is Low then start address phase..... Note:(Frame port may be inout)
output reg selDev;

//Arbiter Pins-----------------------------------------
input gnt;
output req;

//Extra------------------------------------------------
input slotSel;
input clk;

//=============================internal declartions=======================
reg Frame_out, TRDY_out, IRDY_out, cmd_out;
reg [31:0] addr_data_out;

reg Frame_in, TRDY_in, IRDY_in, cmd_in ,gnt_in;
reg [31:0] addr_data_in;

integer transCount = 0;
integer dataPhaseCount = 0;

//=============================assignments===================================
assign in_outMode = (cmd)?1:0;      //if cmd is read (1) then in_outMode is input mode (1)
//assign addr_data = (in_outMode^addressModeOn)?32'bz:Bi_dirOut;
assign addr_data = addressModeOn? Bi_dirOut: in_outMode?32'bz:Bi_dirOut;
assign addressModeOn = (addressDone)?1:0; // this condition is made to ensure that address phase don't interfere 
assign req = (force_req)?0:1;              //with data phase in Bidir_pin

assign Frame 		= Frame_out;
assign TRDY 		= TRDY_out;
assign IRDY			= IRDY_out;
assign cmd			= cmd_out;
assign addr_data	= addr_data_out;

initial
begin
	Frame_out = 1'bz;
	TRDY_out = 1'bz;
	IRDY_out = 1'bz;
	cmd_out = 1'bz;
	addr_data_out = 32'bz;
end

always @(posedge clk) 
begin
	//take a copy of the signals at the postive edge of the clock and save them in registers
	Frame_in			= Frame;
	TRDY_in 			= TRDY;
	IRDY_in 			= IRDY;
	cmd_in 			= cmd;
	addr_data_in	= addr_data;
	gnt_in 			= gnt;
	
	//manage test signals logic
	if (force_req) transCount++;
end

always @(negedge clk)
begin
	//bus requsition
	if (transCount > 0) 	req <= 0;
	if (transCount == 0)	req <= 1;
	
	if (!gnt_in & Frame_in) //if arbiter granted
	begin
		repeat(1) @(negedge clk);
		Frame_out 		<= 0;
		addr_data_out	<= AddressToContact;
		cmd_out 			<= test_cmd;
		
		repeat(1) @(negedge clk);
			IRDY_out			<= 0;
			
		repeat(dataPhaseCount) @(negedge clk)
		begin
			addr_data_out	<= dataToWrite;
			if (dataPhaseCount == 1)	Frame_out	<= 1;
			dataPhaseCount--;
		end
		
		repeat(1) @(negedge clk);
		addr_data_out	<= 32'bz;
		IRDY_out = 1;
		
	end
	
end*/
endmodule

module upcntr_addr(enable,areset,trigger,current_addr);  //tested and working fine (made for address calaculation)
input areset,trigger,enable;
reg [3:0] count;
output [3:0]current_addr;
assign current_addr = (areset)?4'b0000:count;
initial count <= 4'b0000;
always@(posedge trigger)
begin
if(enable)
begin
if(areset)count <= 4'b0000;
else if(count < 4'b1010)count <= count +1;
else count <= 4'b0000;
end
end
endmodule