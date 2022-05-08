
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  I2C Bus busy state monitoring.                                  |
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
entity bus_state is
  generic
  (
    g_f_clk   :       real     := 100000.0;  -- Frequency of 'clk' input (in kHz)
    g_f_scl   :       real     :=    100.0   -- Frequency of 'scl' input (in kHz)
  );
  port
  (
    ------------------------------------
    clk       : in    std_logic;             -- Clock
    s_rst     : in    std_logic;             -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    busy      :   out std_logic;             -- Bus busy indication (busy = high)
    scl_d     :   out std_logic;             -- Delayed I2C Clock signal
    ------------------------------------
    ------------------------------------
    -- Filtered I2C bus signals:
    scl       : in    std_logic;             -- I2C Clock input
    sda       : in    std_logic              -- I2C Data input
    ------------------------------------
  );
end entity bus_state;
--==============================================================================

--==============================================================================
architecture rtl of bus_state is

  ------------------------------------------------------------------------------
  function get_t_buf(a : real) return real is
  begin
    if (a <= 100.0) then
      return 4.7;
    else
      return 1.3;
    end if;
  end function get_t_buf;
  ------------------------------------------------------------------------------

  constant c_t_buf         : real    := get_t_buf(g_f_scl); -- in microseconds
  constant c_t_buf_cnt     : integer := integer((g_f_clk*(c_t_buf/1000.0)) + 0.4999); -- in 'clk' cycles
  constant c_max_cnt       : integer := c_t_buf_cnt;

  signal   scl_d_y         : std_logic                    := '1';
  signal   scl_y           : std_logic;
  signal   sda_d_y         : std_logic                    := '1';
  signal   sda_y           : std_logic;

  signal   sda_cnt         : integer range 0 to c_max_cnt := 0;

  signal   busy_y          : std_logic                    := '0';

  type state_type is (s_free, s_busy, s_guard);
  signal   state           : state_type := s_free;

begin

  scl_y <= to_x01(scl);
  sda_y <= to_x01(sda);

  scl_d <= scl_d_y;

  ------------------------------------------------------------------------------
  -- Monitoring 'scl_i' and 'sda_i' inputs
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        scl_d_y <= '1';
        sda_d_y <= '1';
        sda_cnt <= 0;
      else
        scl_d_y <= scl_y;
        sda_d_y <= sda_y;

        if (sda_d_y /= sda_y) then
          sda_cnt <= 1;
        elsif (sda_cnt /= c_max_cnt) then
          sda_cnt <= sda_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  state_proc:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        state  <= s_free;
        busy_y <= '0';
      else
        case state is
          when s_free =>
            busy_y <= '0';
            if (scl_y = '1')and(sda_d_y = '1')and(sda_y = '0') then
              state  <= s_busy;
              busy_y <= '1';
            end if;
          when s_busy =>
            busy_y <= '1';
            if (scl_y = '1')and(sda_d_y = '0')and(sda_y = '1') then
              state  <= s_guard;
            end if;
          when s_guard =>
            busy_y <= '1';
            if (sda_d_y = '1')and(scl_d_y = '1')and(sda_cnt = c_t_buf_cnt) then
              state  <= s_free;
              busy_y <= '0';
            end if;
        end case;
      end if;
    end if;
  end process state_proc;
  ------------------------------------------------------------------------------

  busy     <= busy_y;

end architecture rtl;
--==============================================================================

