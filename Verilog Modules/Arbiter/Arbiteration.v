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