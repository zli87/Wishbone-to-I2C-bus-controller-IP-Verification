
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Byte layer FSM (master mode).                                   |
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

use work.iicmb_pkg.all;
use work.iicmb_int_pkg.all;


--==============================================================================
entity mbyte is
  generic
  (
    ------------------------------------
    g_bus_num   :       positive range 1 to 16 := 1;               -- Number of separate I2C buses
    g_f_clk     :       real                   := 100000.0         -- Frequency of system clock 'clk' (in kHz)
    ------------------------------------
  );
  port
  (
    ------------------------------------
    clk         : in    std_logic;                                 -- Clock
    s_rst       : in    std_logic;                                 -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    captured    :   out std_logic := '0';                          -- 'Bus is captured' indication (captured = high)
    busy        : in    std_logic;                                 -- 'Bus is busy' indication (busy = high)
    bus_id      :   out natural range 0 to g_bus_num - 1 := 0;     -- Bus selector
    fsm_state   :   out std_logic_vector(3 downto 0);              -- FSM state
    ------------------------------------
    ------------------------------------
    mcmd_wr     : in    std_logic;                                 -- Byte command write (active high)
    mcmd_id     : in    std_logic_vector(2 downto 0);              -- Byte command ID
    mcmd_data   : in    std_logic_vector(7 downto 0);              -- Byte command data
    ------------------------------------
    ------------------------------------
    mrsp_wr     :   out std_logic                    := '0';       -- Byte command response write (active high)
    mrsp_id     :   out std_logic_vector(2 downto 0) := mrsp_done; -- Byte command response control bit
    mrsp_data   :   out std_logic_vector(7 downto 0);              -- Byte command response data
    ------------------------------------
    ------------------------------------
    mbc_wr      :   out std_logic                    := '0';       -- Bit command write (active high)
    mbc         :   out mbc_type                     := mbc_stop;  -- Bit command
    ------------------------------------
    ------------------------------------
    mbr_wr      : in    std_logic;                                 -- Bit command response write (active high)
    mbr         : in    mbr_type                                   -- Bit command response
    ------------------------------------
  );
end entity mbyte;
--==============================================================================

--==============================================================================
architecture rtl of mbyte is

  constant c_cycle_cnt_inc : integer := 1;
  constant c_cycle_cnt_max : integer := integer(g_f_clk);
  constant c_cycle_cnt_thr : integer := c_cycle_cnt_max - c_cycle_cnt_inc;

  type state_type is
  (
    s_idle,          -- Idle
    s_bus_taken,     -- Bus is taken
    s_start_pending, -- Waiting for right moment to capture bus
    s_start,         -- Sending Start Condition (Capturing the bus)
    s_stop,          -- Sending Stop Condition (Releasing the bus)
    s_write,         -- Sending a byte
    s_read,          -- Receiving a byte
    s_wait           -- Receiving a byte
  );

  ------------------------------------------------------------------------------
  -- Converting states to std_logic_vector
  function to_std_logic_vector(a : state_type) return std_logic_vector is
  begin
    case (a) is
      when s_idle          => return "0000";
      when s_bus_taken     => return "0001";
      when s_start_pending => return "0010";
      when s_start         => return "0011";
      when s_stop          => return "0100";
      when s_write         => return "0101";
      when s_read          => return "0110";
      when s_wait          => return "0111";
    end case;
  end function to_std_logic_vector;
  ------------------------------------------------------------------------------

  signal   state           : state_type                         := s_idle;
  signal   cnt             : integer range 0 to 8               := 0;
  signal   sbuf            : std_logic_vector(7 downto 0)       := (others => '0');
  signal   ack             : std_logic                          := '0';
  signal   cycle_cnt       : integer range 0 to c_cycle_cnt_max := 0;
  signal   ms_cnt          : unsigned( 7 downto 0)              := to_unsigned(0, 8);

