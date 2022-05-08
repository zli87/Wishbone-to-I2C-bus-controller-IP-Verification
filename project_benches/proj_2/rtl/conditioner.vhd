
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Signal conditioner.                                             |
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
entity conditioner is
  generic
  (
    ------------------------------------
    g_f_clk   :       real   := 100000.0; -- Frequency of 'clk' input (in kHz)
    g_f_scl   :       real   :=    100.0  -- Frequency of 'scl_i' input (in kHz)
    ------------------------------------
  );
  port
  (
    ------------------------------------
    clk       : in    std_logic;         -- Clock
    s_rst     : in    std_logic;         -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    -- Interface to I2C FSMs:
    busy      :   out std_logic;         -- Bus busy indication (busy = high)
    --
    scl_rx    :   out std_logic;         -- Filtered I2C Clock
    sda_rx    :   out std_logic;         -- Filtered I2C Data
    --
    scl_d_rx  :   out std_logic;         -- Filtered and delayed I2C Clock
    --
    scl_tx    : in    std_logic;         -- I2C Clock from FSMs
    sda_tx    : in    std_logic;         -- I2C Data from FSMs
    ------------------------------------
    ------------------------------------
    -- I2C bus signals:
    scl_i     : in    std_logic;         -- I2C Clock input
    sda_i     : in    std_logic;         -- I2C Data input
    scl_o     :   out std_logic;         -- I2C Clock output
    sda_o     :   out std_logic          -- I2C Data output
    ------------------------------------
  );
end entity conditioner;
--==============================================================================

--==============================================================================
architecture str of conditioner is

  ------------------------------------------------------------------------------
  component bus_state is
    generic
    (
      g_f_clk   :       real     := 100000.0;
      g_f_scl   :       real     :=    100.0
    );
    port
    (
      clk       : in    std_logic;
      s_rst     : in    std_logic;
      busy      :   out std_logic;
      scl_d     :   out std_logic;
      scl       : in    std_logic;
      sda       : in    std_logic
    );
  end component bus_state;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  component filter is
    generic
    (
      g_cycles           :       positive         := 10
    );
    port
    (
      clk                : in    std_logic;
      s_rst              : in    std_logic;
      sig_in             : in    std_logic;
      sig_out            :   out std_logic
    );
  end component filter;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  function get_cycles(a : real) return positive is
    variable ret : positive;
  begin
    ret := 4 + integer((4.0*a)/50000.0);
    return ret;
  end function get_cycles;
  ------------------------------------------------------------------------------

  constant c_cycles      : positive := get_cycles(g_f_clk);

  signal   scl_i_ndeb_1  : std_logic;
  signal   sda_i_ndeb_1  : std_logic;
  signal   scl_i_ndeb_2  : std_logic;
  signal   sda_i_ndeb_2  : std_logic;
  signal   scl_i_deb     : std_logic;
  signal   sda_i_deb     : std_logic;

begin

  -- ###########################################################################
  -- # Debouncing SCL and SDA signals                                          #
  -- ###########################################################################
  ------------------------------------------------------------------------------
  -- Metastability elimination:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        scl_i_ndeb_1 <= '1';
        scl_i_ndeb_2 <= '1';
        sda_i_ndeb_1 <= '1';
        sda_i_ndeb_2 <= '1';
      else
        scl_i_ndeb_1 <= to_x01(scl_i);
        scl_i_ndeb_2 <= scl_i_ndeb_1;
        sda_i_ndeb_1 <= to_x01(sda_i);
        sda_i_ndeb_2 <= sda_i_ndeb_1;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  scl_filter : filter
    generic map
    (
      g_cycles           => c_cycles
    )
    port map
    (
      clk                => clk,
      s_rst              => s_rst,
      sig_in             => scl_i_ndeb_2,
      sig_out            => scl_i_deb
    );
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  sda_filter : filter
    generic map
    (
      g_cycles           => c_cycles
    )
    port map
    (
      clk                => clk,
      s_rst              => s_rst,
      sig_in             => sda_i_ndeb_2,
      sig_out            => sda_i_deb
    );
  ------------------------------------------------------------------------------
  -- ###########################################################################
  -- # End of debouncing SCL and SDA signals                                   #
  -- ###########################################################################

  ------------------------------------------------------------------------------
  bus_state_inst0 : bus_state
    generic map
    (
      g_f_clk   => g_f_clk,
      g_f_scl   => g_f_scl
    )
    port map
    (
      clk       => clk,
      s_rst     => s_rst,
      busy      => busy,
      scl_d     => scl_d_rx,
      scl       => scl_i_deb,
      sda       => sda_i_deb
    );
  ------------------------------------------------------------------------------

  scl_rx <= scl_i_deb;
  sda_rx <= sda_i_deb;
  scl_o  <= scl_tx;
  sda_o  <= sda_tx;

end architecture str;
--==============================================================================

