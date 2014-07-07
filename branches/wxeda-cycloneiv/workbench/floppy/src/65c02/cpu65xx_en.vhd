-- -----------------------------------------------------------------------
--
--                                 FPGA 64
--
--     A fully functional commodore 64 implementation in a single FPGA
--
-- -----------------------------------------------------------------------
-- Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
--
-- Cycle exact 6502/6510 core
--
-- -----------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity cpu65xx_en is
	port (
		clk : in std_logic;
		reset : in std_logic;
		enable : in std_logic;
		nmi_n : in std_logic;
		irq_n : in std_logic;

		di : in unsigned(7 downto 0);
		do : out unsigned(7 downto 0);
		addr : out unsigned(15 downto 0);
		we : out std_logic;
		
		brkActive : out std_logic;

		pcDebugOut : out unsigned(15 downto 0);
		opcodeDebugOut : out unsigned(7 downto 0)
	);
end cpu65xx_en;

-- -----------------------------------------------------------------------

architecture Behavioral of cpu65xx_en is
	type cpuCycles is (opcodeFetch, secondFetch, cycle3, cycle4, cycle5, cycle6, cycleBrk3, cycleBrk4, cycleBrk5, readPcl, readPch, cycleReadWriteOrEnd, cycleRwmCalc, cycleWriteEnd, cycleReadStack, cycleReadStackEnd);
	signal cpuCycle: cpuCycles;

	signal opcode : unsigned(7 downto 0);
	signal fixedAddrL : boolean;
	signal fixedAddrH : boolean;

	signal irqReg: std_logic;
	signal irqActive : std_logic;
	signal nmiReg: std_logic;
	
	signal T : unsigned(7 downto 0);

	signal A: unsigned(7 downto 0); -- Accumulator
	signal X: unsigned(7 downto 0); -- Index X
	signal Y: unsigned(7 downto 0); -- Index Y
	signal S: unsigned(7 downto 0); -- stack pointer

	signal PC : unsigned(15 downto 0); -- Program counter
	signal PCincr :  unsigned(15 downto 0);
	signal PCincrRel : unsigned(8 downto 0);
	signal myAddr : unsigned(15 downto 0);
	signal myAddrIncrL : unsigned(7 downto 0);
	signal myAddrIncrH : unsigned(7 downto 0);


	signal C: std_logic; -- Carry
	signal Z: std_logic; -- Zero flag
	signal I: std_logic; -- Interrupt flag
	signal D: std_logic; -- Decimal mode
--	signal B: std_logic; -- Break flag
	signal V: std_logic; -- Overflow
	signal N: std_logic; -- Negative

	signal aluInput : unsigned(7 downto 0);
	signal aluOut : unsigned(7 downto 0);
	signal aluC : std_logic;
	signal aluZ : std_logic;
	signal aluV : std_logic;
	signal aluN : std_logic;

	signal indexOut : unsigned(8 downto 0);
	
	signal stackIncDec : unsigned(7 downto 0);
	
	-- Returns true if given opcode is a read-modify-write instruction.
	-- The 6510 does one read and 2 write cycles for rmw instructions.
	-- On first write the read value is written back, the second write is the correctly calculated value.
	function isRmwOpcode(aOpcode : in unsigned(7 downto 0)) return boolean is
	begin
		case aOpcode is
		when
			X"06" | X"07"         | X"0E" | X"0F" |
			X"16" | X"17" | X"1B" | X"1E" | X"1F" |
			X"26" | X"27"         | X"2E" | X"2F" |
			X"36" | X"37" | X"3B" | X"3E" | X"3F" |
			X"46" | X"47"         | X"4E" | X"4F" |
			X"56" | X"57" | X"5B" | X"5E" | X"5F" |
			X"66" | X"67"         | X"6E" | X"6F" |
			X"76" | X"77" | X"7B" | X"7E" | X"7F" |
			X"C6" | X"C7"         | X"CE" | X"CF" |
			X"D6" | X"D7" | X"DB" | X"DE" | X"DF" |
			X"E6" | X"E7"         | X"EE" | X"EF" |
			X"F6" | X"F7" | X"FB" | X"FE" | X"FF" =>
			return true;
		when others =>
			return false;
		end case;
	end function;

