
--==============================================================================
--                                                                             |
--    Project: IIC Multiple Bus Controller (IICMB)                             |
--                                                                             |
--    Module:  Register block.                                                 |
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


--------------------------------------------------------------------------------
-- Implemented registers:
-- 
--   Control/Status register:
--            7     6     5     4     3     2     1     0
--         +-----+-----+-----+-----+-----+-----+-----+-----+
--   0x00  |  E  | IE  |  BB |  BC |        Bus ID         |
--         +-----+-----+-----+-----+-----+-----+-----+-----+
--           R/W   R/W   RO    RO             RO
--           '0'   '0'   '0'   '0'          "0000"
--
--            E      - Enable
--            IE     - Interrupt Enable
--            BB     - Bus Busy
--            RC     - Bus Captured
--
--
--   Data register:
--            7     6     5     4     3     2     1     0
--         +-----+-----+-----+-----+-----+-----+-----+-----+
--   0x01  |                     Data                      |
--         +-----+-----+-----+-----+-----+-----+-----+-----+
--                                R/W
--                            "00000000"
--
--   Command register:
--            7     6     5     4     3     2     1     0
--         +-----+-----+-----+-----+-----+-----+-----+-----+
--   0x02  | DON | NAK | AL  | ERR | '0' |  Command Code   |
--         +-----+-----+-----+-----+-----+-----+-----+-----+
--           RO    RO    RO    RO                R/W
--           '1'   '0'   '0'   '0'              "000"
--
--            DON - Command Done
--            NAK - Data write was not acknowledged
--            AL  - Arbitration Lost
--            ERR - Error
--
--
--   Status register of FSM states:
--            7     6     5     4     3     2     1     0
--         +-----+-----+-----+-----+-----+-----+-----+-----+
--   0x03  |       Byte State      |       Bit State       |
--         +-----+-----+-----+-----+-----+-----+-----+-----+
--                    RO                      RO 
--                  "0000"                  "0000"
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

use work.iicmb_pkg.all;


--==============================================================================
entity regblock is
  port
  (
    ------------------------------------
    clk         : in    std_logic;                                -- Clock input
    s_rst       : in    std_logic;                                -- Synchronous reset (active high)
    ------------------------------------
    ------------------------------------
    wr          : in    std_logic_vector( 3 downto 0);            -- Write (active high)
    rd          : in    std_logic_vector( 3 downto 0);            -- Read (active high)
    idata       : in    std_logic_vector(31 downto 0);            -- Data from System Bus
    odata       :   out std_logic_vector(31 downto 0);            -- Data to System Bus
    ------------------------------------
    ------------------------------------
    irq         :   out std_logic;                                -- Interrupt request
    ------------------------------------

    ------------------------------------
    busy        : in    std_logic;                                -- 'Bus is busy' indication (busy = high)
    captured    : in    std_logic;                                -- 'Bus is captured' indication (captured = high)
    bus_id      : in    std_logic_vector( 3 downto 0);            -- ID of selected I2C bus
    bit_state   : in    std_logic_vector( 3 downto 0);            -- State of bit level FSM
    byte_state  : in    std_logic_vector( 3 downto 0);            -- State of byte level FSM
    disable     :   out std_logic;                                -- Disable controller (used as synchronous reset)
    ------------------------------------
    ------------------------------------
    -- 'Generic Interface' signals:
    -- Byte command interface:
    mcmd_wr     :   out std_logic;                                -- Byte command write (active high)
    mcmd_id     :   out std_logic_vector( 2 downto 0);            -- Byte command ID
    mcmd_data   :   out std_logic_vector( 7 downto 0);            -- Byte command data
    -------------
    -- Byte response interface:
    mrsp_wr     : in    std_logic;                                -- Byte response write (active high)
    mrsp_id     : in    std_logic_vector( 2 downto 0);            -- Byte response ID
    mrsp_data   : in    std_logic_vector( 7 downto 0)             -- Byte response data
    ------------------------------------
  );
end entity regblock;
--==============================================================================

