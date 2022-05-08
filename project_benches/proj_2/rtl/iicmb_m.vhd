
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  I2C master controller with 'Generic Interface'.                 |
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
entity iicmb_m is
  generic
  (
    ------------------------------------
    g_bus_num   :       positive range 1 to 16 := 1;          -- Number of separate I2C buses
    g_f_clk     :       real                   := 100000.0;   -- Frequency of system clock 'clk' (in kHz)
    g_f_scl_0   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #0 (in kHz)
    g_f_scl_1   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #1 (in kHz)
    g_f_scl_2   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #2 (in kHz)
    g_f_scl_3   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #3 (in kHz)
    g_f_scl_4   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #4 (in kHz)
    g_f_scl_5   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #5 (in kHz)
    g_f_scl_6   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #6 (in kHz)
    g_f_scl_7   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #7 (in kHz)
    g_f_scl_8   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #8 (in kHz)
    g_f_scl_9   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #9 (in kHz)
    g_f_scl_a   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #10 (in kHz)
    g_f_scl_b   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #11 (in kHz)
    g_f_scl_c   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #12 (in kHz)
    g_f_scl_d   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #13 (in kHz)
    g_f_scl_e   :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #14 (in kHz)
    g_f_scl_f   :       real                   :=    100.0    -- Frequency of 'SCL' clock of I2C bus #15 (in kHz)
    ------------------------------------
  );
  port
  (
    ------------------------------------
    clk         : in    std_logic;                            -- Clock
    s_rst       : in    std_logic;                            -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    -- Status:
    busy        :   out std_logic;                            -- Bus busy status
    captured    :   out std_logic;                            -- Bus captured status
    bus_id      :   out std_logic_vector(3 downto 0);         -- ID of selected I2C bus
    bit_state   :   out std_logic_vector(3 downto 0);         -- State of bit level FSM
    byte_state  :   out std_logic_vector(3 downto 0);         -- State of byte level FSM
    ------------------------------------
    ------------------------------------
    -- 'Generic interface' signals:
    mcmd_wr     : in    std_logic;                            -- Byte command write (active high)
    mcmd_id     : in    std_logic_vector(2 downto 0);         -- Byte command ID
    mcmd_data   : in    std_logic_vector(7 downto 0);         -- Command data
    --
    mrsp_wr     :   out std_logic;                            -- Byte response write (active high)
    mrsp_id     :   out std_logic_vector(2 downto 0);         -- Byte response ID
    mrsp_data   :   out std_logic_vector(7 downto 0);         -- Byte Response data
    ------------------------------------
    ------------------------------------
    -- I2C buses:
    scl_i       : in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    sda_i       : in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    scl_o       :   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    sda_o       :   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    ------------------------------------
  );
end entity iicmb_m;
--==============================================================================

