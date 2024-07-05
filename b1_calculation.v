`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: cheerchips
// Engineer		: david
// Design Name	: 
// Module Name	: b1_calculation
// Project Name	: 
// Target Device: 
// Tool versions: 
// Description	: 
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////

module b1_calculation

       (
        rst_n,
        sdh_clk, 
       
		    tx_int_scram_data,
		    start_of_frame_d1,
		    
		    b1_cal
       );

input           rst_n, sdh_clk    ; 
input           start_of_frame_d1 ;
input    [7:0]  tx_int_scram_data ;

output   [7:0]  b1_cal ;

reg      [7:0]  b1_cal ;
reg      [7:0]  b1_cal_temp;

  always@(negedge rst_n or posedge sdh_clk)
  begin
	  if(!rst_n)
	  	b1_cal_temp <= 8'd0;
	  else
	  begin
	  	if( start_of_frame_d1 )
	      b1_cal_temp  <= tx_int_scram_data;
	    else
        b1_cal_temp  <= b1_cal_temp ^ tx_int_scram_data;
    end
	end
				
				
  always@(negedge rst_n or posedge sdh_clk)
  begin
	  if(!rst_n)
	  	b1_cal <= 8'd0;
	  else
	  begin
	  	if( start_of_frame_d1 )
	      b1_cal  <= b1_cal_temp;
    end
	end



endmodule