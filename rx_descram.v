`timescale 1ns/1ps

module rx_descram (
// ���븴λ�źţ�����Ч
		rst_n, 
		sdh_clk, 
		rx_rec_data,
		rx_data_vld,
		b1_valid,

// rx_los_en, rx_lof_en��rx_oof_en�Ƕ�Ӧ�ĸ澯����ʱ�Ƿ��²�ȫ1��ʹ���źţ�����Ч
// rx_cpu_enΪCPUǿ���²�ȫ1��ʹ���źţ�����Ч��
		rx_cpu_en, 
		rx_los_en, 
		rx_lof_en, 
		rx_oof_en,

// ����LOs��OOF��LOF�澯
		rx_stm_los, 
		rx_stm_oof, 
		rx_stm_lof,

// �������ʹ���źţ�Ϊ1ʱ������ţ�Ϊ0ʱ�����ţ���ʼ��Ϊ0xFE
		rx_descramb_en,
		rx_int_data,
		rx_int_data_vld,
		rec_b1 ,    
		b1_valid_d2
	);
	
	input			      rst_n, sdh_clk;
	input			      rx_cpu_en, rx_los_en, rx_lof_en, rx_oof_en;
	input			      rx_stm_los, rx_stm_oof, rx_stm_lof;
	input			      rx_descramb_en, rx_data_vld;
	input           b1_valid ;
	input  [7:0]		rx_rec_data;
	
	output [7:0]		rx_int_data;
	output          rx_int_data_vld ;
	output [7:0]		rec_b1;
	output          b1_valid_d2 ;
         
	reg    [7:0]		rx_int_data;
	reg             rx_int_data_vld, b1_valid_d2 ;
	reg    [7:0]		rec_b1;
// -------------------------------------------------
  reg			          rx_ais_en;	
  reg      [7:0]	  rx_descramb_byte;
  reg               b1_valid_d1 ;

// ��ͳһ�����²�ȫ1���źţ��Ƚ�Լ��Դ������ٶ�
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
			rx_ais_en <= 1'd0;
		else
			rx_ais_en <=   rx_lof_en & rx_stm_lof ;
	end

// ����������RReceiveByte���н��ţ�ǰ9*16�����ݲ��ý��š�
// �ڲ�����ʱ��������ΪFE������ʱ�����������Ľṹ�Ƴ��ư˴κ��������ֵ
  always@(negedge rst_n or posedge sdh_clk)
  	begin
		if(!rst_n)
			rx_descramb_byte <= 8'd0;
		else
			begin
				if(!rx_descramb_en)
					rx_descramb_byte <= 8'hfe;
				else
					begin
						rx_descramb_byte[7] <= rx_descramb_byte[6] ^ rx_descramb_byte[5];
						rx_descramb_byte[6] <= rx_descramb_byte[5] ^ rx_descramb_byte[4];
						rx_descramb_byte[5] <= rx_descramb_byte[4] ^ rx_descramb_byte[3];
						rx_descramb_byte[4] <= rx_descramb_byte[3] ^ rx_descramb_byte[2];
						rx_descramb_byte[3] <= rx_descramb_byte[2] ^ rx_descramb_byte[1];
						rx_descramb_byte[2] <= rx_descramb_byte[1] ^ rx_descramb_byte[0];
						rx_descramb_byte[1] <= rx_descramb_byte[0] ^ (rx_descramb_byte[6] ^ rx_descramb_byte[5]);
						rx_descramb_byte[0] <= rx_descramb_byte[6] ^ rx_descramb_byte[4];
					end
			end
	end

// ���������ͬʱ�������澯ʱ�²�ȫ1һ����ɡ�
always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
		begin
			rx_int_data <= 8'd0;
			rx_int_data_vld <= 1'b0;
		end
		else
			begin
				if(rx_ais_en)
					rx_int_data <= 8'hff;
				else if(rx_descramb_en)
					rx_int_data <= rx_rec_data ^ rx_descramb_byte;
				else
					rx_int_data <= rx_rec_data;
			 
			  rx_int_data_vld <= rx_data_vld ;
			end
	end

  always@(negedge rst_n or posedge sdh_clk)
	begin
		if(!rst_n)
		begin
			rec_b1 <= 8'd0;
			b1_valid_d1 <= 1'b0;
			b1_valid_d2 <= 1'b0;
		end
		else
			begin
				if(b1_valid_d1)
					rec_b1 <= rx_int_data;
			 
			  b1_valid_d1 <= b1_valid ;
			  b1_valid_d2 <= b1_valid_d1 ;
			end
	end

  endmodule
