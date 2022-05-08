
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Main package.                                                   |
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
use ieee.numeric_std.all;


--==============================================================================
package iicmb_pkg is

  ------------------------------------------------------------------------------
  -- Byte level master mode commands' codes:
  ------------------------------------------------------------------------------
  -- Start                           --> Done | Arbitration Lost
  -- Byte Write                      --> Done | Write Not Acknowledged | Arbitration Lost | Error
  -- Byte Read                       --> Byte Received | Error
  -- Byte Read with Not-Acknowledge  --> Byte Received | Arbitration Lost | Error
  -- Stop                            --> Done
  -- Set Bus                         --> Done | Error
  -- Wait                            --> Done | Error
  constant mcmd_wait     : std_logic_vector(2 downto 0) := "000";
  constant mcmd_write    : std_logic_vector(2 downto 0) := "001";
  constant mcmd_read_ack : std_logic_vector(2 downto 0) := "010";
  constant mcmd_read_nak : std_logic_vector(2 downto 0) := "011";
  constant mcmd_start    : std_logic_vector(2 downto 0) := "100";
  constant mcmd_stop     : std_logic_vector(2 downto 0) := "101";
  constant mcmd_set_bus  : std_logic_vector(2 downto 0) := "110";
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Byte level master mode responses' codes:
  ------------------------------------------------------------------------------
  -- Done
  -- Byte received
  -- Write Not Acknowledged
  -- Arbitration lost
  -- Error
  constant mrsp_done     : std_logic_vector(2 downto 0) := "000";
  constant mrsp_nak      : std_logic_vector(2 downto 0) := "001";
  constant mrsp_arb_lost : std_logic_vector(2 downto 0) := "010";
  constant mrsp_error    : std_logic_vector(2 downto 0) := "011";
  constant mrsp_byte     : std_logic_vector(2 downto 0) := "100";
  ------------------------------------------------------------------------------


  ------------------------------------------------------------------------------
  -- Sequencer related stuff ---------------------------------------------------
  type seq_cmd_id is (seq_wait, seq_set_bus, seq_write_byte);
  type seq_cmd_type is record
    id    : seq_cmd_id;
    saddr : std_logic_vector(6 downto 0);
    daddr : std_logic_vector(7 downto 0);
    data  : std_logic_vector(7 downto 0);
  end record;
  constant c_seq_cmd_default : seq_cmd_type := (id => seq_wait, others => (others => '0'));
  type seq_cmd_type_array is array (natural range <>) of seq_cmd_type;
  constant c_empty_array : seq_cmd_type_array(0 to 0) := (others => c_seq_cmd_default); -- not really empty

  function scmd_wait(a : integer range 0 to 255) return seq_cmd_type;
  function scmd_set_bus(a : integer range 0 to 15) return seq_cmd_type;
  function scmd_write_byte(sa : std_logic_vector(6 downto 0);
                           da : std_logic_vector(7 downto 0);
                           d  : std_logic_vector(7 downto 0)) return seq_cmd_type;
  -- End of sequencer related stuff --------------------------------------------
  ------------------------------------------------------------------------------

end package iicmb_pkg;
--==============================================================================

--==============================================================================
package body iicmb_pkg is

  ------------------------------------------------------------------------------
  function scmd_wait(a : integer range 0 to 255) return seq_cmd_type is
    variable ret : seq_cmd_type;
  begin
    ret.id    := seq_wait;
    ret.saddr := (others => '0');
    ret.daddr := (others => '0');
    ret.data  := std_logic_vector(to_unsigned(a, 8));
    return ret;
  end function scmd_wait;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  function scmd_set_bus(a : integer range 0 to 15) return seq_cmd_type is
    variable ret : seq_cmd_type;
  begin
    ret.id    := seq_set_bus;
    ret.saddr := (others => '0');
    ret.daddr := (others => '0');
    ret.data  := std_logic_vector(to_unsigned(a, 8));
    return ret;
  end function scmd_set_bus;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  function scmd_write_byte(sa : std_logic_vector(6 downto 0);
                           da : std_logic_vector(7 downto 0);
                           d  : std_logic_vector(7 downto 0)) return seq_cmd_type is
    variable ret : seq_cmd_type;
  begin
    ret.id    := seq_write_byte;
    ret.saddr := sa;
    ret.daddr := da;
    ret.data  := d;
    return ret;
  end function scmd_write_byte;
  ------------------------------------------------------------------------------

end package body iicmb_pkg;
--==============================================================================

