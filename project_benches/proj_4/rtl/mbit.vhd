
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Bit layer FSM (master mode).                                    |
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

use work.iicmb_int_pkg.all;


--==============================================================================
entity mbit is
  generic
  (
    g_bus_num :       positive range 1 to 16 := 1;  -- Number of connected I2C buses
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
  );
  port
  (
    ------------------------------------
    clk       : in    std_logic;                    -- Clock
    s_rst     : in    std_logic;                    -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    fsm_state :   out std_logic_vector(3 downto 0); -- FSM state
    bus_id    : in    natural range 0 to g_bus_num - 1; -- I2C Bus ID
    ------------------------------------
    ------------------------------------
    mbc_wr    : in    std_logic;                    -- Bit command write indication (active high)
    mbc       : in    mbc_type;                     -- Bit command
    ------------------------------------
    ------------------------------------
    mbr_wr    :   out std_logic      := '0';        -- Bit command response write indication (active high)
    mbr       :   out mbr_type       := mbr_done;   -- Bit command response
    ------------------------------------
    ------------------------------------
    scl_i     : in    std_logic;                    -- I2C Clock input
    sda_i     : in    std_logic;                    -- I2C Data input
    scl_i_d   : in    std_logic;                    -- I2C Clock input delayed for 1 clock cycle
    scl_o     :   out std_logic      := '1';        -- I2C Clock output
    sda_o     :   out std_logic      := '1'         -- I2C Data output
    ------------------------------------
  );
end entity mbit;
--==============================================================================