begin
	processAluInput: process(opcode, T, A, X, Y)
	begin
		case opcode is
		when
			X"06" | X"0E" | -- ASL zp / ASL abs
			X"16" | X"1E" | -- ASL zp.x / ASL abs.x
			X"26" | X"2E" | -- ROL zp / ROL abs
			X"36" | X"3E" | -- ROL zp.x / ROL abs.x
			X"46" | X"4E" | -- LSR zp / LSR abs
			X"56" | X"5E" | -- LSR zp.x / LSR abs.x
			X"66" | X"6E" | -- ROR zp / ROR abs
			X"76" | X"7E" | -- ROR zp.x / ROR abs.x
			X"C6" | X"CE" | -- DEC zp / DEC abs
			X"D6" | X"DE" | -- DEC zp.x / DEC abs.x
			X"E6" | X"EE" | -- INC zp / INC abs
			X"F6" | X"FE" => -- INC zp.x / INC abs.x
			aluInput <= T;
		when
			X"0A" | -- ASL A
			X"2A" | -- ROL A
			X"4A" | -- LSR A
			X"6A" | -- ROR A
			X"C1" | X"C5" | X"C9" | X"CD" |
			X"D1" | X"D5" | X"D9" | X"DD" => -- CMP
			aluInput <= A;		
		when
			        X"84" | X"88" | X"8C" | -- STY zp / DEY / STY abs
			        X"94" | X"98" | -- STY zpx / TYA
			X"C0" | X"C4" | X"C8" | X"CC" => -- CPY / CPY / INY / CPY
			aluInput <= Y;
		when
			X"86" | X"8A" | X"8E" | -- STX zp / TXA / STX abs
			X"96" | X"9A" | -- STX zpy / TXS
			X"CA" | -- DEX
			X"E0" | X"E4" | X"EC" | -- CPX
			X"E8" => -- INX
			aluInput <= X;
		when -- A & X --
			X"83" | X"87" | X"8F" => -- iSAX (zp.x) / iSAX zp / iSAX abs
			aluInput <= A and X;
		when others =>
			aluInput <= (others => '-');
		end case;	
	end process;

	processAlu: process(opcode, aluInput, T, A, S, N, V, irqActive, D, I, Z, C)
		variable lowBits: unsigned(5 downto 0);
		variable nineBits: unsigned(8 downto 0);
	begin
		lowBits := (others => '-');
		nineBits := (others => '-');
		aluV <= '-';
		
		case opcode is
		when -- -- ADC -- --
			X"61" | X"65" | X"69" | X"6D" |
			X"71" | X"75" | X"79" | X"7D" => -- ADC
			lowBits := ("0" & A(3 downto 0) & C) + ("0" & T(3 downto 0) & "1");
			ninebits := ("0" & A) + ("0" & T) + (B"00000000" & C);
		when -- -- AND -- --
			X"21" | X"25" | X"29" | X"2D" |
			X"31" | X"35" | X"39" | X"3D" => -- AND
			ninebits(7 downto 0) := A and T;
		when -- -- BIT -- --
			X"24" | X"2C" => -- BIT
			ninebits(7 downto 0) := A and T;
		when -- -- CMP / CPX / CPY -- --
			X"C1" | X"C5" | X"C9" | X"CD" |
			X"D1" | X"D5" | X"D9" | X"DD" | -- CMP
			X"E0" | X"E4" | X"EC" | -- CPX
			X"C0" | X"C4" | X"CC" => -- CPY
			ninebits := ("0" & aluInput) + ("0" & (not T)) + B"000000001";			
		when -- -- DEC / DEX / DEY -- --
			X"88" | -- DEY
			X"C6" | X"CE" | -- DEC zp / DEC abs
			X"D6" | X"DE" | -- DEC zp.x / DEC abs.x
			X"CA" => -- DEX
			ninebits := ("0" & aluInput) - 1;
		when -- -- EOR -- --
			X"41" | X"45" | X"49" | X"4D" |
			X"51" | X"55" | X"59" | X"5D" => -- EOR
			ninebits(7 downto 0) := A xor T;
		when -- -- INC / INX / INY -- --
			X"C8" | -- INY
			X"E6" | X"EE" |
			X"F6" | X"FE" | -- INC
			X"E8" => -- INX
			ninebits := ("0" & aluInput) + 1;
		when -- -- ORA -- --
			X"01" | X"05" | X"09" | X"0D" |
			X"11" | X"15" | X"19" | X"1D" => -- ORA
			ninebits := ("0" & A) or ("0" & T);
		when -- -- SBC -- --
			X"E1" | X"E5" | X"E9" | X"ED" |
			X"F1" | X"F5" | X"F9" | X"FD" => -- SBC
			lowBits := ("0" & A(3 downto 0) & C) + ("0" & (not T(3 downto 0)) & "1");
			ninebits := ("0" & A) + ("0" & (not T)) + (B"00000000" & C);
		when -- -- ASL -- --
			X"06" | X"0A" | X"0E" |
			X"16" |         X"1E" => -- ASL
			nineBits := aluInput & B"0";
		when -- -- ROL -- --
			X"26" | X"2A" | X"2E" |
			X"36" |         X"3E" => -- ROL
			nineBits := aluInput & C;
		when -- -- LSR -- --
			X"46" | X"4A" | X"4E" |
			X"56" |         X"5E" => -- LSR
			nineBits := aluInput(0) & B"0" & aluInput(7 downto 1);
		when -- -- ROR -- --
			X"66" | X"6A" | X"6E" |
			X"76" |         X"7E" => -- ROR
			nineBits := aluInput(0) & C & aluInput(7 downto 1);
		when -- -- SAX -- --
			X"83" | X"87" | X"8F" => -- iSAX (zp.x) / iSAX zp / iSAX abs
			nineBits(7 downto 0) := aluInput;
		when -- -- A -- --
			X"48" | -- PHA
			X"81" | X"85" |         X"8D" | -- STA (zp.x) / STA zp / STA abs
			X"91" | X"95" | X"99" | X"9D" | -- STA (zp).y / STA zp.x / STA abs.y / STA abs.x
			X"A8" | X"AA" => -- TAY / TAX
			nineBits(7 downto 0) := A;
		when -- -- S -- --
			X"BA" => -- TSX
			nineBits(7 downto 0) := S;
		when -- -- X -- --
			X"86" | X"8A" | X"8E" | -- STX zp / TXA / STX abs
			X"96" | X"9A" => -- STX zpy / TXS
			nineBits(7 downto 0) := aluInput;
		when -- -- Y -- --
			X"84" | X"8C" | -- STY zp / STY abs
			X"94" | X"98" => -- STY zpx / TYA
			nineBits(7 downto 0) := aluInput;
		when -- -- T -- --
			X"28" | X"68" | -- PLP / PLA
			X"A0" | X"A1" | X"A2" | X"A3" | -- LDY imm / LDA (zp.x) / LDX imm / iLAX (zp.x)
			X"A4" | X"A5" | X"A6" | X"A7" | -- LDY zp / LDA zp / LDX zp / iLAX zp
			        X"A9" |         X"AB" | -- LDA imm / LAX imm
			X"AC" | X"AD" | X"AE" | X"AF" | -- LDY abs / LDA abs / LDX abs / iLAX abs
			        X"B1" |         X"B3" | -- LDA (zp).y / iLAX (zp).y
			X"B4" | X"B5" | X"B6" | X"B7" | -- LDY zp.x / LDA zp.x / LDX zp.y / iLAX zp.y
			        X"B9" |         X"BB" | -- LDA abs.y / LAX abs.y
			X"BC" | X"BD" | X"BE" | X"BF" => -- LDY abs.x / LDA abs.x / LDX abs.y / iLAX abs.y
			nineBits(7 downto 0) := T;
		when -- -- Flags -- --
			X"00" | X"08" => -- BRK / PHP
			nineBits(7 downto 0) := N & V & '1' & (not irqActive) & D & I & Z & C;
		when others =>
			null;
		end case;

		if ninebits(7 downto 0) = X"00" then
			aluZ <= '1';
		else
			aluZ <= '0';
		end if;

		case opcode is
		when -- -- ADC -- --
			-- decimal mode low bits correction, is done after setting Z flag.
 			X"61" | X"65" | X"69" | X"6D" |
			X"71" | X"75" | X"79" | X"7D" =>
			if D = '1' then
				if lowBits(5 downto 1) > 9 then
					ninebits(3 downto 0) := ninebits(3 downto 0) + 6;
					if lowBits(5) = '0'  then
						ninebits(8 downto 4) := ninebits(8 downto 4) + 1;
					end if;
				end if;
			end if;
		when others =>
			null;
		end case;

		aluN <= nineBits(7);			
		aluC <= ninebits(8);

		case opcode is
		when -- -- ADC -- --
			-- decimal mode high bits correction, is done after setting Z and N flags
 			X"61" | X"65" | X"69" | X"6D" |
			X"71" | X"75" | X"79" | X"7D" =>
			aluV <= (A(7) xor ninebits(7)) and (T(7) xor ninebits(7));
			if D = '1' then
				if ninebits(8 downto 4) > 9 then
					ninebits(8 downto 4) := ninebits(8 downto 4) + 6;
					aluC <= '1';
				end if;
			end if;
		when -- -- BIT -- --
			-- bit has somewhat unusual flag usage
			X"24" | X"2C" => -- BIT
			aluV <= T(6);
			aluN <= T(7);			
		when
			X"E1" | X"E5" | X"E9" | X"ED" |
			X"F1" | X"F5" | X"F9" | X"FD" => -- SBC 
			aluV <= (A(7) xor ninebits(7)) and ((not T(7)) xor ninebits(7));
			if D = '1' then
				-- Check for borrow (lower 4 bits)
				if lowBits(5) = '0' then
					ninebits(3 downto 0) := ninebits(3 downto 0) - 6;
				end if;
				-- Check for borrow (upper 4 bits)
				if ninebits(8) = '0' then
					ninebits(8 downto 4) := ninebits(8 downto 4) - 6;
				end if;
			end if;
		when others =>
			null;
		end case;

		aluOut <= ninebits(7 downto 0);	
	end process;

	indexAlu: process(opcode, T, X, Y, PC)
	begin
		case opcode is
		when -- Index with Y --
			X"11" | X"13" | X"19" | X"1B" | -- ORA (zp.y) / iSLO (zp.y) / ORA abs.y / iSLO abs.y
			X"31" | X"33" | X"39" | X"3B" |
			X"51" | X"53" | X"59" | X"5B" |
			X"71" | X"73" | X"79" | X"7B" |
			X"91" | X"93" | X"96" | X"97" | X"99" | X"9B" | X"9E" | X"9F" |
			X"B1" | X"B3" | X"B6" | X"B7" | X"B9" | X"BB" | X"BE" | X"BF" |
			X"D1" | X"D3" | X"D9" | X"DB" |
			X"F1" | X"F3" | X"F9" | X"FB" => -- (zp).y
			indexOut <= (B"0" & T) + (B"0" & Y);
		when -- Index with X --
			X"14" | X"15" | X"16" | X"17"
			| X"34" | X"35" | X"36" | X"37"
			| X"54" | X"55" | X"56" | X"57"
			| X"74" | X"75" | X"76" | X"77"
			| X"94" | X"95"
			| X"B4" | X"B5"
			| X"D4" | X"D5" | X"D6" | X"D7"
			| X"F4" | X"F5" | X"F6" | X"F7" => -- zp.x, illegal zp.x
			indexOut <= (B"0" & T) + (B"0" & X);
		when X"1C" | X"1D" | X"1E" | X"1F"
			| X"3C" | X"3D" | X"3E" | X"3F"
			| X"5C" | X"5D" | X"5E" | X"5F"
			| X"7C" | X"7D" | X"7E" | X"7F"
			| X"9C" | X"9D"
			| X"BC" | X"BD"
			| X"DC" | X"DD" | X"DE" | X"DF"
			| X"FC" | X"FD" | X"FE" | X"FF" => -- abs.x / illegal abs.x
			indexOut <= (B"0" & T) + (B"0" & X);
		when others =>		
			indexOut <= B"0" & T;
		end case;
	end process;

	stackPointer: process(opcode, S)
	begin
		case opcode is
		when X"00" | X"08" | X"20" | X"48" =>
			stackIncDec <= S - 1;
		when X"28" | X"40" | X"60" | X"68" =>
			stackIncDec <= S + 1;
		when others =>
			stackIncDec <= (others => '-');
		end case;
	end process;
	
	myAddrIncrL <= myAddr(7 downto 0) + 1;
	myAddrIncrH <= myAddr(15 downto 8) + 1;
	PCincr <= PC + 1;
	PCincrRel <= (B"0" & T) + (B"0" & PC(7 downto 0));

	process(clk)
	begin	
		if rising_edge(clk) then
			if enable = '1' then
				irqReg <= irq_n or I;
				we <= '0';
				case cpuCycle is
				when opcodeFetch =>
					brkActive <= '0';
					irqActive <= not irqReg;
					nmiReg <= nmi_n;
					fixedAddrL <= false;
					fixedAddrH <= false;

					if ((nmiReg = '1') and (nmi_n = '0')) or (irqReg = '0') then
						-- Simulate brk as it has the same logic as IRQ
						opcode <= X"00";
						-- Signal for easier implementing freezer cartridges and onboard debuggers
						-- is active when IRQ, NMI or BRK instruction is exectuted.
						brkActive <= '1';
					else
						-- Fetch opcode
						PC <= PCincr;
						opcode <= di;
					end if;
					myAddr <= PCincr;
					cpuCycle <= secondFetch;
					
					-- Store result of previous command
					case opcode is
					when
						X"06" | X"07"         | X"0E" | X"0F" | -- ASL zp / SLO zp / ASL abs / SLO abs
						X"16" | X"17" | X"1B" | X"1E" | X"1F" | -- ASL zp.x / SLO zp.x / SLO abs.y / ASL abs.x / SLO abs.x
						X"26" | X"27"         | X"2E" | X"2F" | -- ROL zp / ...
						X"36" | X"37" | X"3B" | X"3E" | X"3F" | -- ROL zp.x / ...
						X"46" | X"47"         | X"4E" | X"4F" | -- LSR zp / ...
						X"56" | X"57" | X"5B" | X"5E" | X"5F" | -- LSR zp.x / ...
						X"66" | X"67"         | X"6E" | X"6F" | -- ROR zp / ...
						X"76" | X"77" | X"7B" | X"7E" | X"7F" | -- ROR zp.x / ...
						        X"C7" |                 X"CF" | -- iDCP zp / iDCP abs
						        X"D7" | X"DB" |         X"DF" => -- iDCP zp.x / iDCP abs.y / iDCP abs.x
						C <= aluC;
						Z <= aluZ;
						N <= aluN;

