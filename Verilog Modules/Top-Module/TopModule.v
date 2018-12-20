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
