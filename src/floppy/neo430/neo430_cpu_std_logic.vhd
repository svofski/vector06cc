-- #################################################################################################
-- #  << NEO430 - Processor Top Entity using resolved signal types (std_logic) only >>             #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2020, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEO430 Processor - https://github.com/stnolting/neo430                                    #
-- #################################################################################################

-- This is the "naked" neo430 CPU suitable for out-of-soc use
-- svofski 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neo430;
use neo430.neo430_package.all;

entity neo430_cpu_std_logic is
  generic (
    -- boot configuration --
    BOOTLD_USE   : boolean := false; -- implement and use bootloader? (default=false)
    IMEM_AS_ROM  : boolean := true -- implement IMEM as read-only memory? (default=true)
  );
  port (
    -- global control --
    clk_i      : in  std_ulogic; -- global clock, rising edge
    rst_i      : in  std_ulogic; -- global reset, low-active, async
    -- memory interface --
    mem_rd_o   : out std_ulogic; -- memory read enable
    mem_imwe_o : out std_ulogic; -- allow writing to IMEM
    mem_wr_o   : out std_ulogic_vector(01 downto 0); -- byte memory write enable
    mem_addr_o : out std_ulogic_vector(15 downto 0); -- address
    mem_data_o : out std_ulogic_vector(15 downto 0); -- write data
    mem_data_i : in  std_ulogic_vector(15 downto 0); -- read data
    -- interrupt system --
    irq_i      : in  std_ulogic_vector(03 downto 0)  -- interrupt requests
  );
end neo430_cpu_std_logic;

architecture neo430_cpu_std_logic_rtl of neo430_cpu_std_logic is
    -- global control --
    signal clk_i_int      : std_ulogic; -- global clock, rising edge
    signal rst_i_int      : std_ulogic; -- global reset, low-active, async
    -- memory interface --
    signal mem_rd_o_int   : std_ulogic; -- memory read enable
    signal mem_imwe_o_int : std_ulogic; -- allow writing to IMEM
    signal mem_wr_o_int   : std_ulogic_vector(01 downto 0); -- byte memory write enable
    signal mem_addr_o_int : std_ulogic_vector(15 downto 0); -- address
    signal mem_data_o_int : std_ulogic_vector(15 downto 0); -- write data
    signal mem_data_i_int : std_ulogic_vector(15 downto 0); -- read data
    -- interrupt system --
    signal irq_i_int      : std_ulogic_vector(03 downto 0);  -- interrupt requests

begin

  -- CPU ----------------------------------------------------------------------
  -- -----------------------------------------------------------------------------
  neo430_cpu_inst: neo430_cpu
  generic map (
    -- boot configuration --
    BOOTLD_USE   => BOOTLD_USE,       -- implement and use bootloader? (default=true)
    IMEM_AS_ROM  => IMEM_AS_ROM       -- implement IMEM as read-only memory? (default=false)
  )
  port map (
    -- global control --
    clk_i      => clk_i_int,          -- global clock, rising edge
    rst_i      => rst_i_int,          -- global reset, async, low-active
    -- memory interface --
    mem_rd_o   => mem_rd_o_int,  
    mem_imwe_o => mem_imwe_o_int,
    mem_wr_o   => mem_wr_o_int,
    mem_addr_o => mem_addr_o_int,
    mem_data_o => mem_data_o_int,
    mem_data_i => mem_data_i_int,
    -- interrupt system --
    irq_i      => irq_i_int
  );


  -- Type Conversion ----------------------------------------------------------
  -- -----------------------------------------------------------------------------
  clk_i_int      <= std_ulogic(clk_i);
  rst_i_int      <= std_ulogic(rst_i);
  irq_i_int      <= std_ulogic_vector(irq_i);
  mem_data_i_int <= std_ulogic_vector(mem_data_i);

  mem_rd_o    <= std_ulogic(mem_rd_o_int);
  mem_imwe_o  <= std_ulogic(mem_imwe_o_int);
  mem_wr_o    <= std_ulogic_vector(mem_wr_o_int);
  mem_addr_o  <= std_ulogic_vector(mem_addr_o_int);
  mem_data_o  <= std_ulogic_vector(mem_data_o_int);


end neo430_cpu_std_logic_rtl;