--						        X"E7" |                 X"EF" | -- iISC zp
--						        X"F7" | X"FB" |         X"FF" =>
						-- C / V / Z / N

					when X"18" => -- CLC
						C <= '0';
					when X"24" | X"2C" => -- BIT
						Z <= aluZ;
						V <= aluV;
						N <= aluN;
					when X"28" | X"40" => -- PLP / RTI
						C <= T(0);
						Z <= T(1);
						I <= T(2);
						D <= T(3);
						V <= T(6);
						N <= T(7);
					when X"38" => -- SEC
						C <= '1';
					when X"58" => -- CLI
						I <= '0';
					when X"78" => -- SEI
						I <= '1';
					when X"B8" => -- CLV
						V <= '0';
					when X"D8" => -- CLD
						D <= '0';
					when X"F8" => -- SED
						D <= '1';
					when
						X"C6" | X"CE" | -- DEC zp / DEC abs
						X"D6" | X"DE" | -- DEC zp.x / DEC abs.x
						X"E6" | X"EE" | -- INC zp / INC abs
						X"F6" | X"FE" => -- INC zp.x / INC abs.x
						Z <= aluZ;
						N <= aluN;
					when
						X"C1" | X"C5" | X"C9" | X"CD" |
						X"D1" | X"D5" | X"D9" | X"DD" | -- CMP
						X"E0" | X"E4" | X"EC" | -- CPX
						X"C0" | X"C4" | X"CC" => -- CPY
						C <= aluC;
						Z <= aluZ;
						N <= aluN;
					when X"61" | X"65" | X"69" | X"6D" | X"71" | X"75" | X"79" | X"7D" -- ADC		
						| X"E1" | X"E5" | X"E9" | X"ED" | X"F1" | X"F5" | X"F9" | X"FD" => -- SBC 
						A <= aluOut;
						C <= aluC;
						Z <= aluZ;
						V <= aluV;
						N <= aluN;
					when X"0A" | X"2A" | X"4A" | X"6A"  => -- ASL A, ROL A, LSR A, ROR A
						A <= aluOut;
						C <= aluC;
						Z <= aluZ;
						N <= aluN;
					when X"01" | X"05" | X"09" | X"0D" | X"11" | X"15" | X"19" | X"1D" -- ORA
						| X"21" | X"25" | X"29" | X"2D" | X"31" | X"35" | X"39" | X"3D" -- AND
						| X"41" | X"45" | X"49" | X"4D" | X"51" | X"55" | X"59" | X"5D" -- EOR
						| X"A1" | X"A5" | X"A9" | X"AD" | X"B1" | X"B5" | X"B9" | X"BD" -- LDA
						| X"68" -- PLA
						| X"8A" | X"98" => -- TXA, TYA
						A <= aluOut;
						Z <= aluZ;
						N <= aluN;
					when X"88" | X"C8" -- DEY, INY
						| X"A0" | X"A4" | X"A8" | X"AC" | X"B4" | X"BC" => -- LDY imm, LDY zp, TAY, LDY abs, LDY zp.x, LDY abs.x
						Y <= aluOut;
						Z <= aluZ;
						N <= aluN;
					when
						X"A2" | X"A6" | X"AE" | -- LDX imm / LDX zp / LDX abs
						        X"B6" | X"BE" | -- LDX zp.y / LDX abs.y
						X"AA" | X"CA" | X"E8" | X"BA" => -- TAX, DEX, INX, TSX
						X <= aluOut;
						Z <= aluZ;
						N <= aluN;
					when X"9A" => -- TXS
						S <= aluInput;
					when
						X"A3" | X"A7" | X"AB" | X"AF" |
						X"B3" | X"B7" |         X"BF" => -- iLAX
						A <= aluOut;
						X <= aluOut;
						Z <= aluZ;
						N <= aluN;
					when others =>
						null;
					end case;
				when secondFetch =>
					-- Second cycle, all instructions will have this cycle.
					-- Reads byte which is not always used. 
					do <= (others => '-');
					T <= di;

					case opcode is
					when -- -- Zeropage -- --
						X"04" | X"05" | X"06" | X"07" | -- iNOP zp / ORA zp / ASL zp / iSLO zp
						X"24" | X"25" | X"26" | X"27" | -- BIT zp / AND zp / ROL zp / iRLA zp
						X"44" | X"45" | X"46" | X"47" | -- iNOP zp / EOR zp / LSR zp / iSRE zp
						X"64" | X"65" | X"66" | X"67" | -- iNOP zp / ADC zp / ROR zp / iRRA zp
						X"84" | X"85" | X"86" | X"87" | -- STY zp / STA zp / STX zp / iSAX zp
						X"A4" | X"A5" | X"A6" | X"A7" | -- LDY zp / LDA zp / LDY zp / iLAX zp
						X"C4" | X"C5" | X"C6" | X"C7" | -- CPY zp / CMP zp / DEC zp / iDCP zp
						X"E4" | X"E5" | X"E6" | X"E7" => -- CPX zp / SBC zp / INC zp / iISC zp
						PC <= PCincr;
						myAddr <= "00000000" & di;
						fixedAddrL <= true;
						fixedAddrH <= true;
						cpuCycle <= cycleReadWriteOrEnd;
						if opcode(7 downto 5) = "100" then
							do <= aluOut;
							we <= '1';
							cpuCycle <= cycleWriteEnd;
						end if;
					when -- -- Immediate -- --
						                X"09" | X"0B" | -- ORA imm / iANC imm
						                X"29" | X"2B" | -- AND imm / iANC imm
						                X"49" | X"4B" | -- EOR imm / iALR imm
						                X"69" | X"6B" | -- ADC imm / iARR imm
						X"80" | X"82" | X"89" | X"8B" | -- iNOP imm / iNOP imm / iNOP imm / iXAA imm			
						X"A0" | X"A2" | X"A9" | X"AB" | -- LDY imm / LDX imm / LDA imm / iLAX imm
						X"C0" | X"C2" | X"C9" | X"CB" | -- CPY imm / iNOP imm / CMP imm / iAXS imm
						X"E0" | X"E2" | X"E9" | X"EB" => -- CPX imm / iNOP imm / SBC imm / iSBC imm
						PC <= PCincr;
						myAddr <= PCincr;
						cpuCycle <= opcodeFetch;
					when -- -- (zp),y and (zp,x) -- --
						X"01" | X"11" | X"21" | X"31" | X"41" | X"51" | X"61" | X"71" |
						X"81" | X"91" | X"A1" | X"B1" | X"C1" | X"D1" | X"E1" | X"F1" | -- (zp).y / (zp).x
						X"03" | X"13" | X"23" | X"33" | X"43" | X"53" | X"63" | X"73" |
						X"83" | X"93" | X"A3" | X"B3" | X"C3" | X"D3" | X"E3" | X"F3" => -- illegal (zp).y
						PC <= PCincr;
						myAddr <= "00000000" & di;
						cpuCycle <= cycle3;					
					when -- -- Implied -- --
						        X"0A" | -- ASL A
						X"18" | X"1A" | -- CLC / iNOP
						        X"2A" | -- ROL A
						X"38" | X"3A" | -- SEC / iNOP
						        X"4A" | -- LSR A
						X"58" | X"5A" | -- CLI / iNOP
						        X"6A" | -- ROR A
						X"78" | X"7A" | -- SEI / iNOP
						X"88" | X"8A" | -- DEY / TXA
						X"98" | X"9A" | -- TYA / TXS
						X"A8" | X"AA" | -- TAY / TAX
						X"B8" | X"BA" | -- CLV / TSX
						X"C8" | X"CA" | -- INY / DEX
						X"D8" | X"DA" | -- CLD / iNOP
						X"E8" | X"EA" | -- INX / NOP (the only 'real' NOP :-)
						X"F8" | X"FA" => -- SED / iNOP
						cpuCycle <= opcodeFetch;
					when -- -- ABS / ABS,Y / ABS,X -- --
						                X"0C" | X"0D" | X"0E" | X"0F" | -- iNOP abs / ORA abs / ASL abs / iSLO abs
						X"19" | X"1B" | X"1C" | X"1D" | X"1E" | X"1F" | -- ORA abs.y / SLO abs.y / iNOP abs.x / ORA abs.x / ASL abs.x / iSLO abs.x
						                X"2C" | X"2D" | X"2E" | X"2F" | -- BIT abs / AND abs / ROL abs / iRLA abs
						X"39" | X"3B" | X"3C" | X"3D" | X"3E" | X"3F" | -- AND abs.y / iRLA abs.y / iNOP abs.x / AND abs.x / ROL abs.x / iRLA abs.x
						                X"4C" | X"4D" | X"4E" | X"4F" | -- JMP abs / EOR abs / LSR abs / iSRE abs
						X"59" | X"5B" | X"5C" | X"5D" | X"5E" | X"5F" | -- EOR abs.y / iSRE abs.y / iNOP abs.x / EOR abs.x / LSR abs.x / iSRE abs.x
						                X"6C" | X"6D" | X"6E" | X"6F" | -- JMP ind / ADC abs / ROR abs / iRRA abs
						X"79" | X"7B" | X"7C" | X"7D" | X"7E" | X"7F" | -- ADC abs.y / iRRA abs.y / iNOP abs.x / ADC abs.x / ROR abx.x / iRRA abs.x
						                X"8C" | X"8D" | X"8E" | X"8F" | -- STY abs / STA abs / STX abs / iSAX abs
						X"99" | X"9B" | X"9C" | X"9D" | X"9E" | X"9F" | -- STA abs.y / iTAS abs.y / iSHY abs.x / STA abs.x / SHX abs.y / AHX abs.y
						                X"AC" | X"AD" | X"AE" | X"AF" | -- LDY abs / LDA abs / LDX abs / iLAX abs
						X"B9" | X"BB" | X"BC" | X"BD" | X"BE" | X"BF" | -- LDA abs.y / iLAS abs.y / LDY abs.x / LDA abs.x / LDX abs.y / iLAX abs.y
						                X"CC" | X"CD" | X"CE" | X"CF" | -- CPY abs / CMP abs / DEC abs / iDCP abs
						X"D9" | X"DB" | X"DC" | X"DD" | X"DE" | X"DF" | -- CMP abs.y / iDCP abs.y / iNOP abs.x / CMP abs.x / DEC abs.x / iDCP abs.x
						                X"EC" | X"ED" | X"EE" | X"EF" | -- CPX abs / SBC abs / INC abs / iISC abs
						X"F9" | X"FB" | X"FC" | X"FD" | X"FE" | X"FF" => -- SBC abs.y / iISC abs.y / iNOP abs.x / SBC abs.x / INC abs.x / iISC abs.x
						PC <= PCincr;
						myAddr <= PCincr;
						cpuCycle <= cycle3;
					when -- -- Zeropage,x and Zeropage,y -- --
						X"14" | X"15" | X"16" | X"17" | -- iNOP zpx / ORA zpx / ASL zpx / iSLO zpx
						X"34" | X"35" | X"36" | X"37" | -- iNOP zpx / AND zpx / ROL zpx / iRLA zpx
						X"54" | X"55" | X"56" | X"57" | -- iNOP zpx / EOR zpx / LSR zpx / iSRE zpx
						X"74" | X"75" | X"76" | X"77" | -- iNOP zpx / ADC zpx / ROR zpx / iRRA zpx
						X"94" | X"95" | X"96" | X"97" | -- STY zpx / STA zpx / STX zpy / iSAX zpy
						X"B4" | X"B5" | X"B6" | X"B7" | -- LDY zpx / LDA zpx / LDX zpy / iLAX zpy
						X"D4" | X"D5" | X"D6" | X"D7" | -- iNOP zpx / CMP zpx / DEC zpx / iDCP zpx
						X"F4" | X"F5" | X"F6" | X"F7" => -- iNOP zpx / SBC zpx / INC zpx / iISC zpx
						PC <= PCincr;
						myAddr <= "00000000" & di;
						fixedAddrH <= true;
						cpuCycle <= cycleReadWriteOrEnd;
					when X"00" => -- BRK
						if ((nmiReg = '1') and (nmi_n = '0')) or (irqReg = '0') then
							-- IRQ / NMI
							do <= PC(15 downto 8);
						else
							-- BRK
							PC <= PCincr;
							do <= PCincr(15 downto 8);
						end if;					
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						we <= '1';
						cpuCycle <= cycleBrk3;
					when X"08" => -- PHP
						do <= aluOut;
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						we <= '1';
						cpuCycle <= cycleWriteEnd;
					when X"20" => -- JSR abs
						myAddr <= "00000001" & S;
						cpuCycle <= cycle3;
					when X"28" => -- PLP
						S <= stackIncDec;
						cpuCycle <= cycleReadStack;
					when X"40" => -- RTI
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						cpuCycle <= cycle3;						
					when X"48" => -- PHA
						do <= aluOut;
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						we <= '1';
						cpuCycle <= cycleWriteEnd;
					when X"60" => -- RTS
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						cpuCycle <= cycle3;
					when X"68" => -- PLA
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						cpuCycle <= cycleReadStack;
					when X"10" | X"30" | X"50" | X"70"
						| X"90" | X"B0" | X"D0" | X"F0" => -- Relative branch
						PC <= PCincr;
						myAddr <= PCincr;
						cpuCycle <= opcodeFetch;
						if (N = '0' and opcode = X"10") or
							(N = '1' and opcode = X"30") or
							(V = '0' and opcode = X"50") or
							(V = '1' and opcode = X"70") or
							(C = '0' and opcode = X"90") or
							(C = '1' and opcode = X"B0") or
							(Z = '0' and opcode = X"D0") or
							(Z = '1' and opcode = X"F0") then
							cpuCycle <= cycle3;
						end if;
					when others =>
						null;
					end case;
				when cycle3 =>
					do <= (others => '-');

					cpuCycle <= opcodeFetch;
					case opcode is
					when X"20" => -- JSR
						S <= stackIncDec;
						do <= PCincr(15 downto 8);
						myAddr <= "00000001" & S;
						we <= '1';
						cpuCycle <= cycle4;
					when X"40" => -- RTI
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						cpuCycle <= cycle4;	
					when X"4C" => -- JMP abs
						PC <= di & T;
						myAddr <= di & T;
						cpuCycle <= opcodeFetch;
					when X"60" => -- RTS
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						cpuCycle <= cycle4;
					when X"6C" => -- JMP ind
						myAddr <= di & T;
						cpuCycle <= readPcl;
					when X"10" | X"30" | X"50" | X"70" | X"90" | X"B0" | X"D0" | X"F0" => -- Relative branch					
						PC(7 downto 0) <= PCincrRel(7 downto 0);
						myAddr(7 downto 0) <= PCincrRel(7 downto 0);
						if PCincrRel(8) = T(7) then
							cpuCycle <= opcodeFetch;
						else
							if T(7) = '0' then
								PC(15 downto 8) <= PC(15 downto 8) + 1;
							else
								PC(15 downto 8) <= PC(15 downto 8) - 1;
							end if;
							cpuCycle <= cycle4;
						end if;
					when -- -- (zp.x) -- --
						X"01" | X"03" | X"21" | X"23" | X"41" | X"43" | X"61" | X"63" |
						X"81" | X"83" | X"A1" | X"A3" | X"C1" | X"C3" | X"E1" | X"E3" =>
						T <= di;
						myAddr(7 downto 0) <= (T + X);
						cpuCycle <= cycle4;					
					when -- -- (zp).y -- --
						X"11" | X"13" | X"31" | X"33" | X"51" | X"53" | X"71" | X"73" |
						X"91" | X"93" | X"B1" | X"B3" | X"D1" | X"D3" | X"F1" | X"F3" =>
						T <= di;
						myAddr(7 downto 0) <= myAddrIncrL;
						cpuCycle <= cycle4;					
					when -- -- ABS / ABS,Y / ABS,X -- --
						                X"0C" | X"0D" | X"0E" | X"0F" | -- iNOP abs / ORA abs / ASL abs / iSLO abs
						X"19" | X"1B" | X"1C" | X"1D" | X"1E" | X"1F" | -- ORA abs.y / SLO abs.y / iNOP abs.x / ORA abs.x / ASL abs.x / iSLO abs.x
						                X"2C" | X"2D" | X"2E" | X"2F" | -- BIT abs / AND abs / ROL abs / iRLA abs
						X"39" | X"3B" | X"3C" | X"3D" | X"3E" | X"3F" | -- AND abs.y / iRLA abs.y / iNOP abs.x / AND abs.x / ROL abs.x / iRLA abs.x
						                        X"4D" | X"4E" | X"4F" | -- EOR abs / LSR abs / iSRE abs
						X"59" | X"5B" | X"5C" | X"5D" | X"5E" | X"5F" | -- EOR abs.y / iSRE abs.y / iNOP abs.x / EOR abs.x / LSR abs.x / iSRE abs.x
						                        X"6D" | X"6E" | X"6F" | -- ADC abs / ROR abs / iRRA abs
						X"79" | X"7B" | X"7C" | X"7D" | X"7E" | X"7F" | -- ADC abs.y / iRRA abs.y / iNOP abs.x / ADC abs.x / ROR abx.x / iRRA abs.x
						                X"8C" | X"8D" | X"8E" | X"8F" | -- STY abs / STA abs / STX abs / iSAX abs
						X"99" | X"9B" | X"9C" | X"9D" | X"9E" | X"9F" | -- STA abs.y / iTAS abs.y / iSHY abs.x / STA abs.x / SHX abs.y / AHX abs.y
						                X"AC" | X"AD" | X"AE" | X"AF" | -- LDY abs / LDA abs / LDX abs / iLAX abs
						X"B9" | X"BB" | X"BC" | X"BD" | X"BE" | X"BF" | -- LDA abs.y / iLAS abs.y / LDY abs.x / LDA abs.x / LDX abs.y / iLAX abs.y
						                X"CC" | X"CD" | X"CE" | X"CF" | -- CPY abs / CMP abs / DEC abs / iDCP abs
						X"D9" | X"DB" | X"DC" | X"DD" | X"DE" | X"DF" | -- CMP abs.y / iDCP abs.y / iNOP abs.x / CMP abs.x / DEC abs.x / iDCP abs.x
						                X"EC" | X"ED" | X"EE" | X"EF" | -- CPX abs / SBC abs / INC abs / iISC abs
						X"F9" | X"FB" | X"FC" | X"FD" | X"FE" | X"FF" => -- SBC abs.y / iISC abs.y / iNOP abs.x / SBC abs.x / INC abs.x / iISC abs.x
						PC <= PCincr;
						fixedAddrL <= true;
						myAddr <= di & indexOut(7 downto 0);
						if opcode(7 downto 4) = "1000" then
							-- Absolute write instructions
							do <= aluOut;
							we <= '1';
							cpuCycle <= cycleWriteEnd;
						else
							cpuCycle <= cycleReadWriteOrEnd;
						end if;
					when others =>
						null;
					end case;
				when cycle4 =>
					do <= (others => '-');

					cpuCycle <= opcodeFetch;
					case opcode is
					when X"20" => -- JSR
						myAddr <= "00000001" & S;
						do <= PCincr(7 downto 0);
						we <= '1';
						cpuCycle <= cycle5;
					when X"40" => -- RTI
						T <= di;
						S <= stackIncDec;
						myAddr <= "00000001" & S;
						cpuCycle <= cycle5;	
					when X"60" => -- RTS
						PC(7 downto 0) <= di;
						myAddr <= "00000001" & S;
						cpuCycle <= cycle5;

					when X"10" | X"30" | X"50" | X"70" | X"90" | X"B0" | X"D0" | X"F0" => -- Relative branch
						myAddr <= PC;
						cpuCycle <= opcodeFetch;

					when -- -- (zp.x) -- --
						X"01" | X"03" | X"21" | X"23" | X"41" | X"43" | X"61" | X"63" |
						X"81" | X"83" | X"A1" | X"A3" | X"C1" | X"C3" | X"E1" | X"E3" =>
						T <= di;
						myAddr(7 downto 0) <= myAddrIncrL;
						cpuCycle <= cycle5;					
					when -- -- (zp).y -- --
						X"11" | X"13" | X"31" | X"33" | X"51" | X"53" | X"71" | X"73" |
						X"91" | X"93" | X"B1" | X"B3" | X"D1" | X"D3" | X"F1" | X"F3" =>
						fixedAddrL <= true;
						myAddr <= di & indexOut(7 downto 0);
						cpuCycle <= cycleReadWriteOrEnd;					
					when others =>
						null;
					end case;
				when cycle5 =>
					do <= (others => '-');

					cpuCycle <= opcodeFetch;
					case opcode is
					when X"20" => -- JSR
						S <= stackIncDec;
						myAddr <= PCincr;
						cpuCycle <= cycle6;
					when X"40" => -- RTI
						myAddr <= "00000001" & S;
						PC(7 downto 0) <= di;
						cpuCycle <= cycle6;	
					when X"60" => -- RTS
						PC(15 downto 8) <= di;
						myAddr <= di & PC(7 downto 0);
						cpuCycle <= cycle6;
					when -- -- (zp.x) -- --
						X"01" | X"03" | X"21" | X"23" | X"41" | X"43" | X"61" | X"63" |
						X"81" | X"83" | X"A1" | X"A3" | X"C1" | X"C3" | X"E1" | X"E3" =>
						myAddr <= di & T;
						cpuCycle <= cycleReadWriteOrEnd;
					when others =>
						null;
					end case;
				when cycle6 =>
					do <= (others => '-');

					cpuCycle <= opcodeFetch;
					case opcode is
					when X"20" => -- JSR
						PC <= di & T;
						myAddr <= di & T;
						cpuCycle <= opcodeFetch;
					when X"40" => -- RTI
						PC(15 downto 8) <= di;
						myAddr <= di & PC(7 downto 0);
						cpuCycle <= opcodeFetch;
					when X"60" => -- RTS
						PC <= PCincr;
						myAddr <= PCincr;
						cpuCycle <= opcodeFetch;
					when others =>
						null;
					end case;
				when cycleBrk3 =>
					do <= PC(7 downto 0);
					S <= stackIncDec;
					myAddr <= "00000001" & S;
					we <= '1';
					cpuCycle <= cycleBrk4;
				when cycleBrk4 =>
					do <= aluOut;
					S <= stackIncDec;
					I <= '1';
					myAddr <= "00000001" & S;
					we <= '1';
					cpuCycle <= cycleBrk5;
				when cycleBrk5 =>
					do <= (others => '-');
					myAddr <= X"FFFE";
					cpuCycle <= readPcl;				
				when readPcl =>
					do <= (others => '-');
					T <= di;

					myAddr(7 downto 0) <= myAddrIncrL;
					cpuCycle <= readPch;
				when readPch =>
					do <= (others => '-');

					PC <= di & T;
					myAddr <= di & T;
					cpuCycle <= opcodeFetch;
				when cycleReadWriteOrEnd =>
					do <= (others => '-');
					T <= di;
					if (indexOut(8) = '1' and (not fixedAddrH)) or (not fixedAddrL) then
						if not fixedAddrL then
							fixedAddrL <= true;
							myAddr(7 downto 0) <= indexOut(7 downto 0);
						end if;
						if (indexOut(8) = '1' and (not fixedAddrH)) then
							fixedAddrH <= true;
							myAddr(15 downto 8) <= myAddrIncrH;
						end if;
						if opcode(7 downto 5) = "100" then
							do <= aluOut;
							we <= '1';
							cpuCycle <= cycleWriteEnd;
						end if;
					else
						if opcode(7 downto 5) = "100" then
							do <= aluOut;
							we <= '1';
							cpuCycle <= cycleWriteEnd;
						elsif isRmwOpcode(opcode) then
							do <= di;
							we <= '1';
							cpuCycle <= cycleRwmCalc;
						else
							myAddr <= PC;
							cpuCycle <= opcodeFetch;
						end if;
					end if;						
				when cycleRwmCalc =>
					do <= aluOut;
					we <= '1';
					cpuCycle <= cycleWriteEnd;
				when cycleWriteEnd =>
					do <= (others => '-');
					myAddr <= PC;
					cpuCycle <= opcodeFetch;					
				when cycleReadStack => -- PLA, PLP
					do <= (others => '-');
					myAddr <= "00000001" & S;
					cpuCycle <= cycleReadStackEnd;
				when cycleReadStackEnd =>
					do <= (others => '-');
					T <= di;
					myAddr <= PC;
					cpuCycle <= opcodeFetch;				
				end case;
			end if;
			if reset = '1' then
				opcode <= X"4C";
				brkActive <= '0';
				fixedAddrL <= false;
				fixedAddrH <= false;
				PC <= X"FFFC";
				myAddr <= X"FFFC";
				cpuCycle <= secondFetch;
--				S <= X"FF";
--				irqReg <= '1';
			end if;
		end if;		
	end process;
	
	addr <= myAddr;
	pcDebugOut <= pc;
	opcodeDebugOut <= opcode;
	
end architecture;


