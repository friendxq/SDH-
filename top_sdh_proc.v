`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: cheerchips
// Engineer		: david
// Design Name	: 
// Module Name	: top_sdh_proc
// Project Name	: 
// Target Device: 
// Tool versions: 
// Description	: 
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////

module top_sdh_proc 
           (
                   input             rst_n,
                   input             sdh_clk, 
        
//////////////////////////////������źŽӿ�/////////////////////////
        
                   input [7:0]       sdh_tx_din,
                   output            sdh_tx_din_req, //��ǰ1��
                   
  				         //SDH���ͷ������ؽӿ��ź�
  				         output [31:0]     sdh_gtx_fifo_data,
                   output            sdh_gtx_fifo_wen,
                   
                   //SDH���շ������ؽӿ��ź�
                   input  [7:0]      gtx_sdh_fifo_rdata,
                   output [7:0]      rx_int_data,
                   output            rx_int_data_vld,
                   output            warn_out

            			);
    
//------------- �ڲ��źŶ��� --------------------    

sdh_transmitter  U_sdh_transmitter 
     (
     .rst_n                (rst_n),
     .sdh_clk              (sdh_clk), 
   
////////////////������źŽӿ�/////////////////////////
                   
     .sdh_tx_din           (sdh_tx_din  ),
     .sdh_tx_din_req       (sdh_tx_din_req),//��ǰ1��
     
  	 // ����������ź��32λ���ݣ�ͬʱ���²�ȫ1����
		 .sdh_gtx_fifo_data    (sdh_gtx_fifo_data),
	   .sdh_gtx_fifo_wen     (sdh_gtx_fifo_wen )
   	);

		
sdh_receiver  U_sdh_receiver 
   (
     .rst_n              (rst_n),
     .sdh_clk            (sdh_clk), 
        
//////////////////////////////������źŽӿ�/////////////////////////
  	// ����������ź��32λ���ݣ�ͬʱ���²�ȫ1����
		 .gtx_sdh_fifo_rdata (gtx_sdh_fifo_rdata),
	   .rx_int_data        (rx_int_data       ),
	   .rx_int_data_vld    (rx_int_data_vld   ),
	   .warn_out           (warn_out          )
     );
			
endmodule