--==============================================================================
architecture str of iicmb_m is

  ------------------------------------------------------------------------------
  component conditioner_mux is
    generic
    (
      g_bus_num :       positive range 1 to 16 := 1;
      g_f_clk   :       real                   := 100000.0;
      g_f_scl_0 :       real           :=    100.0;
      g_f_scl_1 :       real           :=    100.0;
      g_f_scl_2 :       real           :=    100.0;
      g_f_scl_3 :       real           :=    100.0;
      g_f_scl_4 :       real           :=    100.0;
      g_f_scl_5 :       real           :=    100.0;
      g_f_scl_6 :       real           :=    100.0;
      g_f_scl_7 :       real           :=    100.0;
      g_f_scl_8 :       real           :=    100.0;
      g_f_scl_9 :       real           :=    100.0;
      g_f_scl_a :       real           :=    100.0;
      g_f_scl_b :       real           :=    100.0;
      g_f_scl_c :       real           :=    100.0;
      g_f_scl_d :       real           :=    100.0;
      g_f_scl_e :       real           :=    100.0;
      g_f_scl_f :       real           :=    100.0
    );
    port
    (
      clk       : in    std_logic;
      s_rst     : in    std_logic;
      bus_id    : in    natural range 0 to g_bus_num - 1;
      busy      :   out std_logic := '0';
      scl_rx    :   out std_logic := '1';
      sda_rx    :   out std_logic := '1';
      scl_d_rx  :   out std_logic := '1';
      scl_tx    : in    std_logic;
      sda_tx    : in    std_logic;
      scl_i     : in    std_logic_vector(0 to g_bus_num - 1);
      sda_i     : in    std_logic_vector(0 to g_bus_num - 1);
      scl_o     :   out std_logic_vector(0 to g_bus_num - 1);
      sda_o     :   out std_logic_vector(0 to g_bus_num - 1)
    );
  end component conditioner_mux;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  component mbit is
    generic
    (
      g_bus_num :       positive range 1 to 16 := 1;
      g_f_clk   :       real           := 100000.0;
      g_f_scl_0 :       real           :=    100.0;
      g_f_scl_1 :       real           :=    100.0;
      g_f_scl_2 :       real           :=    100.0;
      g_f_scl_3 :       real           :=    100.0;
      g_f_scl_4 :       real           :=    100.0;
      g_f_scl_5 :       real           :=    100.0;
      g_f_scl_6 :       real           :=    100.0;
      g_f_scl_7 :       real           :=    100.0;
      g_f_scl_8 :       real           :=    100.0;
      g_f_scl_9 :       real           :=    100.0;
      g_f_scl_a :       real           :=    100.0;
      g_f_scl_b :       real           :=    100.0;
      g_f_scl_c :       real           :=    100.0;
      g_f_scl_d :       real           :=    100.0;
      g_f_scl_e :       real           :=    100.0;
      g_f_scl_f :       real           :=    100.0
    );
    port
    (
      clk       : in    std_logic;
      s_rst     : in    std_logic;
      fsm_state :   out std_logic_vector(3 downto 0);
      bus_id    : in    natural range 0 to g_bus_num - 1;
      mbc_wr    : in    std_logic;
      mbc       : in    mbc_type;
      mbr_wr    :   out std_logic      := '0';
      mbr       :   out mbr_type       := mbr_done;
      scl_i     : in    std_logic;
      sda_i     : in    std_logic;
      scl_i_d   : in    std_logic;
      scl_o     :   out std_logic      := '1';
      sda_o     :   out std_logic      := '1'
    );
  end component mbit;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  component mbyte is
    generic
    (
      g_bus_num   :       positive range 1 to 16 := 1;
      g_f_clk     :       real                   := 100000.0
    );
    port
    (
      clk         : in    std_logic;
      s_rst       : in    std_logic;
      captured    :   out std_logic;
      busy        : in    std_logic;
      bus_id      :   out natural range 0 to g_bus_num - 1 := 0;
      fsm_state   :   out std_logic_vector(3 downto 0);
      mcmd_wr     : in    std_logic;
      mcmd_id     : in    std_logic_vector(2 downto 0);
      mcmd_data   : in    std_logic_vector(7 downto 0);
      mrsp_wr     :   out std_logic                    := '0';
      mrsp_id     :   out std_logic_vector(2 downto 0) := mrsp_done;
      mrsp_data   :   out std_logic_vector(7 downto 0);
      mbc_wr      :   out std_logic                    := '0';
      mbc         :   out mbc_type                     := mbc_stop;
      mbr_wr      : in    std_logic;
      mbr         : in    mbr_type
    );
  end component mbyte;
  ------------------------------------------------------------------------------

  signal bus_id_y  : natural range 0 to g_bus_num - 1;
  signal busy_y    : std_logic;
  signal scl_rx    : std_logic;
  signal sda_rx    : std_logic;
  signal scl_d_rx  : std_logic;
  signal scl_tx    : std_logic;
  signal sda_tx    : std_logic;

  signal mbc_wr    : std_logic;
  signal mbc       : mbc_type;
  signal mbr_wr    : std_logic;
  signal mbr       : mbr_type;

