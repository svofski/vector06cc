------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- Copyright (c) 2007 Tobias Gubener <tobiflex@opencores.org>               -- 
--                                                                          --
-- This source file is free software: you can redistribute it and/or modify --
-- it under the terms of the GNU General Public License as published        --
-- by the Free Software Foundation, either version 3 of the License, or     --
-- (at your option) any later version.                                      --
--                                                                          --
-- This source file is distributed in the hope that it will be useful,      --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of           --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            --
-- GNU General Public License for more details.                             --
--                                                                          --
-- You should have received a copy of the GNU General Public License        --
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.    --
--                                                                          --
------------------------------------------------------------------------------
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity TXD is
   port ( 
	clk: in std_logic;				
	ld: in std_logic;				
	data: in std_logic_vector(7 downto 0);		
	TxD: out std_logic;			
	txbusy: buffer std_logic				
   );

end TXD;


architecture TXD of TXD is

signal shift: std_logic_vector(9 downto 0);
signal clkgen: std_logic_vector(9 downto 0);
signal stop: std_logic;
signal shiftout: std_logic;

begin
TxD <= not shiftout;
process(clk, shift)
begin
   if shift = "0000000000" then
        txbusy <= '0';
   else
        txbusy <= '1';
   end if;

   	if clk'event and clk = '1' then
 	  	if ld = '1' then
   			shiftout <= '0';
   			shift <=  '1' & data & '0';			--STOP,MSB...LSB, START
   		end if;
		if clkgen/=0 then
	 	  	if ld = '1' and stop = '0' then
				clkgen <= "0000000001";		
			else		
				clkgen <= clkgen-1;
			end if;
		else	
--			clkgen <= "1101000000";--832;		--96MHz/115200
--			clkgen <= "0111100101";--487;		--56MHz/115200
--			clkgen <= "0011110010";--243;		--28MHz/115200
			clkgen <= "0011010000";					--24MHz/115200
--			clkgen <= "1001110001";					--24MHz/38400
			shiftout <= not(shift(0) or not txbusy or ld);
			stop <= shift(0);
		   	shift <=  '0' & shift(9 downto 1);
	 	end if;
   	end if;
end process; 

end TXD;  
