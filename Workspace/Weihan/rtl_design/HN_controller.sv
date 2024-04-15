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


module HN_controller (/*AUTOARG*/
   // Outputs
   tx_opcode, trgID, RX_REQLCRDV, RX_RSPLCRDV, RX_DATLCRDV,
   TX_REQFLIT_128, TX_RSPFLIT_128, TX_DATFLIT_128, TX_REQFLITPEND,
   TX_REQFLITV, TX_RSPFLITPEND, TX_RSPFLITV, TX_DATFLITPEND,
   TX_DATFLITV,
   // Inputs
   clk, rstn, rx_opcode, RX_REQFLIT_128, RX_RSPFLIT_128,
   RX_DATFLIT_128, RX_REQFLITPEND, RX_REQFLITV, RX_RSPFLITPEND,
   RX_RSPFLITV, RX_DATFLITPEND, RX_DATFLITV, TX_REQLCRDV, TX_RSPLCRDV,
   TX_DATLCRDV
   ) ;

   input  clk, rstn;

   //
   input  [6:0]  rx_opcode;
   output [6:0]  tx_opcode;
   output [6:0]  trgID;
   
   // CHI in   
   input [127:0] RX_REQFLIT_128, RX_RSPFLIT_128, RX_DATFLIT_128; //128 pkg
   input 	 RX_REQFLITPEND, RX_REQFLITV;                    
   input 	 RX_RSPFLITPEND, RX_RSPFLITV;
   input 	 RX_DATFLITPEND, RX_DATFLITV;
   output 	 RX_REQLCRDV, RX_RSPLCRDV, RX_DATLCRDV;          //L-credit
   // CHI out
   output [127:0] TX_REQFLIT_128, TX_RSPFLIT_128, TX_DATFLIT_128;
   output 	  TX_REQFLITPEND, TX_REQFLITV;   
   output 	  TX_RSPFLITPEND, TX_RSPFLITV;
   output 	  TX_DATFLITPEND, TX_DATFLITV;
   input 	  TX_REQLCRDV, TX_RSPLCRDV, TX_DATLCRDV;         //L-credit
   //
   /*AUTOWIR*/
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			RX_DATLCRDV;
   reg			RX_REQLCRDV;
   reg			RX_RSPLCRDV;
   reg			TX_DATFLITPEND;
   reg			TX_DATFLITV;
   reg [127:0]		TX_DATFLIT_128;
   reg			TX_REQFLITPEND;
   reg			TX_REQFLITV;
   reg [127:0]		TX_REQFLIT_128;
   reg			TX_RSPFLITPEND;
   reg			TX_RSPFLITV;
   reg [127:0]		TX_RSPFLIT_128;
   reg [6:0]		trgID;
   reg [6:0]		tx_opcode;
   // End of automatics
   //************************************************************//

   // 1. Parameters  
   // rx_OPCODE
   parameter
     rx_BLANK = 7'b0000_000,
     ReadShared = 7'b0000_001,
     SnpRspData = 7'b0000_010,
     SnpResp_I  = 7'b0000_011,
     CompData_I = 7'b0000_100,
     CompAck    = 7'b0000_101,
     
     CompDBIDResp_SN = 7'b0001_001,
     CBWrData_I      = 7'b0001_010,
     CBWrData_PD     = 7'b0001_011;

   // tx_OPCODE
   parameter
     tx_BLANK = 7'b1000_000,
     SnpShared    = 7'b1000_001,
     ReadNOSnp    = 7'b1000_010,
     CompData     = 7'b1000_011,
     CompDBIDResp = 7'b1000_100,
     WriteNoSnp   = 7'b1000_101,
     NonCBWrData  = 7'b1000_110;

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
   // 2. reg, cnt, edge
   reg 		     lc_req,lc_dat,lc_rsp;
   reg [bit_Num-1:0] cnt_SnpResp_I;         // counting for num# of SnpResp from RN
   reg [bit_Num-1:0] cnt_lc_rsp;            // counting for cycles should sent

   wire		     falling_edge_RespChannel; // flag : receiving resps from RN
   wire 	     falling_edge_DataChannel; // flag : receiving data  from RN/SN
   reg 		     RX_RSPFLITPEND_d1;
   reg 		     RX_RSPFLITPEND_d2;
   reg 		     RX_DATFLITPEND_d1;
   reg 		     RX_DATFLITPEND_d2;

   
   reg 		     rx_pkg;
   reg 		     tx_pkg;
   
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

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 RX_RSPFLITPEND_d1 <= 0;
	 RX_RSPFLITPEND_d2 <= 0;
	 RX_DATFLITPEND_d1 <= 0;
	 RX_DATFLITPEND_d2 <= 0;
	 
      end
      else begin
	 RX_RSPFLITPEND_d1 <= RX_RSPFLITPEND;
	 RX_RSPFLITPEND_d2 <= RX_RSPFLITPEND_d1;
	 RX_DATFLITPEND_d1 <= RX_DATFLITPEND;
	 RX_DATFLITPEND_d2 <= RX_DATFLITPEND_d1;
      end
   end // always @ (posedge clk or negedge rstn)

   assign falling_edge_RespChannel = (~RX_RSPFLITPEND) & (RX_RSPFLITPEND_d1);
   



   
   /**********************FSM*****************************/
   /********************************************************/
   // State registers for coherency_state
   reg [3:0] 	     coherency_state, coherency_state_nxt;

   // State FF for coherency
   always @ ( posedge clk or negedge rstn ) begin
      if ( !rstn ) begin 
	 coherency_state <= IDLE;
	 cnt_lc_rsp      <= 0;
	 cnt_SnpResp_I <= 0;
	 
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

	 
	 ////cnt_SnpResp_I increase: 0->1->2. based on the Snpresponse from remote RN
	 if(coherency_state == WAIT_RSP && falling_edge_RespChannel==1 && cnt_SnpResp_I < Core_Num-1) begin
	    cnt_SnpResp_I <= cnt_SnpResp_I + 1;
	 end
	 if(cnt_SnpResp_I >= Core_Num-1) begin
	    cnt_SnpResp_I <= 0;
	 end
      end
   end
   

   // Next State Logic for coherency
   always @ ( /*AUTOSENSE*/cnt_SnpResp_I or coherency_state
	     or rx_opcode) begin
      case (coherency_state) 
	IDLE: begin
	   coherency_state_nxt = START;
	end
	
	START: begin  // Important:  we now only think ReadShared case
	   if (rx_opcode == ReadShared) begin
	      coherency_state_nxt = WAIT_RSP;
	   end
	   else begin
	      coherency_state_nxt = START;
	   end	      
	end
	//
	WAIT_RSP : begin
	   if (rx_opcode == SnpRspData) begin
	      coherency_state_nxt = WAIT_ACK;
	   end
	   else begin
	      if (cnt_SnpResp_I == Core_Num-1) begin // the SnpResp received is 0->1->2->3
		 coherency_state_nxt = WAIT_MEM;
	      end
	      else begin
		 coherency_state_nxt = WAIT_RSP;
	      end
	   end	  
	end
	//
	WAIT_MEM : begin
	   if (rx_opcode == CompData_I) begin
	      coherency_state_nxt = WAIT_ACK;
	   end
	   else begin
	      coherency_state_nxt = WAIT_MEM;
	   end
	end
	WAIT_ACK : begin
	   if (rx_opcode == CompAck) begin
	      coherency_state_nxt = START;
	   end
	   else begin
	      coherency_state_nxt = WAIT_ACK;
	   end
	end
	//
	WAIT_DBID : begin
	   if (rx_opcode == CompDBIDResp) begin
	      coherency_state_nxt = START;
	   end
	   else begin
	      coherency_state_nxt = WAIT_DBID;
	   end
	end 
	WAIT_EVIC : begin
	   if (rx_opcode == CBWrData_I) begin
	      coherency_state_nxt = START;
	   end
	   else if (rx_opcode == CBWrData_PD) begin
	      coherency_state_nxt = WAIT_DBID;
	   end
	   else begin
	      coherency_state_nxt = WAIT_EVIC;
	   end
	end 
      endcase
   end


   /*************output logic**************/
   always @ ( /*AUTOSENSE*/cnt_lc_rsp or coherency_state
	     or coherency_state_nxt) begin
      lc_req = 1'b0;
      lc_dat = 1'b0;
      lc_rsp = 1'b0;
      tx_opcode  = 7'b1000_000;
      trgID = 7'b1000_000;
      
      case ( coherency_state_nxt )
	IDLE: begin

	end
	//
	START: begin
	   if ( coherency_state == WAIT_DBID) begin
	      tx_opcode = NonCBWrData;
	   end
	   else if ( coherency_state == IDLE || coherency_state == WAIT_EVIC) begin
	      lc_req = 1'b1;
	   end
	end
	
	//
	WAIT_RSP : begin
	   if ( coherency_state == START ) begin
	      tx_opcode = SnpShared;
	      trgID = RNX;
	      lc_dat = 1'b1;
	   end
	   if ( cnt_lc_rsp < Core_Num-1 ) begin
	      lc_rsp = 1'b1;
	   end
	   

	end 
	
	//
	WAIT_MEM : begin
	   tx_opcode     = ReadNOSnp;
	end
	
	WAIT_ACK : begin
	   tx_opcode     = CompData;
	end
	
	//	
	WAIT_DBID : begin
	   tx_opcode     = WriteNoSnp;
	end
	
	WAIT_EVIC : begin
	   tx_opcode     = CompDBIDResp;

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
