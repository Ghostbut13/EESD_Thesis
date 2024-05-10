// =============================================================================
//
//            Copyright (c) 2019 CHALMERS University of Technology
//                             All rights reserved
//
// This file contains CHALMERS proprietary and confidential information 
// and has been developed by CHALMERS within the EPI-SGA1 Project (GA 826647). 
// The permission rights for this file are governed by the EPI Grant Agreement 
// and the EPI Consortium Agreement.
//
// ===============================[ INFORMATION ]===============================
//
// Author(s)  : Bhavishya Goel
// Contact(s) : goelb@chalmers.se
//
// Summary    : L1C parameters for verification
// Created    : 06/03/2022
// Modified   : 
//
// ===============================[ DESCRIPTION ]===============================
//
// Package for defining L1 Data cache parameters used for HN UVM verification
//
// =============================================================================

package l1c_mems_config_pkg;

  parameter int unsigned L1C_DATA_WIDTH = 512;
  
  parameter int unsigned L1C_STALL_LIMIT = 16;
  parameter int unsigned L1C_PT_LIMIT = 16;
  parameter int unsigned L1C_VB_LIMIT = 16;
  
  parameter int unsigned L1C_SET_NUM = 512;
  parameter int unsigned L1C_INDEX_WIDTH = $clog2(L1C_SET_NUM);
  
  parameter int unsigned L1C_ADDR_WIDTH = 48;
  
  parameter int unsigned L1C_OFFSET = 6;
  //parameter int unsigned L1C_OFFSET_WIDTH = $clog2(L1C_OFFSET);
  
  parameter int unsigned L1C_IDXOFFSET_WIDTH = L1C_OFFSET + L1C_INDEX_WIDTH;
  
  parameter int unsigned L1C_TAG_WIDTH = (L1C_ADDR_WIDTH - L1C_INDEX_WIDTH - L1C_OFFSET);
  parameter int unsigned L1C_WAY_NUM = 1;

endpackage : l1c_mems_config_pkg
