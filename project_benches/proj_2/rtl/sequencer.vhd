
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Command sequencer for 'iicmb_m'.                                |
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

use work.iicmb_pkg.all;


--==============================================================================
entity sequencer is
  generic
  (
    g_cmd       :       seq_cmd_type_array := c_empty_array   -- Sequence of commands (supported: WAIT, SET_BUS and WRITE_BYTE)
  );
  port
  (
    ------------------------------------
    clk         : in    std_logic;                            -- Clock input
    s_rst       : in    std_logic;                            -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    cs_start    : in    std_logic;                            -- Start executing command sequence
    cs_busy     :   out std_logic;                            -- Command sequence is being executed
    cs_status   :   out std_logic_vector(2 downto 0);         -- Execution status
    ------------------------------------
    ------------------------------------
    -- Status:
    busy        : in    std_logic;                            -- Bus busy status
    captured    : in    std_logic;                            -- Bus captured status
    bus_id      : in    std_logic_vector(3 downto 0);         -- ID of selected I2C bus
    bit_state   : in    std_logic_vector(3 downto 0);         -- State of bit level FSM
    byte_state  : in    std_logic_vector(3 downto 0);         -- State of byte level FSM
    ------------------------------------
    ------------------------------------
    -- 'Generic interface' signals:
    mcmd_wr     :   out std_logic;                            -- Byte command write (active high)
    mcmd_id     :   out std_logic_vector(2 downto 0);         -- Byte command ID
    mcmd_data   :   out std_logic_vector(7 downto 0);         -- Command data
    --
    mrsp_wr     : in    std_logic;                            -- Byte response write (active high)
    mrsp_id     : in    std_logic_vector(2 downto 0);         -- Byte response ID
    mrsp_data   : in    std_logic_vector(7 downto 0)          -- Response data
    ------------------------------------
  );
end entity sequencer;
--==============================================================================

--==============================================================================
architecture rtl of sequencer is

  type cmd_type_array is array (natural range <>) of std_logic_vector(10 downto 0);

  ------------------------------------------------------------------------------
  function get_cmd_seq_length(a : seq_cmd_type_array) return natural is
    variable v_ret : natural := 0;
  begin
    for i in a'range loop
      case a(i).id is
        when seq_wait       => v_ret := v_ret + 1;
        when seq_set_bus    => v_ret := v_ret + 1;
        when seq_write_byte => v_ret := v_ret + 5;
      end case;
    end loop;
    return v_ret;
  end function get_cmd_seq_length;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  function get_cmd_seq(a : seq_cmd_type_array) return cmd_type_array is
    variable v_ret : cmd_type_array(0 to (get_cmd_seq_length(a) - 1));
    variable j : integer;
  begin
    j := 0;
    for i in a'range loop
      case a(i).id is
        when seq_wait       =>
          v_ret(j) := mcmd_wait & a(i).data;
          j := j + 1;
        when seq_set_bus    =>
          v_ret(j) := mcmd_set_bus & a(i).data;
          j := j + 1;
        when seq_write_byte =>
          v_ret(j + 0) := mcmd_start & x"00";
          v_ret(j + 1) := mcmd_write & a(i).saddr & "0";
          v_ret(j + 2) := mcmd_write & a(i).daddr;
          v_ret(j + 3) := mcmd_write & a(i).data;
          v_ret(j + 4) := mcmd_stop  & x"00";
          j := j + 5;
      end case;
    end loop;
    return v_ret;
  end function get_cmd_seq;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Sequence of commands to execute:
  constant cmd_seq   : cmd_type_array := get_cmd_seq(g_cmd);
  ------------------------------------------------------------------------------

  type state_type is (s_idle, s_active);
  signal   state     : state_type                        := s_idle;
  signal   cmd_cnt   : integer range 0 to cmd_seq'length := 0;

begin

  ------------------------------------------------------------------------------
  state_proc:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        state     <= s_idle;
        cmd_cnt   <= 0;
        cs_busy   <= '0';
        cs_status <= mrsp_done;
        mcmd_wr   <= '0';
        mcmd_id   <= "000";
        mcmd_data <= "00000000";
      else
        -- Defaults:
        mcmd_wr   <= '0';

        -- FSM:
        case state is
          -------------- 's_idle' state ------------------------
          when s_idle   =>
            cs_busy   <= '0';
            if (cs_start = '1') then
              if (cmd_cnt = cmd_seq'length) then
                cs_status <= mrsp_done;
                cmd_cnt   <= 0;
              else
                state     <= s_active;
                cmd_cnt   <= cmd_cnt + 1;
                cs_busy   <= '1';
                mcmd_wr   <= '1';
                mcmd_id   <= cmd_seq(cmd_cnt)(10 downto 8);
                mcmd_data <= cmd_seq(cmd_cnt)( 7 downto 0);
              end if;
            end if;
          -------------- 's_idle' state ------------------------

          -------------- 's_active' state ----------------------
          when s_active =>
            cs_busy   <= '1';
            if (mrsp_wr = '1') then
              case mrsp_id is
                when mrsp_nak | mrsp_arb_lost | mrsp_error =>
                  state     <= s_idle;
                  cmd_cnt   <= 0;
                  cs_busy   <= '0';
                  cs_status <= mrsp_id;
                when others        =>
                  if (cmd_cnt = cmd_seq'length) then
                    state     <= s_idle;
                    cmd_cnt   <= 0;
                    cs_busy   <= '0';
                    cs_status <= mrsp_done;
                  else
                    cmd_cnt   <= cmd_cnt + 1;
                    mcmd_wr   <= '1';
                    mcmd_id   <= cmd_seq(cmd_cnt)(10 downto 8);
                    mcmd_data <= cmd_seq(cmd_cnt)( 7 downto 0);
                  end if;
              end case;
            end if;
          -------------- 's_active' state ----------------------
        end case;
      end if;
    end if;
  end process state_proc;
  ------------------------------------------------------------------------------

end architecture rtl;
--==============================================================================

