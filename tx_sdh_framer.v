`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: cheerchips
// Engineer		: david
// Design Name	: 
// Module Name	: tx_sdh_framer
// Project Name	: 
// Target Device: 
// Tool versions: 
// Description	: 
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////

module tx_sdh_framer 
           (
                   input             rst_n,
                   input             sdh_clk, 
        
        
                   input [7:0]       sdh_tx_din,
                   output reg        sdh_tx_din_req, //��ǰ1��
                   
                   input [7:0]       b1_cal,
                   
  				          //SDH���ͷ������ؽӿ��ź�
				           output reg [7:0]	 tx_no_scramble_data,
				           output reg        start_of_frame,
				           output reg        tx_scramb_en

            			);
    
//------------- �ڲ��źŶ��� -------    
reg [1:0]			stm_mu_cnt;
reg [8:0]			stm_col; 	//SDH���м�����
reg [3:0]			stm_row; 	//SDH���м�����
    
 
	
//SDH���õ�Ԫ�ļ�����
always @(posedge sdh_clk or negedge rst_n)
begin
  if(!rst_n)
  	 stm_mu_cnt <= 2'b00;
  else
	   stm_mu_cnt <= stm_mu_cnt + 1'b1;
end		

	
//SDH���м�����
always @(posedge sdh_clk or negedge rst_n)
begin
  if(!rst_n)
	  stm_col <= 9'd0;
  else
  begin
	if((stm_mu_cnt == 2'd3)&&(stm_col == 9'd269))
	  stm_col <= 9'd0;
	else if(stm_mu_cnt == 2'd3)
	  stm_col <= stm_col + 1'b1;
  end
end		

//SDH���м�����
always @(posedge sdh_clk or negedge rst_n)
begin
  if(!rst_n)
	stm_row <= 4'd0;
  else
  begin
	if ((stm_mu_cnt == 2'd3)&&(stm_col  == 9'd269)&&(stm_row == 4'd8))
	  stm_row <= 4'd0;
	else if ((stm_mu_cnt == 2'd3)&&(stm_col  == 9'd269))
	  stm_row <= stm_row + 1'b1;
  end
end		
	
	
always @(posedge sdh_clk or negedge rst_n)
begin
  if(!rst_n)
	  sdh_tx_din_req <= 1'b0;                    
  else
	begin
	  if((stm_mu_cnt == 2'd2)&&(stm_col == 9'd269))
	    sdh_tx_din_req <= 1'b0;
	  else if((stm_mu_cnt == 2'd2)&&(stm_col == 9'd8))
		  sdh_tx_din_req <= 1'b1;
	end
end		
	

		
always @(posedge sdh_clk or negedge rst_n)
begin
  if(!rst_n)
  begin
	  tx_no_scramble_data <= 8'd0;
	  start_of_frame <= 1'b0;
	  tx_scramb_en <= 1'b0;
  end
  else
  begin
    if(stm_row == 4'd0 && stm_col <= 9'd2)
      tx_no_scramble_data <= 8'hf6;
    else if(stm_row == 4'd0 &&stm_col <= 9'd5)
      tx_no_scramble_data <= 8'h28;
    else if((stm_row == 4'd1) && (stm_col == 9'd0)&&(stm_mu_cnt == 2'd0))
      tx_no_scramble_data <= b1_cal ;
    else if(stm_col >= 9'd9)
      tx_no_scramble_data <= sdh_tx_din;
    else
      tx_no_scramble_data <= 8'h55;
      
      
    if((stm_row == 4'd0) && (stm_col == 9'd0)&&(stm_mu_cnt == 2'd0))   
      start_of_frame <= 1'b1;
    else
      start_of_frame <= 1'b0;
        
    if(stm_row == 4'd0 && stm_col <= 9'd8)   
      tx_scramb_en <= 1'b0;
    else
      tx_scramb_en <= 1'b1;
      
        
  end
end	


			
endmodule
   