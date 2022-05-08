
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Multiplexer of I2C buses.                                       |
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
entity conditioner_mux is
  generic
  (
    ------------------------------------
    g_bus_num :       positive range 1 to 16 := 1;          -- Number of separate I2C busses
    g_f_clk   :       real           := 100000.0;   -- Frequency of 'clk' clock (in kHz)
    g_f_scl_0 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #0 (in kHz)
    g_f_scl_1 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #1 (in kHz)
    g_f_scl_2 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #2 (in kHz)
    g_f_scl_3 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #3 (in kHz)
    g_f_scl_4 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #4 (in kHz)
    g_f_scl_5 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #5 (in kHz)
    g_f_scl_6 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #6 (in kHz)
    g_f_scl_7 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #7 (in kHz)
    g_f_scl_8 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #8 (in kHz)
    g_f_scl_9 :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #9 (in kHz)
    g_f_scl_a :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #10 (in kHz)
    g_f_scl_b :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #11 (in kHz)
    g_f_scl_c :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #12 (in kHz)
    g_f_scl_d :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #13 (in kHz)
    g_f_scl_e :       real           :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #14 (in kHz)
    g_f_scl_f :       real           :=    100.0    -- Frequency of 'SCL' clock of I2C bus #15 (in kHz)
    ------------------------------------
  );
  port
  (
    ------------------------------------
    clk       : in    std_logic;                            -- Clock
    s_rst     : in    std_logic;                            -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    -- Interface to controller:
    bus_id    : in    natural range 0 to g_bus_num - 1;
    --
    busy      :   out std_logic := '0';                     -- Bus busy indication (busy = high)
    --
    scl_rx    :   out std_logic := '1';                     -- Conditioned I2C Clock
    sda_rx    :   out std_logic := '1';                     -- Conditioned I2C Data
    --
    scl_d_rx  :   out std_logic := '1';                     -- Conditioned I2C Clock delayed for 1 'clk' cycle
    --
    scl_tx    : in    std_logic;                            -- I2C Clock from bit controller
    sda_tx    : in    std_logic;                            -- I2C Data from bit controller
    ------------------------------------
    ------------------------------------
    -- I2C interfaces:
    scl_i     : in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    sda_i     : in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    scl_o     :   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    sda_o     :   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    ------------------------------------
  );
end entity conditioner_mux;
--==============================================================================

--==============================================================================
architecture str of conditioner_mux is

  type real_array is array (natural range <>) of real;
  constant c_f_scl : real_array(0 to 15) := (g_f_scl_0, g_f_scl_1, g_f_scl_2, g_f_scl_3,
                                             g_f_scl_4, g_f_scl_5, g_f_scl_6, g_f_scl_7,
                                             g_f_scl_8, g_f_scl_9, g_f_scl_a, g_f_scl_b,
                                             g_f_scl_c, g_f_scl_d, g_f_scl_e, g_f_scl_f);

  ------------------------------------------------------------------------------
  component conditioner is
    generic
    (
      g_f_clk   :       real   := 100000.0;
      g_f_scl   :       real   :=    100.0
    );
    port
    (
      clk       : in    std_logic;
      s_rst     : in    std_logic;
      busy      :   out std_logic;
      scl_rx    :   out std_logic;
      sda_rx    :   out std_logic;
      scl_d_rx  :   out std_logic;
      scl_tx    : in    std_logic;
      sda_tx    : in    std_logic;
      scl_i     : in    std_logic;
      sda_i     : in    std_logic;
      scl_o     :   out std_logic;
      sda_o     :   out std_logic
    );
  end component conditioner;
  ------------------------------------------------------------------------------

  signal   scl_rx_y      : std_logic_vector(0 to g_bus_num - 1);
  signal   sda_rx_y      : std_logic_vector(0 to g_bus_num - 1);
  signal   scl_d_rx_y    : std_logic_vector(0 to g_bus_num - 1);
  signal   busy_y        : std_logic_vector(0 to g_bus_num - 1);
  signal   scl_tx_y      : std_logic_vector(0 to g_bus_num - 1) := (others => '1');
  signal   sda_tx_y      : std_logic_vector(0 to g_bus_num - 1) := (others => '1');

begin

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        busy     <= '0';
        scl_rx   <= '1';
        sda_rx   <= '1';
        scl_d_rx <= '1';
      else
        busy     <= busy_y(bus_id);
        scl_rx   <= scl_rx_y(bus_id);
        sda_rx   <= sda_rx_y(bus_id);
        scl_d_rx <= scl_d_rx_y(bus_id);
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  --****************************************************************************
  scl_sda_gen:
  for i in 0 to g_bus_num - 1 generate
    ----------------------------------------------------------------------------
    conditioner_inst0 : conditioner
      generic map
      (
        g_f_clk   => g_f_clk,
        g_f_scl   => c_f_scl(i)
      )
      port map
      (
        clk       => clk,
        s_rst     => s_rst,
        busy      => busy_y(i),
        scl_rx    => scl_rx_y(i),
        sda_rx    => sda_rx_y(i),
        scl_d_rx  => scl_d_rx_y(i),
        scl_tx    => scl_tx_y(i),
        sda_tx    => sda_tx_y(i),
        scl_i     => scl_i(i),
        sda_i     => sda_i(i),
        scl_o     => scl_o(i),
        sda_o     => sda_o(i)
      );
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    process(clk)
    begin
      if rising_edge(clk) then
        if (s_rst = '1') then
          scl_tx_y(i) <= '1';
          sda_tx_y(i) <= '1';
        else
          if (i = bus_id) then
            scl_tx_y(i) <= scl_tx;
            sda_tx_y(i) <= sda_tx;
          else
            scl_tx_y(i) <= '1';
            sda_tx_y(i) <= '1';
          end if;
        end if;
      end if;
    end process;
    ----------------------------------------------------------------------------
  end generate scl_sda_gen;
  --****************************************************************************

end architecture str;
--==============================================================================