begin

  mrsp_data <= sbuf;
  fsm_state <= to_std_logic_vector(state);

  ------------------------------------------------------------------------------
  -- Main FSM:
  main_fsm_proc:
  process(clk)
    ---------
    procedure bit_command(a : mbc_type) is
    begin
      mbc_wr <= '1';
      mbc    <= a;
    end procedure bit_command;
    ---------
    ---------
    procedure bit_command(a : std_logic) is
    begin
      mbc_wr <= '1';
      if (a = '0') then
        mbc <= mbc_write_0;
      else
        mbc <= mbc_write_1;
      end if;
    end procedure bit_command;
    ---------
    ---------
    function get_bit(a : mbr_type) return std_logic is
    begin
      if (a = mbr_bit_0) then
        return '0';
      else
        return '1';
      end if;
    end function get_bit;
    ---------
    ---------
    procedure byte_response(a : std_logic_vector(2 downto 0)) is
    begin
      mrsp_wr <= '1';
      mrsp_id <= a;
    end procedure byte_response;
    ---------
    variable v_bus_id   : integer range 0 to 15;
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        state     <= s_idle;
        cnt       <= 0;
        sbuf      <= (others => '0');
        ack       <= '0';
        mbc_wr    <= '0';
        mbc       <= mbc_stop;
        mrsp_wr   <= '0';
        mrsp_id   <= mrsp_done;
        bus_id    <= 0;
        captured  <= '0';
        cycle_cnt <= 0;
        ms_cnt    <= to_unsigned(0, 8);
      else
        -- Default:
        mbc_wr    <= '0';
        mrsp_wr   <= '0';
        ------

        case (state) is
          -- 'Idle' state ----------------------------------
          when s_idle =>
            if (mcmd_wr = '1') then
              case (mcmd_id) is
                when mcmd_start =>
                  -- Begin procedure of bus capturing
                  state     <= s_start_pending;
                when mcmd_set_bus =>
                  -- Switch to another bus
                  state     <= s_idle;
                  v_bus_id  := to_integer(unsigned(mcmd_data(3 downto 0)));
                  if (v_bus_id > (g_bus_num - 1)) then
                    byte_response(mrsp_error);
                  else
                    bus_id    <= v_bus_id;
                    byte_response(mrsp_done);
                  end if;
                when mcmd_wait =>
                  -- Wait for specified period:
                  state     <= s_wait;
                  cycle_cnt <= 0;
                  ms_cnt    <= unsigned(mcmd_data);
                when others =>
                  -- Other commands are rejected in 'Idle' state
                  state     <= s_idle;
                  byte_response(mrsp_error);
              end case;
              cnt       <= 0;
            end if;
            captured  <= '0';
          -- 'Idle' state ----------------------------------

          -- 'Wait' state ----------------------------------
          when s_wait =>
            captured  <= '0';
            if (ms_cnt = 0) then
              state     <= s_idle;
              byte_response(mrsp_done);
            else
              if (cycle_cnt < c_cycle_cnt_thr) then
                cycle_cnt <= cycle_cnt + c_cycle_cnt_inc;
              else
                cycle_cnt <= cycle_cnt - c_cycle_cnt_thr;
                ms_cnt    <= ms_cnt - 1;
              end if;
            end if;
          -- 'Wait' state ----------------------------------

          -- 'Bus is Taken' state --------------------------
          when s_bus_taken =>
            if (mcmd_wr = '1') then
              case (mcmd_id) is
                when mcmd_start =>
                  -- Generate Repeated Start condition
                  state     <= s_start;
                  bit_command(mbc_start);
                when mcmd_read_ack =>
                  -- Byte reading with acknowledge
                  state     <= s_read;
                  ack       <= '0';
                  bit_command(mbc_read);
                when mcmd_read_nak =>
                  -- Byte reading with not-acknowledge
                  state     <= s_read;
                  ack       <= '1';
                  bit_command(mbc_read);
                when mcmd_stop =>
                  -- Issue Stop condition
                  state     <= s_stop;
                  bit_command(mbc_stop);
                when mcmd_write =>
                  -- Byte writing
                  state     <= s_write;
                  sbuf      <= mcmd_data(6 downto 0) & '0';
                  bit_command(mcmd_data(7));
                when others =>
                  -- Other commands are rejected in 'Bus Is Taken' state
                  state     <= s_bus_taken;
                  byte_response(mrsp_error);
              end case;
              cnt       <= 0;
            end if;
            captured <= '1';
          -- 'Bus is Taken' state --------------------------

          -- 'Start is Pending' state ----------------------
          when s_start_pending =>
            captured  <= '0';
            if (busy = '0') then
              state     <= s_start;
              bit_command(mbc_start);
            end if;
          -- 'Start is Pending' state ----------------------

          -- 'Start' state ---------------------------------
          when s_start =>
            if (mbr_wr = '1') then
              if (mbr = mbr_done) then
                state     <= s_bus_taken;
                captured  <= '1';
                byte_response(mrsp_done);
              else
                -- (mbr = mbr_arb_lost)
                state     <= s_idle;
                captured  <= '0';
                byte_response(mrsp_arb_lost);
              end if;
            end if;
          -- 'Start' state ---------------------------------

          -- 'Stop' state ----------------------------------
          when s_stop =>
            captured  <= '1';
            if (mbr_wr = '1') then
              state     <= s_idle;
              captured  <= '0';
              byte_response(mrsp_done);
            end if;
          -- 'Stop' state ----------------------------------

          -- 'Byte Reading' state --------------------------
          when s_read =>
            captured  <= '1';
            if (mbr_wr = '1') then
              case (cnt) is
                when 8 =>
                  if (mbr = mbr_done) then
                    -- Return to 'Bus Is Taken' state and
                    -- respond with a byte of data.
                    state     <= s_bus_taken;
                    byte_response(mrsp_byte);
                  else
                    -- (mbr = mbr_arb_lost)
                    state     <= s_idle;
                    captured  <= '0';
                    byte_response(mrsp_arb_lost);
                  end if;
                when others =>
                  if (mbr = mbr_error) then
                    state     <= s_idle;
                    captured  <= '0';
                    byte_response(mrsp_error);
                  else
                    -- (mbr = mbr_bit_0)or(mbr = mbr_bit_1)
                    sbuf      <= sbuf(6 downto 0) & get_bit(mbr);
                    cnt       <= cnt + 1;
                    if (cnt = 7) then
                      -- Write Ack/Nak
                      bit_command(ack);
                    else
                      -- Read a bit
                      bit_command(mbc_read);
                    end if;
                  end if;
              end case;
            end if;
          -- 'Byte Reading' state --------------------------

          -- 'Byte Writing' state --------------------------
          when s_write =>
            captured  <= '1';
            if (mbr_wr = '1') then
              case (cnt) is
                when 8 =>
                  state     <= s_bus_taken;
                  if (mbr = mbr_error) then
                    -- Something went wrong
                    state     <= s_idle;
                    captured  <= '0';
                    byte_response(mrsp_error);
                  elsif (mbr = mbr_bit_0) then
                    -- Write is acknowledged
                    byte_response(mrsp_done);
                  else
                    -- Write is not acknowledged
                    byte_response(mrsp_nak);
                  end if;
                when others =>
                  if (mbr = mbr_done) then
                    sbuf      <= sbuf(6 downto 0) & '0';
                    cnt       <= cnt + 1;
                    if (cnt = 7) then
                      -- Read Ack/Nak
                      bit_command(mbc_read);
                    else
                      -- Write a bit
                      bit_command(sbuf(7));
                    end if;
                  else
                    -- (mbr = mbr_arb_lost)
                    state     <= s_idle;
                    captured  <= '0';
                    byte_response(mrsp_arb_lost);
                  end if;
              end case;
            end if;
          -- 'Byte Writing' state --------------------------
        end case;
      end if;
    end if;
  end process main_fsm_proc;
  ------------------------------------------------------------------------------

end architecture rtl;
--==============================================================================

