module Slot(selSlot, Frame, selDev, addr_data, slotAddress);

output selSlot;
input Frame, selDev;	//PCI control pins
input [31:0] addr_data;	 			//pci address/data bus
input [4:0] slotAddress; 			//address given to this slot

assign selSlot = Frame | !selDev? 0 :addr_data == slotAddress?1:0;

endmodule
