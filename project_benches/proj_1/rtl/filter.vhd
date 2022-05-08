
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Digital filter with hysteresis.                                 |
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
entity filter is
  generic
  (
    g_cycles           :       positive         := 10    -- Number of levels to receive before toggling output
  );
  port
  (
    -------------------------------------
    clk                : in    std_logic;                -- Clock
    s_rst              : in    std_logic;                -- Synchronous reset
    -------------------------------------
    -------------------------------------
    sig_in             : in    std_logic;                -- Input signal
    sig_out            :   out std_logic                 -- Output (filtered) signal
    -------------------------------------
  );
end entity filter;
--==============================================================================

--==============================================================================
architecture rtl of filter is

  signal   sig_out_y : std_logic                   := '1';
  signal   cnt       : integer range 0 to g_cycles := g_cycles;

begin

  ------------------------------------------------------------------------------
  sig_out_y_proc:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        sig_out_y <= '1';
        cnt       <= g_cycles;
      else
        if (sig_in = '1') then
          if (cnt /= g_cycles) then
            cnt <= cnt + 1;
          end if;
        else
          if (cnt /= 0) then
            cnt <= cnt - 1;
          end if;
        end if;

        if (sig_out_y = '1') then
          if (sig_in = '0')and(cnt = 1) then
            sig_out_y <= '0';
          end if;
        else
          if (sig_in = '1')and(cnt = (g_cycles - 1)) then
            sig_out_y <= '1';
          end if;
        end if;
      end if;
    end if;
  end process sig_out_y_proc;
  ------------------------------------------------------------------------------

  sig_out <= sig_out_y;

end rtl;
--==============================================================================

