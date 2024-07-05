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

module b1_check

       (
        rst_n,
        sdh_clk, 
       
		    rec_b1 ,
		    b1_valid_d2,
		    rx_1st_byte_valid,
		    rx_rec_data,
		    
		    b1_err
       );

input           rst_n, sdh_clk    ; 
input           b1_valid_d2  ;
input    [7:0]  rec_b1       ;
input           rx_1st_byte_valid;
input    [7:0]  rx_rec_data ;

output          b1_err ;

reg      [7:0]  b1_cal ;
reg      [7:0]  b1_cal_temp;
reg             b1_err ;

  always@(negedge rst_n or posedge sdh_clk)
  begin
	  if(!rst_n)
	  	b1_cal_temp <= 8'd0;
	  else
	  begin
	  	if( rx_1st_byte_valid )
	      b1_cal_temp  <= rx_rec_data;
	    else
        b1_cal_temp  <= b1_cal_temp ^ rx_rec_data;
    end
	end
				
				
  always@(negedge rst_n or posedge sdh_clk)
  begin
	  if(!rst_n)
	  	b1_cal <= 8'd0;
	  else
	  begin
	  	if( rx_1st_byte_valid )
	      b1_cal  <= b1_cal_temp;
    end
	end

  always@(negedge rst_n or posedge sdh_clk)
  begin
	  if(!rst_n)
	  	b1_err <= 1'b0;
	  else
	  begin
	  	if( b1_valid_d2 && (rec_b1!=b1_cal))
	      b1_err <= 1'b1;
	    else
	      b1_err <= 1'b0;
    end
	end

endmodule