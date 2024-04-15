/*********************testbench*************************/
parameter CLK_2_5=2.5; // 200MHz


/*************************design********************************/
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
     RNX = 7'b1111_111,
     SN  = 7'b0010_000;

