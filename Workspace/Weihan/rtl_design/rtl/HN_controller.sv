//-----------------------------------------------------------------------------
// Title         : Home Node controller
// Project       : Master thesis
//-----------------------------------------------------------------------------
// File          : controller.sv
// Author        : Weihan  <weihan@weihan-IdeaPad-3-15IGL05>
// Created       : 21.03.2024
// Last modified : 31.03.2024
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2024 by cth This model is the confidential and
// proprietary property of cth and the possession or use of this
// file requires a written license from cth.
//------------------------------------------------------------------------------
// Modification history :
// 21.03.2024 : created
//-----------------------------------------------------------------------------

module HN_controller 
import llc_config_pkg::*;
import llc_common_pkg::*; //data infomation bit(flags)
import chi_package::*;    //the interface rx and tx and opcode 
(
 input logic clk,
 input logic rstn,
	     
 chi_channel_inf.rx rx_req, 
 chi_channel_inf.rx rx_rsp, 
 chi_channel_inf.rx rx_dat, 
 
 chi_channel_inf.tx tx_req, 
 chi_channel_inf.tx tx_rsp, 
 chi_channel_inf.tx tx_dat, 
 chi_channel_inf.tx tx_snp 
);
   /* ====================
    OPCODE in <chi_package> :
    READ_SHARED     = 7'h1      , //req channel
    READ_UNIQUE     = 7'h7      , //req channel
    WRITE_BACK_FULL = 7'h1b     , //req channel 
    READ_NO_SNP     = 7'h4      , //req channel
    WRITE_NO_SNP_DEF  =  7'h4E  , //req channel
    
    
    SNP_RESP            =   5'h1, //rsp channel
    COMP_ACK            =   5'h2, //rsp channel
    COMP                =   5'h4, //rsp channel
    COMP_DBID_RESP      =   5'h5, //rsp channel
    DBID_RESP           =   5'h6, //rsp channel
    RESP_SEP_DATA       =   5'hB, //rsp channel

    SNP_SHARED          =   5'h1, //snp channel
    SNP_UNIQUE          =   5'h7, //snp channel
    
    SNP_RSP_DATA               = 4'h1,//data channel
    COPY_BACK_WR_DATA          = 4'h2,//data channel
    NON_COPY_BACK_WR_DATA      = 4'h3,//data channel
    COMP_DATA                  = 4'h4,//data channel
    DATA_SEP_RESP              = 4'hb,//data channel
   ====================== */
     //rx_BLANK     = 7'b0000_000,
     //READ_SHARED  = 7'b0000_001,
     //SNP_RSP_DATA = 7'b0000_010,
     //SNP_RESP     = 7'b0000_011,
     //COMP_DATA    = 7'b0000_100,
     //COMP_ACK     = 7'b0000_101,
     
     //COMP_DBID_RESP     = 7'b0001_001,
     //COPY_BACK_WR_DATA  = 7'b0001_010,
     //COPY_BACK_WR_DATA  = 7'b0001_011;

     //tx_BLANK     = 7'b1000_000,
     //SNP_SHARED   = 7'b1000_001,
     //READ_NO_SNP  = 7'b1000_010,
     //COMP_DATA    = 7'b1000_011,
     //COMP_DBID_RESP     = 7'b1000_100,
     //WRITE_NO_SNP_DEF   = 7'b1000_101,
     //NON_COPY_BACK_WR_DATA  = 7'b1000_110;
   /* ====================== */

   
   // NODEID
   parameter
     RN1 = 7'b0000_001,
     RN2 = 7'b0000_010,
     RN3 = 7'b0000_100,
     RN4 = 7'b0001_000,
     RNX = 7'b1111_111, // boardcast
     SN  = 7'b0010_000; 
   
   // Others
   parameter Core_Num = 4;  // multi-processor num
   parameter bit_Num = 2;   // 2 = log4


   
   //******************************************************//
   // 2. logic, cnt, edge
   logic     lc_req,lc_dat,lc_rsp;
   logic [bit_Num-1:0] cnt_SNP_RESP;         // counting for num# of SnpResp from RN
   logic [bit_Num-1:0] cnt_lc_rsp;            // counting for cycles should sent

   logic 	       falling_edge_RespChannel; // flag : receiving resps from RN
   logic 	       falling_edge_DataChannel; // flag : receiving data  from RN/SN
   logic 	       RX_RSPFLITPEND_d1;
   logic 	       RX_RSPFLITPEND_d2;
   logic 	       RX_DATFLITPEND_d1;
   logic 	       RX_DATFLITPEND_d2;

   
   logic 		     rx_pkg;
   logic 		     tx_pkg;
   
   // FSM for coherence controller
   localparam 
     IDLE      = 3'b000,
     START     = 3'b001,
     WAIT_RSP  = 3'b010,
     WAIT_MEM  = 3'b011,   
     WAIT_ACK  = 3'b100,
     WAIT_DBID = 3'b101,
     WAIT_EVIC = 3'b110;

   /********************************************/

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 RX_RSPFLITPEND_d1 <= 0;
	 RX_RSPFLITPEND_d2 <= 0;
	 RX_DATFLITPEND_d1 <= 0;
	 RX_DATFLITPEND_d2 <= 0;
	 
      end
      else begin
	 RX_RSPFLITPEND_d1 <= rx_rsp.flit_pend;//RX_RSPFLITPEND;
	 RX_RSPFLITPEND_d2 <= RX_RSPFLITPEND_d1;
	 RX_DATFLITPEND_d1 <= rx_dat.flit_pend;//RX_DATFLITPEND;
	 RX_DATFLITPEND_d2 <= RX_DATFLITPEND_d1;
      end
   end // always @ (posedge clk or negedge rstn)

   //assign falling_edge_RespChannel = (~RX_RSPFLITPEND) & (RX_RSPFLITPEND_d1);
   assign falling_edge_RespChannel = (~rx_rsp.flit_pend) & (RX_RSPFLITPEND_d1); 


   
   /**********************FSM*****************************/
   // State registers for coherency_state
   logic [3:0] 	     coherency_state, coherency_state_nxt;

   // State FF for coherency
   always_ff @ ( posedge clk or negedge rstn ) begin
      if ( !rstn ) begin 
	 coherency_state <= IDLE;
	 cnt_lc_rsp      <= 0;
	 cnt_SNP_RESP <= 0;
	 
      end
      else begin
	 coherency_state <= coherency_state_nxt;

	 // at the beginning of state WAIT_RSP :  "cnt_lc_rsp"  0->1->2 , indicating lc_response be there 3 cycles
	 if(coherency_state_nxt == WAIT_RSP || coherency_state == WAIT_RSP) begin
	    if(cnt_lc_rsp < Core_Num-1) begin
	       // 0->1->2->2->2.....
	       cnt_lc_rsp <= cnt_lc_rsp + 1; 
	    end
	 end
	 else begin
	    cnt_lc_rsp <= 0;
	 end

	 
	 ////cnt_SNP_RESP increase: 0->1->2. based on the Snpresponse from remote RN
	 if(coherency_state == WAIT_RSP && falling_edge_RespChannel==1 && cnt_SNP_RESP < Core_Num-1) begin
	    cnt_SNP_RESP <= cnt_SNP_RESP + 1;
	 end
	 if(cnt_SNP_RESP >= Core_Num-1) begin
	    cnt_SNP_RESP <= 0;
	 end
      end
   end
   

   // Next State Logic for coherency
   //always @ ( /*AUTOSENSE*/COMP_ACK or COMP_DATA
   //		  or COMP_DBID_RESP or COPY_BACK_WR_DATA
   //		  or READ_SHARED or SNP_RSP_DATA or cnt_SNP_RESP
   //		  or coherency_state or rx_opcode) begin
   always_comb begin
      case (coherency_state) 
	IDLE: begin
	   coherency_state_nxt = START;
	end
	
	START: begin  // Important:  we now only think READ_SHARED case
	   if (rx_req.opcode == READ_SHARED) begin
	      coherency_state_nxt = WAIT_RSP;
	   end
	   else begin
	      coherency_state_nxt = START;
	   end	      
	end
	//
	WAIT_RSP : begin
	   if (rx_rsp.opcode == SNP_RSP_DATA) begin
	      coherency_state_nxt = WAIT_ACK;
	   end
	   else begin
	      if (cnt_SNP_RESP == Core_Num-1) begin // the SnpResp received is 0->1->2->3
		 coherency_state_nxt = WAIT_MEM;
	      end
	      else begin
		 coherency_state_nxt = WAIT_RSP;
	      end
	   end	  
	end
	//
	WAIT_MEM : begin
	   if (rx_rsp.opcode == COMP_DATA) begin
	      coherency_state_nxt = WAIT_ACK;
	   end
	   else begin
	      coherency_state_nxt = WAIT_MEM;
	   end
	end
	WAIT_ACK : begin
	   if (rx_rsp.opcode == COMP_ACK) begin
	      coherency_state_nxt = START;
	   end
	   else begin
	      coherency_state_nxt = WAIT_ACK;
	   end
	end
	//
	WAIT_DBID : begin
	   if (rx_rsp.opcode == COMP_DBID_RESP) begin
	      coherency_state_nxt = START;
	   end
	   else begin
	      coherency_state_nxt = WAIT_DBID;
	   end
	end 
	WAIT_EVIC : begin
	   if (rx_rsp.opcode == COPY_BACK_WR_DATA) begin
	      coherency_state_nxt = START;
	   end
	   else if (rx_rsp.opcode == COPY_BACK_WR_DATA) begin
	      coherency_state_nxt = WAIT_DBID;
	   end
	   else begin
	      coherency_state_nxt = WAIT_EVIC;
	   end
	end 
      endcase
   end

   logic trgID;
   
   /*************output logic**************/
   //always @ ( /*AUTOSENSE*/COMP_DATA or COMP_DBID_RESP
   //             or NON_COPY_BACK_WR_DATA or READ_NO_SNP
   //             or SNP_SHARED or WRITE_NO_SNP_DEF or cnt_lc_rsp
   //		  or coherency_state or coherency_state_nxt) begin
   always_comb begin
      lc_req = 1'b0;
      lc_dat = 1'b0;
      lc_rsp = 1'b0;
      
      tx_req.opcode  = 0;
      tx_rsp.opcode  = 0;
      tx_dat.opcode  = 0;
      tx_snp.copde   = 0;
      trgID  = 7'b1000_000;
      
      case ( coherency_state_nxt )
	IDLE: begin

	end
	//
	START: begin
	   if ( coherency_state == WAIT_DBID) begin
	      tx_rsp.opcode = NON_COPY_BACK_WR_DATA;
	   end
	   else if ( coherency_state == IDLE || coherency_state == WAIT_EVIC) begin
	      lc_req = 1'b1;
	   end
	end
	
	//
	WAIT_RSP : begin
	   if ( coherency_state == START ) begin
	      tx_snp.opcode = SNP_SHARED;
	      trgID = RNX;
	      lc_dat = 1'b1;
	   end
	   if ( cnt_lc_rsp < Core_Num-1 ) begin
	      lc_rsp = 1'b1;
	   end
	   

	end 
	
	//
	WAIT_MEM : begin
	   tx_rsp.opcode     = READ_NO_SNP;
	end
	
	WAIT_ACK : begin
	   tx_rsp.opcode     = COMP_DATA;
	end
	
	//	
	WAIT_DBID : begin
	   tx_rsp.opcode     = WRITE_NO_SNP_DEF;
	end
	
	WAIT_EVIC : begin
	   tx_rsp.opcode     = COMP_DBID_RESP;

	   if ( coherency_state == START) begin
	      lc_dat       = 1'b1;
	   end
	   else begin
	      lc_dat       = 1'b0;
	   end
	end
 
      endcase // case ( coherency_state_nxt )
      
   end
   


endmodule // HN_controller
