`timescale 100ns / 1ns
module Device (req, selDev, force_req, test_cmd, AddressToContact, dataToWrite, dataPhaseCount, gnt, selSlot, clk, addr_data, cmd, Frame, TRDY, IRDY);

//module Device (dataPhaseCount,force_req,req,gnt,selDev,addr_data,AddressToContact,cmd,test_cmd,Frame,TRDY,IRDY,clk ,selSlot ,dataToWrite);
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
output reg selDev;

//Arbiter Pins-----------------------------------------
input gnt;
output reg req;

//Extra------------------------------------------------
input selSlot;
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
	Frame_out 		<= 1'bz;
	TRDY_out 		<= 1'bz;
	IRDY_out 		<= 1'bz;
	cmd_out			<= 1'bz;
	selDev			<= 1'bz;
	addr_data_out 	<= 32'bz;
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
	if (selSlot) //if select slot is true this means a master device is communicating with this device
	begin
		repeat(1) @(negedge clk);	//wait for selDev & TRDY turn over cycle
		selDev 				<= 0; 	//pull down the selDev signal
		TRDY_out				<= 0; 	//pull down the TRDY signal
		addressCounter 	<= 0; 	//initialize addressCounter to zero
		
		//data phases
		while (IRDY_in==0 | Frame_in == 0)
		begin
			repeat (1) @(posedge clk) memory[addressCounter] <= addr_data_in;
			addressCounter <= addressCounter + 1;
		end
		TRDY_out 	<= 1'bz; //release TRDY
		selDev		<= 1'bz; //release selDev
	end
end
	

endmodule

module Slot(selSlot, Frame, selDev, addr_data, slotAddress);

output selSlot;
input Frame, selDev;	//PCI control pins
input [31:0] addr_data;	 			//pci address/data bus
input [4:0] slotAddress; 			//address given to this slot

assign selSlot = Frame | !selDev? 0 :addr_data == slotAddress?1:0;

endmodule

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

/*note that bit number zero mis for the first device (A)
,and the bit umber 1 is for DEvice B
and the bit umber 2 is for DEvice C
the most priority is for the A then B then C*/


module Arbiter(reqA,reqB,reqC,gntA,gntB,gntC,frame,clk);
output reg gntA,gntB,gntC;
input reqA,reqB,reqC;
input frame,clk;
initial	
	begin 
		gntA = 1;gntB = 1;gntC = 1;
	end
always @(posedge clk )
	begin	
	if(frame)
#10
	begin
		if     ( reqA==0 && reqB==0 && reqC==0 ) begin gntA=0; gntB=1; gntC=1; end
		else if( reqA==0 && reqB==0 && reqC==1 ) begin gntA=0; gntB=1; gntC=1; end
		else if( reqA==0 && reqB==1 && reqC==0 ) begin gntA=0; gntB=1; gntC=1; end
		else if( reqA==0 && reqB==1 && reqC==1 ) begin gntA=0; gntB=1; gntC=1; end
		else if( reqA==1 && reqB==0 && reqC==0 ) begin gntA=1; gntB=0; gntC=1; end
		else if( reqA==1 && reqB==0 && reqC==1 ) begin gntA=1; gntB=0; gntC=1; end
		else if( reqA==1 && reqB==1 && reqC==0 ) begin gntA=1; gntB=1; gntC=0; end
		else if( reqA==1 && reqB==1 && reqC==1 ) begin gntA=1; gntB=1; gntC=1; end

	end
			
			
		
	end		
endmodule 

module test();
reg  reqA,reqB,reqC;
reg clk,frame;
wire gntA,gntB,gntC;
initial 
begin 
$monitor (" %b %b %b %b %b %b %b %b",clk ,reqA,reqB,reqC,gntA,gntB,gntC,frame);
clk = 1; reqA = 0 ;reqB = 0;reqC=0; frame = 1;
#10
clk = 0;
#10
clk = 1; reqA = 0 ;reqB = 0;reqC=1; frame = 1;
#10
clk = 0;
#10
clk = 1; reqA = 0 ;reqB = 1;reqC=0; frame = 1;
#10
clk = 0;
#10
clk = 1; reqA = 0 ;reqB = 1;reqC=1; frame = 1;
#10
clk = 0;
#10
clk = 1; reqA = 1;reqB = 0;reqC=0; frame = 1;
#10
clk = 0;
#10
clk = 1; reqA = 1 ;reqB = 0;reqC=1; frame = 1;
#10
clk = 0;
#10
clk = 1; reqA = 1 ;reqB = 1;reqC=0; frame = 1;
#10
clk = 0;
#10
clk = 1; reqA = 1 ;reqB = 1;reqC=1; frame = 1;
end 
Arbiter MM(reqA,reqB,reqC,gntA,gntB,gntC,frame,clk);
endmodule

/*001: GNT =3'b011  ;
			010: GNT =3'b011  ;
			011: GNT =3'b011  ;
			100: GNT =3'b101  ;
			101: GNT =3'b101  ;
			110: GNT =3'b110  ;
			111: GNT =3'b111  ;
			000: GNT =3'b011  ;
*/

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




module TopModule(
force_reqA ,AddressToContactA, dataPhaseCountA,	//device A test pins		(Input)
force_reqB ,AddressToContactB, dataPhaseCountB, //device B test pins		(Input)
force_reqC ,AddressToContactC, dataPhaseCountC, //device C test pins		(Input)
Frame,addr_data, TRDY, IRDY, selDev,				//pci control signals	(output)
reqA, gntA, reqB, gntB, reqC, gntC,					//arbiter signals			(output)
clk															//clock						(Input)
);

//========================= pins declaration=========================\\
input force_reqA ,force_reqB, force_reqC;
input [4:0] AddressToContactA, AddressToContactB, AddressToContactC;
input [3:0] dataPhaseCountA, dataPhaseCountB, dataPhaseCountC;
output Frame,addr_data, TRDY, IRDY, selDev;
output reqA, gntA, reqB, gntB, reqC, gntC;
input clk;

//======================= Internal declaration=======================\\
wire [4:0]	slotAddressA, slotAddressB, slotAddressC;
wire [31:0] dataToWriteA, dataToWriteB, dataToWriteC;
wire [31:0] addr_data;
//=========================== Assignments ===========================\\
assign slotAddressA = 0;
assign slotAddressB = 1;
assign slotAddressC = 2;

assign dataToWriteA = 32'hAAAA_AAAA;
assign dataToWriteB = 32'hBBBB_BBBB;
assign dataToWriteC = 32'hCCCC_CCCC;

//======================= Modules declaration========================\\
Device deviceA(reqA, selDev, force_reqA, test_cmdA, AddressToContactA, dataToWriteA, dataPhaseCountA, gntA, selSlotA, clk, addr_data, cmd, Frame, TRDY, IRDY);
Device deviceB(reqB, selDev, force_reqB, test_cmdB, AddressToContactB, dataToWriteB, dataPhaseCountB, gntB, selSlotB, clk, addr_data, cmd, Frame, TRDY, IRDY);
Device deviceC(reqC, selDev, force_reqC, test_cmdC, AddressToContactC, dataToWriteC, dataPhaseCountC, gntC, selSlotC, clk, addr_data, cmd, Frame, TRDY, IRDY);

Slot slotA(selSlotA, Frame, selDev, addr_data, slotAddressA);
Slot slotB(selSlotB, Frame, selDev, addr_data, slotAddressB);
Slot slotC(selSlotC, Frame, selDev, addr_data, slotAddressC);

PCIBus bus(Frame, TRDY, IRDY, selDev, Frame, TRDY, IRDY ,selDev);
Arbiter arbiter(reqA,reqB,reqC,gntA,gntB,gntC,Frame,clk);

endmodule





module test_topmodule()
/*-----------------TestBench_input/output---------------*/
input reg clck,frame,force_requestA,force_requestB,force_requestC;
input reg [31:0]addresstocontactmA,addresstocontactmB,addresstocontactmC;
/*-----------------TopModule_input/output---------------*/


/*
**
wire ,,,
*/


initial
   begin
$monitor ( $time ,, "%b  %h %b %h %b %h %b-",  clck,addresstocontactA,force_requestA,addresstocontactB,force_requestB,addresstocontactC,force_requestC)
clck=0;  
force_requestA=0;     force_requestB=0;    force_requestC=0;
addresstocontactA=z;  addresstocontactB=z;  addresstocontactC=z;
#20
force_requestA=1;
#60
// reg z=1;  //no of transection
addresstocontactA=32'b1;   //address of device B
#20
/*
reg y=3; // no of word
reg x=32'hAAAAAAAA;
*/

#80

force_requestA=0;   force_requestB=1;
#60
//reg z=1;
addresstocontactb=32'b0;   //address of device A
#20
/*
reg y=2; // no of word
reg x=32'hBBBBBBBB;
*/
#60     //no of word n2s wa7e f fe cycle 7tn2s
force_requestA=1;   force_requestB=0; force_requestC=1;
#60
addresstocontactA=32'b2;    //address of device C
#20
/*
reg y=1; // no of word
reg x=32'hAAAAAAAA;
*/
#40
// reg z=2;
addresstocontactC=32'b0;   //device C contact to device A
#20
/*
reg y=1; // no of word
reg x=32'hCCCCCCCC;
*/
#40
addresstocontactC=32'b1;   //device C contact to device B
#20
/*
reg y=1; // no of word
reg x=32'hCCCCCCCC;
*/   


   end

always 
   begin
#10
clck~=clck;
   end
/*
**
instance of TopModule
*
*/
endmodule
/*
**
 y --> no of word
 x--> Data 
  z--> no of trans
**
*/
