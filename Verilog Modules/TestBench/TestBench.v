
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