
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Package for internal declarations.                              |
--    Version:                                                                 |
--             1.0,   April 29, 2016                                           |
--                                                                             |
--    Author:  Sergey Shuvalkin, (sshuv2@opencores.org)                        |
--                                                                             |
--==============================================================================
--==============================================================================
-- Copyright (c) 2016, Sergey Shuvalkin                                        |
-- All rights reserved.                                                        |
--                                                                             |
-- Redistribution and use in source and binary forms, with or without          |
-- modification, are permitted provided that the following conditions are met: |
--                                                                             |
-- 1. Redistributions of source code must retain the above copyright notice,   |
--    this list of conditions and the following disclaimer.                    |
-- 2. Redistributions in binary form must reproduce the above copyright        |
--    notice, this list of conditions and the following disclaimer in the      |
--    documentation and/or other materials provided with the distribution.     |
--                                                                             |
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" |
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE   |
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE  |
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE    |
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR         |
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF        |
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS    |
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     |
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)     |
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE  |
-- POSSIBILITY OF SUCH DAMAGE.                                                 |
--==============================================================================


library ieee;
use ieee.std_logic_1164.all;


--==============================================================================
package iicmb_int_pkg is

  ------------------------------------------------------------------------------
  -- Bit-level master mode commands:
  ------------------------------------------------------------------------------
  type mbc_type is
  (
    mbc_start,        -- Start          --> Done | Arbitration Lost
    mbc_stop,         -- Stop           --> Done
    mbc_write_0,      -- Write Bit 0    --> Done | Error
    mbc_write_1,      -- Write Bit 1    --> Done | Arbitration Lost | Error
    mbc_read          -- Read Bit       --> Bit 0 Received | Bit 1 Received | Error
  );
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Bit-level master mode responses:
  ------------------------------------------------------------------------------
  type mbr_type is
  (
    mbr_done,         -- Done
    mbr_arb_lost,     -- Arbitration Lost
    mbr_bit_0,        -- Bit 0 Received
    mbr_bit_1,        -- Bit 1 Received
    mbr_error         -- Error
  );
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Bit-level slave mode commands:
  ------------------------------------------------------------------------------
  type sbc_type is
  (
    sbc_idle,         -- Idle
    sbc_hold,         -- Clock stretching
    sbc_write_0,      -- Write Bit 0
    sbc_write_1,      -- Write Bit 1
    sbc_read          -- Read Bit
  );
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Bit-level slave mode responses:
  ------------------------------------------------------------------------------
  type sbr_type is
  (
    sbr_start,        -- Start
    sbr_stop,         -- Stop
    sbr_bit_0,        -- Bit 0 received
    sbr_bit_1         -- Bit 1 received
  );
  ------------------------------------------------------------------------------

end package iicmb_int_pkg;
--==============================================================================

--==============================================================================
package body iicmb_int_pkg is


end package body iicmb_int_pkg;
--==============================================================================

