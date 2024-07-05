`timescale 1 ns/1ps

module tx_scram (
// ���븴λ�źţ�����Ч������77.76Mʱ�ӣ�8λ���������
		rst_n, 
		sdh_clk, 
		start_of_frame,
		tx_no_scramble_data,

// �������ʹ���źţ�Ϊ1ʱ������ţ�Ϊ0ʱ�����ţ���ʼ��Ϊ0xFE��ǰ9xN����Ӧ�����š�
		tx_scramb_en,

// ����������ź��32λ���ݣ�ͬʱ���²�ȫ1����
		sdh_gtx_fifo_data,
		sdh_gtx_fifo_wen,
		tx_int_scram_data,
		start_of_frame_d1
	);
	input			        rst_n, sdh_clk     ;
	input			        tx_scramb_en       ;
	input             start_of_frame     ;
	input  [7:0]		  tx_no_scramble_data;
	output [31:0]	    sdh_gtx_fifo_data  ;
	output            sdh_gtx_fifo_wen   ;
	output [7:0]      tx_int_scram_data  ;
	output            start_of_frame_d1  ;
                                       
	reg    [31:0]		  sdh_gtx_fifo_data  ;
	reg               sdh_gtx_fifo_wen   ;
	reg               start_of_frame_d1  ;
// -------------------------------------------------
  reg    [7:0]	    tx_scramb_byte;
  reg    [7:0]	    tx_int_scram_data;
  reg               sdh_gtx_fifo_wen_p2,   sdh_gtx_fifo_wen_p1;

// �ڲ�����ʱ��������ΪFE������ʱ�����������Ľṹ�Ƴ��ư˴κ��������ֵ
  always@(negedge rst_n or posedge sdh_clk)
  	begin
		if(!rst_n)
			tx_scramb_byte <= 8'd0;
		else
			begin
				if(!tx_scramb_en)
					tx_scramb_byte <= 8'hfe;
				else
					begin
						tx_scramb_byte[7] <= tx_scramb_byte[6] ^ tx_scramb_byte[5];
						tx_scramb_byte[6] <= tx_scramb_byte[5] ^ tx_scramb_byte[4];
						tx_scramb_byte[5] <= tx_scramb_byte[4] ^ tx_scramb_byte[3];
						tx_scramb_byte[4] <= tx_scramb_byte[3] ^ tx_scramb_byte[2];
						tx_scramb_byte[3] <= tx_scramb_byte[2] ^ tx_scramb_byte[1];
						tx_scramb_byte[2] <= tx_scramb_byte[1] ^ tx_scramb_byte[0];
						tx_scramb_byte[1] <= tx_scramb_byte[0] ^ (tx_scramb_byte[6] ^ tx_scramb_byte[5]);
						tx_scramb_byte[0] <= tx_scramb_byte[6] ^ tx_scramb_byte[4];
					end
			end
	end

// ���������
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
		begin
			tx_int_scram_data <= 16'd0;
			start_of_frame_d1 <= 1'b0;
		end
		else
			begin
				if(tx_scramb_en)
					tx_int_scram_data <= tx_no_scramble_data ^ tx_scramb_byte;
				else
					tx_int_scram_data <= tx_no_scramble_data;
					
				start_of_frame_d1 <= start_of_frame;
			end
	end
	
reg   [1:0]     btye_cnt     ;
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
		begin
			sdh_gtx_fifo_data <= 32'd0;
			btye_cnt <= 2'd0;
			sdh_gtx_fifo_wen_p2 <= 1'b0;
			sdh_gtx_fifo_wen_p1 <= 1'b0;
			sdh_gtx_fifo_wen <= 1'b0;
		end
		else
			begin
				btye_cnt <= btye_cnt + 1'b1;
				
				if(btye_cnt == 2'd3)
				  sdh_gtx_fifo_wen_p2 <= 1'b1;
				else
				  sdh_gtx_fifo_wen_p2 <= 1'b0;
				  
				sdh_gtx_fifo_wen_p1 <= sdh_gtx_fifo_wen_p2  ;
				sdh_gtx_fifo_wen    <= sdh_gtx_fifo_wen_p1  ;
					
				sdh_gtx_fifo_data <= {sdh_gtx_fifo_data[23:0], tx_int_scram_data};
			end
	end
	
 endmodule
