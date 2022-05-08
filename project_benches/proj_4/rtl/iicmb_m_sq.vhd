
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Top level of IICMB controller with sequencer.                   |
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
entity iicmb_m_sq is
  generic
  (
    ------------------------------------
    g_bus_num     :       positive range 1 to 16 := 1;          -- Number of separate I2C buses
    g_f_clk       :       real                   := 100000.0;   -- Frequency of system clock 'clk' (in kHz)
    g_f_scl_0     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #0 (in kHz)
    g_f_scl_1     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #1 (in kHz)
    g_f_scl_2     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #2 (in kHz)
    g_f_scl_3     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #3 (in kHz)
    g_f_scl_4     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #4 (in kHz)
    g_f_scl_5     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #5 (in kHz)
    g_f_scl_6     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #6 (in kHz)
    g_f_scl_7     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #7 (in kHz)
    g_f_scl_8     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #8 (in kHz)
    g_f_scl_9     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #9 (in kHz)
    g_f_scl_a     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #10 (in kHz)
    g_f_scl_b     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #11 (in kHz)
    g_f_scl_c     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #12 (in kHz)
    g_f_scl_d     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #13 (in kHz)
    g_f_scl_e     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #14 (in kHz)
    g_f_scl_f     :       real                   :=    100.0;   -- Frequency of 'SCL' clock of I2C bus #15 (in kHz)
    g_cmd         :       seq_cmd_type_array     := c_empty_array -- Sequence of commands (supported: WAIT, SET_BUS and WRITE_BYTE)
    ------------------------------------
  );
  port
  (
    ------------------------------------
    clk           : in    std_logic;                            -- Clock
    s_rst         : in    std_logic;                            -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    cs_start      : in    std_logic;                            -- Start executing command sequence
    cs_busy       :   out std_logic;                            -- Command sequence is being executed
    cs_status     :   out std_logic_vector(2 downto 0);         -- Execution status
    ------------------------------------
    ------------------------------------
    -- I2C interfaces:
    scl_i         : in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    sda_i         : in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    scl_o         :   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    sda_o         :   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    ------------------------------------
  );
end entity iicmb_m_sq;
--==============================================================================

--==============================================================================
architecture str of iicmb_m_sq is

  ------------------------------------------------------------------------------
  component sequencer is
    generic
    (
      g_cmd       :       seq_cmd_type_array := c_empty_array
    );
    port
    (
      clk         : in    std_logic;
      s_rst       : in    std_logic;
      cs_start    : in    std_logic;
      cs_busy     :   out std_logic;
      cs_status   :   out std_logic_vector(2 downto 0);
      busy        : in    std_logic;
      captured    : in    std_logic;
      bus_id      : in    std_logic_vector(3 downto 0);
      bit_state   : in    std_logic_vector(3 downto 0);
      byte_state  : in    std_logic_vector(3 downto 0);
      mcmd_wr     :   out std_logic;
      mcmd_id     :   out std_logic_vector(2 downto 0);
      mcmd_data   :   out std_logic_vector(7 downto 0);
      mrsp_wr     : in    std_logic;
      mrsp_id     : in    std_logic_vector(2 downto 0);
      mrsp_data   : in    std_logic_vector(7 downto 0)
    );
  end component sequencer;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  component iicmb_m is
    generic
    (
      g_bus_num   :       positive range 1 to 16 := 1;
      g_f_clk     :       real                   := 100000.0;
      g_f_scl_0   :       real                   :=    100.0;
      g_f_scl_1   :       real                   :=    100.0;
      g_f_scl_2   :       real                   :=    100.0;
      g_f_scl_3   :       real                   :=    100.0;
      g_f_scl_4   :       real                   :=    100.0;
      g_f_scl_5   :       real                   :=    100.0;
      g_f_scl_6   :       real                   :=    100.0;
      g_f_scl_7   :       real                   :=    100.0;
      g_f_scl_8   :       real                   :=    100.0;
      g_f_scl_9   :       real                   :=    100.0;
      g_f_scl_a   :       real                   :=    100.0;
      g_f_scl_b   :       real                   :=    100.0;
      g_f_scl_c   :       real                   :=    100.0;
      g_f_scl_d   :       real                   :=    100.0;
      g_f_scl_e   :       real                   :=    100.0;
      g_f_scl_f   :       real                   :=    100.0
    );
    port
    (
      clk         : in    std_logic;
      s_rst       : in    std_logic;
      busy        :   out std_logic;
      captured    :   out std_logic;
      bus_id      :   out std_logic_vector(3 downto 0);
      bit_state   :   out std_logic_vector(3 downto 0);
      byte_state  :   out std_logic_vector(3 downto 0);
      mcmd_wr     : in    std_logic;
      mcmd_id     : in    std_logic_vector(2 downto 0);
      mcmd_data   : in    std_logic_vector(7 downto 0);
      mrsp_wr     :   out std_logic;
      mrsp_id     :   out std_logic_vector(2 downto 0);
      mrsp_data   :   out std_logic_vector(7 downto 0);
      scl_i       : in    std_logic_vector(0 to g_bus_num - 1);
      sda_i       : in    std_logic_vector(0 to g_bus_num - 1);
      scl_o       :   out std_logic_vector(0 to g_bus_num - 1);
      sda_o       :   out std_logic_vector(0 to g_bus_num - 1)
    );
  end component iicmb_m;
  ------------------------------------------------------------------------------

  signal busy        : std_logic;
  signal captured    : std_logic;
  signal bus_id      : std_logic_vector( 3 downto 0);
  signal bit_state   : std_logic_vector( 3 downto 0);
  signal byte_state  : std_logic_vector( 3 downto 0);

  -- Signals of 'Generic Interface':
  -- Command:
  signal mcmd_wr     : std_logic;
  signal mcmd_id     : std_logic_vector( 2 downto 0);
  signal mcmd_data   : std_logic_vector( 7 downto 0);
  -- Response:
  signal mrsp_wr     : std_logic;
  signal mrsp_id     : std_logic_vector( 2 downto 0);
  signal mrsp_data   : std_logic_vector( 7 downto 0);