--==============================================================================
architecture rtl of regblock is

  signal irq_y             : std_logic                    := '0';
  signal mcmd_wr_y         : std_logic                    := '0';
  signal mcmd_id_y         : std_logic_vector(2 downto 0) := mcmd_set_bus;
  signal e_reg             : std_logic                    := '0';
  signal ie_reg            : std_logic                    := '0';
  signal tx_data_reg       : std_logic_vector(7 downto 0) := "00000000";
  signal rx_data_reg       : std_logic_vector(7 downto 0) := "00000000";
  signal don_reg           : std_logic                    := '1';
  signal nak_reg           : std_logic                    := '0';
  signal al_reg            : std_logic                    := '0';
  signal err_reg           : std_logic                    := '0';
  signal cmd_code_reg      : std_logic_vector(2 downto 0) := "000";
  signal command_completed : std_logic;

begin

  disable             <= not(e_reg);

  odata(31 downto 28) <= byte_state;
  odata(27 downto 24) <= bit_state;
  --
  odata(23)           <= don_reg;
  odata(22)           <= nak_reg;
  odata(21)           <= al_reg;
  odata(20)           <= err_reg;
  odata(19)           <= '0';
  odata(18 downto 16) <= cmd_code_reg;
  --
  odata(15 downto  8) <= rx_data_reg;
  --
  odata( 7)           <= e_reg;
  odata( 6)           <= ie_reg;
  odata( 5)           <= busy;
  odata( 4)           <= captured;
  odata( 3 downto  0) <= bus_id;

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        e_reg        <= '0';
        ie_reg       <= '0';
      else
        if (wr(0) = '1') then
          e_reg  <= idata(7);
          ie_reg <= idata(6);
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1') then
        tx_data_reg  <= "00000000";
      else
        if (wr(1) = '1') then
          tx_data_reg <= idata(15 downto 8);
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  command_completed <= don_reg or nak_reg or al_reg or err_reg;

  ------------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1')or(e_reg = '0') then
        cmd_code_reg <= "000";
      else
        if (wr(2) = '1') then
          if (command_completed = '1') then
            cmd_code_reg <= idata(18 downto 16);
          end if;
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Command status registers
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1')or(e_reg = '0') then
        don_reg     <= '1';
        nak_reg     <= '0';
        al_reg      <= '0';
        err_reg     <= '0';
        rx_data_reg <= "00000000";
      else
        if (wr(2) = '1') then
          don_reg <= '0';
          nak_reg <= '0';
          al_reg  <= '0';
          err_reg <= '0';
        end if;
        if (mrsp_wr = '1') then
          case (mrsp_id) is
            when mrsp_done     => don_reg <= '1';
            when mrsp_byte     =>
              don_reg     <= '1';
              rx_data_reg <= mrsp_data;
            when mrsp_nak      => nak_reg <= '1';
            when mrsp_arb_lost => al_reg  <= '1';
            when others        => err_reg <= '1';
          end case;
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Interrupt request
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1')or(e_reg = '0') then
        irq_y <= '0';
      else
        if (rd(2) = '1') then
          irq_y <= '0';
        end if;
        if (mrsp_wr = '1') then
          irq_y <= '1';
        end if;
        if (ie_reg = '0') then
          irq_y <= '0';
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  irq <= irq_y;

  ------------------------------------------------------------------------------
  -- Generating a byte command
  mcmd_proc:
  process(clk)
  begin
    if rising_edge(clk) then
      if (s_rst = '1')or(e_reg = '0') then
        mcmd_wr_y <= '0';
        mcmd_id_y <= mcmd_wait;
      else
        if (wr(2) = '1')and(command_completed = '1') then
          mcmd_wr_y <= '1';
          mcmd_id_y <= idata(18 downto 16);
        else
          mcmd_wr_y <= '0';
        end if;
      end if;
    end if;
  end process mcmd_proc;
  ------------------------------------------------------------------------------

  mcmd_wr   <= mcmd_wr_y;
  mcmd_id   <= mcmd_id_y;
  mcmd_data <= tx_data_reg;

end architecture rtl;
--==============================================================================

