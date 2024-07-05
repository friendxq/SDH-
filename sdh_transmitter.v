`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////
// Company		: cheerchips
// Engineer		: david
// Design Name	: 
// Module Name	: sdh_transmitter
// Project Name	: 
// Target Device: 
// Tool versions: 
// Description	: 
//				
// Revision		: V1.0
// Additional Comments	:  
// 
////////////////////////////////////////////////////////////////////////////////

module sdh_transmitter 
           (
                   input             rst_n,
                   input             sdh_clk, 
        
//////////////////////////////������źŽӿ�/////////////////////////
        
                   input [7:0]       sdh_tx_din,
                   output            sdh_tx_din_req,    //��ǰ1��
                   
  				         // ����������ź��32λ���ݣ�ͬʱ���²�ȫ1����
		               output [31:0]	   sdh_gtx_fifo_data  ,
	                 output            sdh_gtx_fifo_wen   
            			);
    
//------------- �ڲ��źŶ��� -----------    
wire   [7:0]	  tx_no_scramble_data        ;
wire            tx_scramb_en    ;
wire            start_of_frame  ,start_of_frame_d1;
wire   [7:0]    tx_int_scram_data   ;
wire   [7:0]    b1_cal ;
	
tx_sdh_framer  U_tx_sdh_framer 
           (
            .rst_n         (rst_n),
            .sdh_clk       (sdh_clk),
        
//////////////////////////////������źŽӿ�/////////////////////////
           
            .sdh_tx_din    (sdh_tx_din  ), 
            .sdh_tx_din_req(sdh_tx_din_req), //��ǰ1��
            .b1_cal        (b1_cal),
                   
  				  //SDH���ͷ������ؽӿ��ź�
			      .tx_no_scramble_data      (tx_no_scramble_data),
			      .start_of_frame           (start_of_frame),
			      .tx_scramb_en             (tx_scramb_en)
             );
             
tx_scram  U_tx_scram (
// ���븴λ�źţ�����Ч������77.76Mʱ�ӣ�8λ���������
		.rst_n                   (rst_n),
		.sdh_clk                 (sdh_clk),
		.tx_no_scramble_data     (tx_no_scramble_data),
    .start_of_frame          (start_of_frame),
// �������ʹ���źţ�Ϊ1ʱ������ţ�Ϊ0ʱ�����ţ���ʼ��Ϊ0xFE��һ��ǰ9xN�����ü��š�
		.tx_scramb_en            (tx_scramb_en),

// ����������ź��32λ���ݣ�ͬʱ���²�ȫ1����
		.sdh_gtx_fifo_data       (sdh_gtx_fifo_data),
		.sdh_gtx_fifo_wen        (sdh_gtx_fifo_wen),
		.tx_int_scram_data       (tx_int_scram_data),
		.start_of_frame_d1       (start_of_frame_d1)
	);
	
b1_calculation  U_b1_calculation

       (
        .rst_n             (rst_n),
        .sdh_clk           (sdh_clk), 
		    .tx_int_scram_data (tx_int_scram_data),
		    .start_of_frame_d1 (start_of_frame_d1),
		    .b1_cal            (b1_cal)
       );

			
endmodule
   