`timescale 100ns / 1ns

module Device (dataPhaseCount,force_req,req,gnt,devSel,addr_data,AddressToContact,cmd,test_cmd,Frame,TRDY,IRDY,clk ,slotSel ,dataToWrite);
//========================= pins declaration=========================

//Test Pins--------------------------------------------
input force_req;         		//for testing purpouse only 
input test_cmd;           		//for testing purpouse only used in determining read or write 
input [4:0]AddressToContact;  //for testing purpouse only where msb [4] is the device ((0)for device B or (1)for device C)
input [0:31] dataToWrite;		//for testing purpouse only used in detrimining what data to write
input [3:0] dataPhaseCount;	//for testing purpouse only used in detrimining number of data phases

//PCI Pins---------------------------------------------
inout [31:0]addr_data;
inout cmd;            			  //for cmd (command) signal 1 for read and 0 for write
inout Frame, TRDY, IRDY;        //when Frame is Low and gnt is Low then start address phase..... Note:(Frame port may be inout)
output reg devSel;

//Arbiter Pins-----------------------------------------
input gnt;
output reg req;

//Extra------------------------------------------------
input slotSel;
input clk;

//=============================internal declartions=======================
reg Frame_out, TRDY_out, IRDY_out, cmd_out;
reg [31:0] addr_data_out;

reg Frame_in, TRDY_in, IRDY_in, cmd_in ,gnt_in;
reg [31:0] addr_data_in;

integer   transCount = 0;			//this variable counts the number of transactions
reg [3:0] dataPhaseCount_temp;	//this variable will serve later as a counter for data phases
reg [3:0] addressCounter = 0;		//this variable is used in slave/target to write in the memory
reg [9:0] memory [0:31];

//=============================assignments===================================
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
	if (force_req) transCount <= transCount + 1; //increment the transaction counter
end


//==================================INITIATOR/MASTER MANAGMENT==================================//
always @(negedge clk)
begin

	//bus requsition
	if (transCount > 0) 	req <= 0; //the req signal is asserted as long as transcount is higher than 0
	if (transCount == 0)	req <= 1; //the device no longer requests the bus if transcount is zero
	
	if (!gnt_in & Frame_in) //if arbiter granted and frame is free ,then commence the transaction
	begin
	
		dataPhaseCount_temp <= dataPhaseCount; //take a copy of the latest dataPhaseCount
		
		repeat(1) @(negedge clk);	 				//wait for frame turn over cycle
		
		//-----------------------------Address Phase------------------------------//
		Frame_out 		<= 0;			  				//pull down the frame signal
		addr_data_out	<= AddressToContact;		//insert the address
		cmd_out 			<= test_cmd;				//insert the cmd
		if (transCount == 1) req <= 1;			//remove the reqest signal if there is only one transaction
		
		repeat(1) @(negedge clk);					//wait for IRDY turn over cycle
			IRDY_out			<= 0;						//pull down the IRDY signal
			
		//-----------------------------Data Phases--------------------------------//
		addr_data_out	<= dataToWrite;										//insert the data into the bus
		if (dataPhaseCount_temp == 1'b001)	Frame_out	<= 1'bz;		 //release the frame signal if the next data phase is the last one
		dataPhaseCount_temp <= dataPhaseCount_temp - 1;					//decrement the value of dataPhaseCount every time we finish a data phase
		wait(TRDY_in == 0);	
		
		repeat(dataPhaseCount_temp - 1) @(negedge clk)					//repeat the data phases
		begin
			addr_data_out	<= dataToWrite;									//insert the data into the bus
			if (dataPhaseCount_temp == 1'b001)	Frame_out	<= 1'bz; //release the frame signal if the next data phase is the last one
			dataPhaseCount_temp <= dataPhaseCount_temp - 1;				//decrement the value of dataPhaseCount every time we finish a data phase
			wait(TRDY_in == 0);													//do not proceed into the next data phase unless TRDY is low
		end
		
		
		//------------------------Finishing The Transaction------------------------//
		repeat(1) @(negedge clk) wait(TRDY_in == 0);					
		//wait one cycle to make sure target device has read the data
		//also if the TRDY is high this means that target has not read the last data phase
		//so we will wait until TRDY is low again before releasing the bus
		
		//---------------------------Releasing The Bus-----------------------------//
		addr_data_out	<= 32'bz;					//release the address/data bus
		IRDY_out = 1'bz; 								//release the IRDY signal
		cmd_out 	= 1'bz; 								//release the cmd signal
		transCount = transCount - 1; 				//decrement the transCount every time a transaction starts
	end
end	

//==================================TARGET/SLAVE MANAGMENT==================================//
always @(negedge clk)
begin
	if (slotSel) //if slot select is true this means a master device is communicating with this device
	begin
		repeat(1) @(negedge clk);	//wait for devSel & TRDY turn over cycle
		devSel 				<= 0; 	//pull down the devsel signal
		TRDY_out				<= 0; 	//pull down the TRDY signal
		addressCounter 	<= 0; 	//initialize addressCounter to zero
		
		//data phases
		while (IRDY_in==0 | Frame_in == 0)
		begin
			wait (IRDY_in == 0);
			repeat (1) @(posedge clk) memory[addressCounter] <= addr_data_in;
			addressCounter <= addressCounter + 1;
		end
		TRDY_out 	<= 1'bz; //release TRDY
		devSel		<= 1'bz; //release devSel
	end
end
	

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