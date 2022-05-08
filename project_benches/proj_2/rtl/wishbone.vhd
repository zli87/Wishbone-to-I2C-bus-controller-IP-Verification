
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Wishbone adapter.                                               |
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
entity wishbone is
  port
  (
    ------------------------------------
    clk_i       : in    std_logic;                              -- Clock input
    rst_i       : in    std_logic;                              -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    -- Wishbone slave interface:
    cyc_i       : in    std_logic;                              -- Valid bus cycle indication
    stb_i       : in    std_logic;                              -- Slave selection
    ack_o       :   out std_logic;                              -- Acknowledge output
    adr_i       : in    std_logic_vector( 1 downto 0);          -- Low bits of Wishbone address
    we_i        : in    std_logic;                              -- Write enable
    dat_i       : in    std_logic_vector( 7 downto 0);          -- Data input
    dat_o       :   out std_logic_vector( 7 downto 0);          -- Data output
    ------------------------------------
    ------------------------------------
    -- Regblock interface:
    wr          :   out std_logic_vector( 3 downto 0);          -- Write (active high)
    rd          :   out std_logic_vector( 3 downto 0);          -- Read (active high)
    idata       :   out std_logic_vector(31 downto 0);          -- Data from System Bus
    odata       : in    std_logic_vector(31 downto 0)           -- Data to System Bus
    ------------------------------------
  );
end entity wishbone;
--==============================================================================

--==============================================================================
architecture rtl of wishbone is

  signal ack_o_y      : std_logic                    := '0';
  signal dat_o_y      : std_logic_vector(7 downto 0) := (others => '0');

begin

  ack_o   <= ack_o_y;
  dat_o   <= dat_o_y;

  ------------------------------------------------------------------------------
  ack_o_proc:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        ack_o_y <= '0';
      else
        if (ack_o_y = '0') then
          ack_o_y <= stb_i and cyc_i;
        else
          ack_o_y <= '0';
        end if;
      end if;
    end if;
  end process ack_o_proc;
  ------------------------------------------------------------------------------

  wr(0) <= stb_i and cyc_i and     we_i  and not(ack_o_y) when (adr_i = "00") else '0';
  wr(1) <= stb_i and cyc_i and     we_i  and not(ack_o_y) when (adr_i = "01") else '0';
  wr(2) <= stb_i and cyc_i and     we_i  and not(ack_o_y) when (adr_i = "10") else '0';
  wr(3) <= stb_i and cyc_i and     we_i  and not(ack_o_y) when (adr_i = "11") else '0';
  rd(0) <= stb_i and cyc_i and not(we_i) and not(ack_o_y) when (adr_i = "00") else '0';
  rd(1) <= stb_i and cyc_i and not(we_i) and not(ack_o_y) when (adr_i = "01") else '0';
  rd(2) <= stb_i and cyc_i and not(we_i) and not(ack_o_y) when (adr_i = "10") else '0';
  rd(3) <= stb_i and cyc_i and not(we_i) and not(ack_o_y) when (adr_i = "11") else '0';
  idata <= dat_i & dat_i & dat_i & dat_i;

  ------------------------------------------------------------------------------
  dat_o_proc:
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        dat_o_y <= (others => '0');
      else
        case (adr_i) is
          when "00"   => dat_o_y <= odata( 7 downto  0);
          when "01"   => dat_o_y <= odata(15 downto  8);
          when "10"   => dat_o_y <= odata(23 downto 16);
          when others => dat_o_y <= odata(31 downto 24);
        end case;
      end if;
    end if;
  end process dat_o_proc;
  ------------------------------------------------------------------------------

end architecture rtl;
--==============================================================================