begin

  busy   <= busy_y;
  bus_id <= std_logic_vector(to_unsigned(bus_id_y, 4));

  ------------------------------------------------------------------------------
  mbyte_inst0 : mbyte
    generic map
    (
      g_bus_num   => g_bus_num,
      g_f_clk     => g_f_clk
    )
    port map
    (
      clk         => clk,
      s_rst       => s_rst,
      captured    => captured,
      busy        => busy_y,
      bus_id      => bus_id_y,
      fsm_state   => byte_state,
      mcmd_wr     => mcmd_wr,
      mcmd_id     => mcmd_id,
      mcmd_data   => mcmd_data,
      mrsp_wr     => mrsp_wr,
      mrsp_id     => mrsp_id,
      mrsp_data   => mrsp_data,
      mbc_wr      => mbc_wr,
      mbc         => mbc,
      mbr_wr      => mbr_wr,
      mbr         => mbr
    );
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  mbit_inst0 : mbit
    generic map
    (
      g_bus_num => g_bus_num,
      g_f_clk   => g_f_clk,
      g_f_scl_0 => g_f_scl_0,
      g_f_scl_1 => g_f_scl_1,
      g_f_scl_2 => g_f_scl_2,
      g_f_scl_3 => g_f_scl_3,
      g_f_scl_4 => g_f_scl_4,
      g_f_scl_5 => g_f_scl_5,
      g_f_scl_6 => g_f_scl_6,
      g_f_scl_7 => g_f_scl_7,
      g_f_scl_8 => g_f_scl_8,
      g_f_scl_9 => g_f_scl_9,
      g_f_scl_a => g_f_scl_a,
      g_f_scl_b => g_f_scl_b,
      g_f_scl_c => g_f_scl_c,
      g_f_scl_d => g_f_scl_d,
      g_f_scl_e => g_f_scl_e,
      g_f_scl_f => g_f_scl_f
    )
    port map
    (
      clk       => clk,
      s_rst     => s_rst,
      fsm_state => bit_state,
      bus_id    => bus_id_y,
      mbc_wr    => mbc_wr,
      mbc       => mbc,
      mbr_wr    => mbr_wr,
      mbr       => mbr,
      scl_i     => scl_rx,
      sda_i     => sda_rx,
      scl_i_d   => scl_d_rx,
      scl_o     => scl_tx,
      sda_o     => sda_tx
    );
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  conditioner_mux_inst0 : conditioner_mux
    generic map
    (
      g_bus_num => g_bus_num,
      g_f_clk   => g_f_clk,
      g_f_scl_0 => g_f_scl_0,
      g_f_scl_1 => g_f_scl_1,
      g_f_scl_2 => g_f_scl_2,
      g_f_scl_3 => g_f_scl_3,
      g_f_scl_4 => g_f_scl_4,
      g_f_scl_5 => g_f_scl_5,
      g_f_scl_6 => g_f_scl_6,
      g_f_scl_7 => g_f_scl_7,
      g_f_scl_8 => g_f_scl_8,
      g_f_scl_9 => g_f_scl_9,
      g_f_scl_a => g_f_scl_a,
      g_f_scl_b => g_f_scl_b,
      g_f_scl_c => g_f_scl_c,
      g_f_scl_d => g_f_scl_d,
      g_f_scl_e => g_f_scl_e,
      g_f_scl_f => g_f_scl_f
    )
    port map
    (
      clk       => clk,
      s_rst     => s_rst,
      bus_id    => bus_id_y,
      busy      => busy_y,
      scl_rx    => scl_rx,
      sda_rx    => sda_rx,
      scl_d_rx  => scl_d_rx,
      scl_tx    => scl_tx,
      sda_tx    => sda_tx,
      scl_i     => scl_i,
      sda_i     => sda_i,
      scl_o     => scl_o,
      sda_o     => sda_o
    );
  ------------------------------------------------------------------------------

end architecture str;
--==============================================================================