--==============================================================================
architecture rtl of mbit is

  type real_array is array (natural range <>) of real;
  constant c_f_scl : real_array(0 to 15) := (g_f_scl_0, g_f_scl_1, g_f_scl_2, g_f_scl_3,
                                             g_f_scl_4, g_f_scl_5, g_f_scl_6, g_f_scl_7,
                                             g_f_scl_8, g_f_scl_9, g_f_scl_a, g_f_scl_b,
                                             g_f_scl_c, g_f_scl_d, g_f_scl_e, g_f_scl_f);

  type timing_parameters_type is record
    max_cnt       : integer; -- Minimum number of 'clk' cycles in single 'SCL' cycle
    fe_cnt        : integer; -- Time for falling edge of 'SCL'
    t_hd_sta_cnt  : integer; -- Hold time (repeated) Start condition
    t_vd_dat_cnt  : integer; -- Data valid time
    t_high_cnt    : integer; -- 'SCL' high time
    t_su_sto_cnt  : integer; -- Set-up time for Stop condition
    t_su_sta_cnt  : integer; -- Set-up time for a repeated Start condition
    t_su_dat_cnt  : integer; -- Data set-up time
  end record;

  type timing_parameters_type_array is array (0 to g_bus_num - 1) of timing_parameters_type;

  ------------------------------------------------------------------------------
  function get_tp(a_f_clk : real; a_f_scl : real_array(0 to 15)) return timing_parameters_type_array is
    variable ret        : timing_parameters_type_array;
    variable v_t_scl    : integer;
    variable v_t_high   : integer;
    variable v_t_low    : integer;
    variable v_t_vd_dat : integer;
  begin
    for i in ret'range loop
      v_t_scl             := integer((a_f_clk/a_f_scl(i)) + 0.4999);   -- number of 'clk' periods in an 'SCL' period
      if (a_f_scl(i) <= 100.0) then
        v_t_high            := integer(real(v_t_scl)*0.401);             -- 'SCL' high time
        v_t_low             := integer(real(v_t_scl)*0.47);              -- 'SCL' low time
      else
        v_t_high            := integer(real(v_t_scl)*0.241);             -- 'SCL' high time
        v_t_low             := integer(real(v_t_scl)*0.52);              -- 'SCL' low time
      end if;
      v_t_vd_dat          := integer((a_f_clk*(0.5/1000.0)) + 0.4999);
      --
      ret(i).max_cnt      := v_t_scl - 1;
      ret(i).fe_cnt       := v_t_low - v_t_vd_dat + v_t_high - 1;
      ret(i).t_hd_sta_cnt := v_t_high - 1;
      ret(i).t_vd_dat_cnt := v_t_vd_dat - 1;
      ret(i).t_high_cnt   := v_t_high - 1;
      ret(i).t_su_sto_cnt := v_t_high - 1;
      ret(i).t_su_sta_cnt := v_t_low - 1;
      ret(i).t_su_dat_cnt := v_t_low - v_t_vd_dat - 1;
    end loop;
    return ret;
  end function get_tp;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  function get_max_cnt(a : timing_parameters_type_array) return integer is
    variable ret        : integer := 0;
  begin
    for i in a'range loop
      if (ret < a(i).max_cnt) then
        ret := a(i).max_cnt;
      end if;
    end loop;
    return ret;
  end function get_max_cnt;
  ------------------------------------------------------------------------------

  constant c_tp            : timing_parameters_type_array := get_tp(g_f_clk, c_f_scl);
  constant c_max_cnt       : integer := get_max_cnt(c_tp);

  type state_type is
    (
      s_idle,      -- Idle
      --
      s_start_a,   -- Start condition generating
      s_start_b,   -- Start condition generating
      s_start_c,   -- Start condition generating
      --
      s_rw_a,      -- Bit Read/Write
      s_rw_b,      -- Bit Read/Write
      s_rw_c,      -- Bit Read/Write
      s_rw_d,      -- Bit Read/Write
      s_rw_e,      -- Bit Read/Write
      --
      s_stop_a,    -- Stop condition generating
      s_stop_b,    -- Stop condition generating
      s_stop_c,    -- Stop condition generating
      --
      s_rstart_a,  -- Preparation for Repeated Start
      s_rstart_b,  -- Preparation for Repeated Start
      s_rstart_c   -- Preparation for Repeated Start
    );

  ------------------------------------------------------------------------------
  -- Conversion from 'state_type' to 'std_logic_vector(3 downto 0)'
  function to_std_logic_vector(a : state_type) return std_logic_vector is
  begin
    case (a) is
      when s_idle      => return "0000";
      when s_start_a   => return "0001";
      when s_start_b   => return "0010";
      when s_start_c   => return "0011";
      when s_rw_a      => return "0100";
      when s_rw_b      => return "0101";
      when s_rw_c      => return "0110";
      when s_rw_d      => return "0111";
      when s_rw_e      => return "1000";
      when s_stop_a    => return "1001";
      when s_stop_b    => return "1010";
      when s_stop_c    => return "1011";
      when s_rstart_a  => return "1100";
      when s_rstart_b  => return "1101";
      when s_rstart_c  => return "1110";
    end case;
  end function to_std_logic_vector;
  ------------------------------------------------------------------------------

  signal   state           : state_type                   := s_idle; -- FSM state
  signal   cnt             : integer range 0 to c_max_cnt := 0;      -- Counter of clock cycles
  signal   d_reg           : std_logic                    := '0';    -- Output data bit register
  signal   r_reg           : std_logic                    := '0';    -- Read operation indication
  signal   i_reg           : std_logic                    := '0';    -- Input data bit register

  signal   scl_cnt         : integer range 0 to c_max_cnt := 0;      -- Counter of cycles when scl is stable

  -- Timing parameters:
  signal   max_cnt         : integer range 0 to c_max_cnt := c_tp(0).max_cnt;
  signal   fe_cnt          : integer range 0 to c_max_cnt := c_tp(0).fe_cnt;
  signal   t_hd_sta_cnt    : integer range 0 to c_max_cnt := c_tp(0).t_hd_sta_cnt;
  signal   t_vd_dat_cnt    : integer range 0 to c_max_cnt := c_tp(0).t_vd_dat_cnt;
  signal   t_high_cnt      : integer range 0 to c_max_cnt := c_tp(0).t_high_cnt;
  signal   t_su_sto_cnt    : integer range 0 to c_max_cnt := c_tp(0).t_su_sto_cnt;
  signal   t_su_sta_cnt    : integer range 0 to c_max_cnt := c_tp(0).t_su_sta_cnt;
  signal   t_su_dat_cnt    : integer range 0 to c_max_cnt := c_tp(0).t_su_dat_cnt;

