/* 

   This code is built on top of the CacheCore and SMPCache code from  
   
   Sesc: Super ESCalar simulator
   Copyright (C) 2003 University of Illinois.
   
   This file was Created by Brandon Lucia
   

This file is based on a part of SESC.
SESC is free software; you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation;
either version 2, or (at your option) any later version.
SESC is    distributed in the  hope that  it will  be  useful, but  WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.
You should  have received a copy of  the GNU General  Public License along with
SESC; see the file COPYING.  If not, write to the  Free Software Foundation, 59
Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef SIMPLESMPCACHESTATE_H
#define SIMPLESMPCACHESTATE_H

#include "CacheCore.h"
// these states are the most basic ones you can have
// all classes that inherit from this class should 
// have at least the following states and bits, with the same encoding

enum MOESIState_t {
  MOESI_MODIFIED          = 0x00000001,
  MOESI_SHARED            = 0x00000010,
  MOESI_INVALID           = 0x00000100,
  MOESI_EXCLUSIVE         = 0x00001000,
  MOESI_OWNED             = 0x00010000
};

class MOESI_SMPCacheState : public StateGeneric<> {

private:
protected:

  //You can add other state that should be 
  //maintained for each cache line here
  //e.g.: bool from_untrusted_source
  //or whatever.
  
public:
  MOESI_SMPCacheState() : StateGeneric<>() {
    state = (unsigned)MOESI_INVALID;
  }

  // BEGIN CacheCore interface 
  bool isValid() const {
    return (state != (unsigned)MOESI_INVALID);
  }

  void invalidate() {
    clearTag();
    state = (unsigned)MOESI_INVALID;
  }
    
  bool isLocked() const {
    return false;
  }
  // END CacheCore interface

  unsigned getState() const {
    return state;
  }

  void changeStateTo(MOESIState_t newstate) {
    // not supposed to invalidate through this interface
    //I(newstate != (unsigned)MOESI_INVALID);
    state = (unsigned)newstate;
  }

};

#endif //SMPCACHESTATE_H