begin

  ------------------------------------------------------------------------------
  sequencer_inst0 : sequencer
    generic map
    (
      g_cmd       => g_cmd
    )
    port map
    (
      clk         => clk,
      s_rst       => s_rst,
      cs_start    => cs_start,
      cs_busy     => cs_busy,
      cs_status   => cs_status,
      busy        => busy,
      captured    => captured,
      bus_id      => bus_id,
      bit_state   => bit_state,
      byte_state  => byte_state,
      mcmd_wr     => mcmd_wr,
      mcmd_id     => mcmd_id,
      mcmd_data   => mcmd_data,
      mrsp_wr     => mrsp_wr,
      mrsp_id     => mrsp_id,
      mrsp_data   => mrsp_data 
    );
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  iicmb_m_inst0 : iicmb_m
    generic map
    (
      g_bus_num   => g_bus_num,
      g_f_clk     => g_f_clk,
      g_f_scl_0   => g_f_scl_0,
      g_f_scl_1   => g_f_scl_1,
      g_f_scl_2   => g_f_scl_2,
      g_f_scl_3   => g_f_scl_3,
      g_f_scl_4   => g_f_scl_4,
      g_f_scl_5   => g_f_scl_5,
      g_f_scl_6   => g_f_scl_6,
      g_f_scl_7   => g_f_scl_7,
      g_f_scl_8   => g_f_scl_8,
      g_f_scl_9   => g_f_scl_9,
      g_f_scl_a   => g_f_scl_a,
      g_f_scl_b   => g_f_scl_b,
      g_f_scl_c   => g_f_scl_c,
      g_f_scl_d   => g_f_scl_d,
      g_f_scl_e   => g_f_scl_e,
      g_f_scl_f   => g_f_scl_f
    )
    port map
    (
      clk         => clk,
      s_rst       => s_rst,
      busy        => busy,
      captured    => captured,
      bus_id      => bus_id,
      bit_state   => bit_state,
      byte_state  => byte_state,
      mcmd_wr     => mcmd_wr,
      mcmd_id     => mcmd_id,
      mcmd_data   => mcmd_data,
      mrsp_wr     => mrsp_wr,
      mrsp_id     => mrsp_id,
      mrsp_data   => mrsp_data,
      scl_i       => scl_i,
      sda_i       => sda_i,
      scl_o       => scl_o,
      sda_o       => sda_o
    );
  ------------------------------------------------------------------------------

end architecture str;
--==============================================================================