begin

  fsm_state <= to_std_logic_vector(state);

  ------------------------------------------------------------------------------
  -- Changing timing parameters:
  tp_proc:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        max_cnt      <= c_tp(0).max_cnt;
        fe_cnt       <= c_tp(0).fe_cnt;
        t_hd_sta_cnt <= c_tp(0).t_hd_sta_cnt;
        t_vd_dat_cnt <= c_tp(0).t_vd_dat_cnt;
        t_high_cnt   <= c_tp(0).t_high_cnt;
        t_su_sto_cnt <= c_tp(0).t_su_sto_cnt;
        t_su_sta_cnt <= c_tp(0).t_su_sta_cnt;
        t_su_dat_cnt <= c_tp(0).t_su_dat_cnt;
      else
        max_cnt      <= c_tp(bus_id).max_cnt;
        fe_cnt       <= c_tp(bus_id).fe_cnt;
        t_hd_sta_cnt <= c_tp(bus_id).t_hd_sta_cnt;
        t_vd_dat_cnt <= c_tp(bus_id).t_vd_dat_cnt;
        t_high_cnt   <= c_tp(bus_id).t_high_cnt;
        t_su_sto_cnt <= c_tp(bus_id).t_su_sto_cnt;
        t_su_sta_cnt <= c_tp(bus_id).t_su_sta_cnt;
        t_su_dat_cnt <= c_tp(bus_id).t_su_dat_cnt;
      end if;
    end if;
  end process tp_proc;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Counting how long 'scl_i' input remains stable
  scl_cnt_proc:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        scl_cnt <= 0;
      else
        if (scl_i_d /= scl_i) then
          scl_cnt <= 1;
        elsif (scl_cnt < max_cnt) then
          scl_cnt <= scl_cnt + 1;
        else
          scl_cnt <= max_cnt;
        end if;
      end if;
    end if;
  end process scl_cnt_proc;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Main Finite State Machine:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        state   <= s_idle;
        d_reg   <= '0';
        i_reg   <= '0';
        r_reg   <= '0';
        cnt     <= 0;
        mbr_wr  <= '0';
        mbr     <= mbr_done;
      else
        -- Defaults:
        if (cnt < max_cnt) then
          cnt     <= cnt + 1;
        else
          cnt     <= max_cnt;
        end if;
        mbr_wr  <= '0';
        ------

        case state is
          -- 'Idle' state ----------------------------------
          when s_idle =>
            if (mbc_wr = '1') then
              case (mbc) is
                when mbc_start =>
                  state  <= s_start_a;
                when mbc_stop =>
                  assert false report "Stop command without Start command!" severity warning;
                  mbr_wr <= '1';
                  mbr    <= mbr_done;
                when others =>
                  assert false report "In 'Idle' state only Start command allowed!" severity warning;
                  mbr_wr <= '1';
                  mbr    <= mbr_error;
              end case;
              cnt    <= 0;
            end if;
          -- 'Idle' state ----------------------------------

          -- 'Start A' state -------------------------------
          when s_start_a =>
            if (scl_i = '0')or(cnt = t_hd_sta_cnt) then -- t_{HD;STA} >= 4.0 us
              state  <= s_start_b;
            end if;
          -- 'Start A' state -------------------------------

          -- 'Start B' state -------------------------------
          when s_start_b =>
            if (scl_i_d = '0')and(scl_cnt > t_vd_dat_cnt) then -- t_{VD;DAT} <= 3.45 us, t_{HD;DAT} >= 0 us;
              state  <= s_start_c;
              mbr_wr <= '1';
              mbr    <= mbr_done;
            end if;
          -- 'Start B' state -------------------------------

          -- 'Start C' state -------------------------------
          when s_start_c =>
            if (mbc_wr = '1') then
              case (mbc) is
                when mbc_write_0 =>
                  state  <= s_rw_a;
                  d_reg  <= '0'; -- data
                  r_reg  <= '0'; -- read indication
                when mbc_write_1 =>
                  state  <= s_rw_a;
                  d_reg  <= '1'; -- data
                  r_reg  <= '0'; -- read indication
                when mbc_read =>
                  state  <= s_rw_a;
                  d_reg  <= '1'; -- data
                  r_reg  <= '1'; -- read indication
                when mbc_stop =>
                  state  <= s_stop_a;
                when mbc_start =>
                  -- Second 'Start' command coming immediately after the first
                  -- one is ignored without an 'Error' response.
                  assert false report "Second Start command!" severity warning;
                  mbr_wr <= '1';
                  mbr    <= mbr_done;
              end case;
              cnt    <= 0;
            end if;
          -- 'Start C' state -------------------------------

          -- 'Read/Write A' state --------------------------
          when s_rw_a =>
            if (cnt = t_su_dat_cnt) then -- t_{SU;DAT} >= 0.25 us
              state  <= s_rw_b;
            end if;
          -- 'Read/Write A' state --------------------------

          -- 'Read/Write B' state --------------------------
          when s_rw_b =>
            if (scl_i = '1') then
              state  <= s_rw_c;
            end if;
          -- 'Read/Write B' state --------------------------

          -- 'Read/Write C' state --------------------------
          when s_rw_c =>
            if (scl_i = '0')or((scl_cnt > t_high_cnt)and(cnt >= fe_cnt)) then -- t_{HIGH} >= 4.0 us;
              state  <= s_rw_d;
              i_reg  <= sda_i;
            end if;
            if (scl_i = '1')and(r_reg = '0')and(sda_i /= d_reg) then
              mbr_wr <= '1';
              mbr    <= mbr_arb_lost; -- Arbitration lost
              state  <= s_idle;
            end if;
          -- 'Read/Write C' state --------------------------

          -- 'Read/Write D' state --------------------------
          when s_rw_d =>
            if (scl_i_d = '0')and(scl_cnt > t_vd_dat_cnt)and(cnt = max_cnt) then -- t_{VD;DAT} <= 3.45 us, t_{HD;DAT} >= 0 us;
              state  <= s_rw_e;
              mbr_wr <= '1';
              if (r_reg = '0') then
                mbr    <= mbr_done;     -- Successfull write
              else
                if (i_reg = '0') then
                  mbr    <= mbr_bit_0;    -- Bit 0 received
                else
                  mbr    <= mbr_bit_1;    -- Bit 1 received
                end if;
              end if;
            end if;
          -- 'Read/Write D' state --------------------------

          -- 'Read/Write E' state --------------------------
          when s_rw_e =>
            if (mbc_wr = '1') then
              case (mbc) is
                when mbc_write_0 =>
                  state  <= s_rw_a;
                  d_reg  <= '0'; -- data
                  r_reg  <= '0'; -- read indication
                when mbc_write_1 =>
                  state  <= s_rw_a;
                  d_reg  <= '1'; -- data
                  r_reg  <= '0'; -- read indication
                when mbc_read =>
                  state  <= s_rw_a;
                  d_reg  <= '1'; -- data
                  r_reg  <= '1'; -- read indication
                when mbc_start =>
                  state  <= s_rstart_a;
                when mbc_stop =>
                  state  <= s_stop_a;
              end case;
              cnt    <= 0;
            end if;
          -- 'Read/Write E' state --------------------------

          -- 'Stop A' state --------------------------------
          when s_stop_a =>
            if (cnt = t_su_dat_cnt) then -- t_{SU;DAT} >= 0.25 us
              state  <= s_stop_b;
            end if;
          -- 'Stop A' state --------------------------------

          -- 'Stop B' state --------------------------------
          when s_stop_b =>
            if (scl_i = '1') then
              state  <= s_stop_c;
              cnt    <= 0;
            end if;
          -- 'Stop B' state --------------------------------

          -- 'Stop C' state --------------------------------
          when s_stop_c =>
            if (cnt > t_su_sto_cnt) then -- t_{SU;STO} >= 4.0 us
              state  <= s_idle;
              mbr_wr <= '1';
              mbr    <= mbr_done;
              cnt    <= 0;
            end if;
          -- 'Stop C' state --------------------------------

          -- 'Repeated Start A' state ----------------------
          when s_rstart_a =>
            if (cnt = t_su_dat_cnt) then -- t_{SU;DAT} >= 0.25 us
              state  <= s_rstart_b;
            end if;
          -- 'Repeated Start A' state ----------------------

          -- 'Repeated Start B' state ----------------------
          when s_rstart_b =>
            if (scl_i = '1') then
              state  <= s_rstart_c;
            end if;
          -- 'Repeated Start B' state ----------------------

          -- 'Repeated Start C' state ----------------------
          when s_rstart_c =>
            if (scl_i_d = '0')or((scl_cnt > t_su_sta_cnt)and(cnt = max_cnt)) then -- t_{SU;STA} >= 4.7 us
              state  <= s_start_a;
              cnt    <= 0;
            end if;
            if (scl_i = '1')and(sda_i = '0') then
              mbr_wr <= '1';
              mbr    <= mbr_arb_lost; -- Arbitration lost
              state  <= s_idle;
            end if;
          -- 'Repeated Start C' state ----------------------
        end case;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  scl_sda_proc:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        scl_o <= '1';
        sda_o <= '1';
      else
        case state is
          when s_idle     => sda_o <= '1';   scl_o <= '1';
          when s_start_a  => sda_o <= '0';   scl_o <= '1';
          when s_start_b  => sda_o <= '0';   scl_o <= '0';
          when s_start_c  => sda_o <= '0';   scl_o <= '0';
          when s_rw_a     => sda_o <= d_reg; scl_o <= '0';
          when s_rw_b     => sda_o <= d_reg; scl_o <= '1';
          when s_rw_c     => sda_o <= d_reg; scl_o <= '1';
          when s_rw_d     => sda_o <= d_reg; scl_o <= '0';
          when s_rw_e     => sda_o <= d_reg; scl_o <= '0';
          when s_stop_a   => sda_o <= '0';   scl_o <= '0';
          when s_stop_b   => sda_o <= '0';   scl_o <= '1';
          when s_stop_c   => sda_o <= '0';   scl_o <= '1';
          when s_rstart_a => sda_o <= '1';   scl_o <= '0';
          when s_rstart_b => sda_o <= '1';   scl_o <= '1';
          when s_rstart_c => sda_o <= '1';   scl_o <= '1';
        end case;
      end if;
    end if;
  end process scl_sda_proc;
  ------------------------------------------------------------------------------

end architecture rtl;
--==============================================================================
