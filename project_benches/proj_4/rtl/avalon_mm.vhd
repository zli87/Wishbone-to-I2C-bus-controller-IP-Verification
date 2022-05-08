
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Avalon-MM adapter.                                              |
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
entity avalon_mm is
  port
  (
    ------------------------------------
    clk           : in    std_logic;                            -- Clock input
    s_rst         : in    std_logic;                            -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    -- Avalon-MM slave interface:
    waitrequest   :   out std_logic;                            -- Wait request
    readdata      :   out std_logic_vector(31 downto 0);        -- Data from slave to master
    readdatavalid :   out std_logic;                            -- Data validity indication
    writedata     : in    std_logic_vector(31 downto 0);        -- Data from master to slave
    write         : in    std_logic;                            -- Asserted to indicate write transfer
    read          : in    std_logic;                            -- Asserted to indicate read transfer
    byteenable    : in    std_logic_vector( 3 downto 0);        -- Enables specific byte lane(s)
    ------------------------------------
    ------------------------------------
    -- Regblock interface:
    wr            :   out std_logic_vector( 3 downto 0);        -- Write (active high)
    rd            :   out std_logic_vector( 3 downto 0);        -- Read (active high)
    idata         :   out std_logic_vector(31 downto 0);        -- Data from System Bus
    odata         : in    std_logic_vector(31 downto 0)         -- Data for System Bus
    ------------------------------------
  );
end entity avalon_mm;
--==============================================================================

--==============================================================================
architecture rtl of avalon_mm is

begin

  waitrequest <= '0';
  wr          <= (3 downto 0 => write) and byteenable;
  rd          <= (3 downto 0 => read ) and byteenable;
  idata       <= writedata;

  ------------------------------------------------------------------------------
  readdata_proc:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        readdata      <= (others => '0');
        readdatavalid <= '0';
      else
        readdata      <= odata;
        readdatavalid <= read;
      end if;
    end if;
  end process readdata_proc;
  ------------------------------------------------------------------------------

end architecture rtl;
--==============================================================================

