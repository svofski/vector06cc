-------------------------------------------------------------------[26.01.2011]
-- YM2149 SSG
-------------------------------------------------------------------------------
-- V0.1 	26.01.2011	первая версия

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity YM2149 is
	port (
		CLK			: in  std_logic;
		ENA			: in  std_logic;
		RESET		: in  std_logic;
		BDIR		: in  std_logic;
		CS			: in  std_logic;
		BC			: in  std_logic;
		DI			: in  std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0);
		OUT_A		: out std_logic_vector(7 downto 0);
		OUT_B		: out std_logic_vector(7 downto 0);
		OUT_C		: out std_logic_vector(7 downto 0));
end;

architecture RTL of YM2149 is
	type  array_3x12   is array (1 to 3) of std_logic_vector(11 downto 0);

	signal freq_a		: std_logic_vector(11 downto 0);
	signal freq_b		: std_logic_vector(11 downto 0);
	signal freq_c		: std_logic_vector(11 downto 0);
	signal noise		: std_logic_vector(4 downto 0);
	signal settings		: std_logic_vector(7 downto 0);
	signal level_a		: std_logic_vector(4 downto 0);
	signal level_b		: std_logic_vector(4 downto 0);
	signal level_c		: std_logic_vector(4 downto 0);
	signal envelope		: std_logic_vector(15 downto 0);
	signal shape		: std_logic_vector(3 downto 0);
	signal port_a		: std_logic_vector(7 downto 0);
	signal port_b		: std_logic_vector(7 downto 0);
	signal cnt_div		: unsigned(2 downto 0) := (others => '0');
	signal noise_div	: std_logic := '0';
	signal ena_div		: std_logic;
	signal ena_div_noise: std_logic;
	signal poly17		: std_logic_vector(16 downto 0) := (others => '0');
	signal addr			: std_logic_vector(3 downto 0);
	signal env_reset	: std_logic;
	signal noise_gen_cnt: unsigned(4 downto 0);
	signal noise_gen_op	: std_logic;
	signal tone_gen_cnt	: array_3x12 := (others => (others => '0'));
	signal tone_gen_op	: std_logic_vector(3 downto 1) := "000";
	signal env_gen_cnt	: std_logic_vector(15 downto 0);
	signal env_ena		: std_logic;
	signal env_hold		: std_logic;
	signal env_inc		: std_logic;
	signal env_vol		: std_logic_vector(4 downto 0);

	function volTable (value : std_logic_vector(4 downto 0)) return std_logic_vector is
		variable result : std_logic_vector (7 downto 0);
	begin
		case value is
			when "00000" => result := "00000000";
			when "00001" => result := "00000001";
			when "00010" => result := "00000010";
			when "00011" => result := "00000010";
			when "00100" => result := "00000011";
			when "00101" => result := "00000011";
			when "00110" => result := "00000100";
			when "00111" => result := "00000101";
			when "01000" => result := "00000110";
			when "01001" => result := "00000111";
			when "01010" => result := "00001000";
			when "01011" => result := "00001001";
			when "01100" => result := "00001011";
			when "01101" => result := "00001101";
			when "01110" => result := "00010000";
			when "01111" => result := "00010011";
			when "10000" => result := "00010110";
			when "10001" => result := "00011010";
			when "10010" => result := "00011111";
			when "10011" => result := "00100101";
			when "10100" => result := "00101100";
			when "10101" => result := "00110100";
			when "10110" => result := "00111101";
			when "10111" => result := "01001000";
			when "11000" => result := "01010100";
			when "11001" => result := "01100011";
			when "11010" => result := "01110100";
			when "11011" => result := "10001000";
			when "11100" => result := "10011111";
			when "11101" => result := "10111010";
			when "11110" => result := "11011001";
			when "11111" => result := "11111111";
			when others => null;
		end case;
	return result;
	end volTable;

begin
	p_wdata : process (RESET, CLK, CS, BDIR, BC, addr, freq_a, freq_b, freq_c, noise, settings, level_a, level_b, level_c, envelope, shape, port_a, port_b)
	begin
		if RESET = '1' then
			freq_a		<= (others => '0');
			freq_b		<= (others => '0');
			freq_c		<= (others => '0');
			noise		<= (others => '0');
			settings	<= x"FF";
			level_a		<= (others => '0');
			level_b		<= (others => '0');
			level_c		<= (others => '0');
			envelope	<= (others => '0');
			shape		<= (others => '0');
			port_a		<= (others => '0');
			port_b		<= (others => '0');
			addr		<= (others => '0');
		elsif CLK'event and CLK = '1' then
			if CS = '1' and BDIR = '1' then
				if BC = '1' then
					addr <= DI(3 downto 0);
				else
					env_reset <= '0';
					case addr is
						when "0000" => freq_a(7 downto 0)	<= DI;
						when "0001" => freq_a(11 downto 8)	<= DI(3 downto 0);
						when "0010" => freq_b(7 downto 0)	<= DI;
						when "0011" => freq_b(11 downto 8)	<= DI(3 downto 0);
						when "0100" => freq_c(7 downto 0)	<= DI;
						when "0101" => freq_c(11 downto 8)	<= DI(3 downto 0);
						when "0110" => noise				<= DI(4 downto 0);
						when "0111" => settings				<= DI;
						when "1000" => level_a				<= DI(4 downto 0);
						when "1001" => level_b				<= DI(4 downto 0);
						when "1010" => level_c				<= DI(4 downto 0);
						when "1011" => envelope(7 downto 0)	<= DI;
						when "1100" => envelope(15 downto 8)<= DI;
						when "1101" => shape				<= DI(3 downto 0); env_reset <= '1';
						when "1110" => port_a				<= DI;
						when "1111" => port_b				<= DI;
						when others => null;
					end case;
				end if;
			end if;
		end if;
--		case addr is
--			when "0000" => DO <= freq_a(7 downto 0);
--			when "0001" => DO <= "0000" & freq_a(11 downto 8);
--			when "0010" => DO <= freq_b(7 downto 0);
--			when "0011" => DO <= "0000" & freq_b(11 downto 8);
--			when "0100" => DO <= freq_c(7 downto 0);
--			when "0101" => DO <= "0000" & freq_c(11 downto 8);
--			when "0110" => DO <= "000" & noise;
--			when "0111" => DO <= settings;
--			when "1000" => DO <= "000" & level_a;
--			when "1001" => DO <= "000" & level_b;
--			when "1010" => DO <= "000" & level_c;
--			when "1011" => DO <= envelope(7 downto 0);
--			when "1100" => DO <= envelope(15 downto 8);
--			when "1101" => DO <= "0000" & shape;
--			when "1110" => if settings(6) = '1' then DO <= port_a; end if;
--			when "1111" => if settings(7) = '1' then DO <= port_b; end if;
--			when others => DO <= (others => '1');
--		end case;
	end process;
	
	DO <=	freq_a(7 downto 0)				when addr = "0000" else
			"0000" & freq_a(11 downto 8)	when addr = "0001" else
			freq_b(7 downto 0)				when addr = "0010" else
			"0000" & freq_b(11 downto 8)	when addr = "0011" else
			freq_c(7 downto 0)				when addr = "0100" else
			"0000" & freq_c(11 downto 8)	when addr = "0101" else
			"000" & noise					when addr = "0110" else
			settings						when addr = "0111" else
			"000" & level_a					when addr = "1000" else
			"000" & level_b					when addr = "1001" else
			"000" & level_c					when addr = "1010" else
			envelope(7 downto 0)			when addr = "1011" else
			envelope(15 downto 8)			when addr = "1100" else
			"0000" & shape					when addr = "1101" else
			port_a							when addr = "1110" and settings(6) = '1' else
			port_b							when addr = "1111" and settings(7) = '1' else	
			(others => '1');

	process (CLK, ENA)
	begin
		if CLK'event and CLK = '1' then
			if ENA = '1' then
				ena_div <= '0';
				ena_div_noise <= '0';
				if cnt_div = "000" then
					cnt_div <= "111";
					ena_div <= '1';
					noise_div <= not noise_div;
					if noise_div = '1' then ena_div_noise <= '1'; end if;
				else
					cnt_div <= cnt_div - "1";
				end if;
			end if;
		end if;
	end process;

	process (CLK)
		variable noise_gen_comp : unsigned(4 downto 0);
		variable poly17_zero : std_logic;
	begin
	if CLK'event and CLK = '1' then
		if noise = "00000" then
			noise_gen_comp := "00000";
		else
			noise_gen_comp := unsigned(noise) - 1;
		end if;
		poly17_zero := '0';
		if poly17 = "00000000000000000" then poly17_zero := '1'; end if;
		if ENA = '1' then
			if ena_div_noise = '1' then -- divider ena
				if noise_gen_cnt >= noise_gen_comp then
					noise_gen_cnt <= "00000";
					poly17 <= (poly17(0) xor poly17(2) xor poly17_zero) & poly17(16 downto 1);
				else
					noise_gen_cnt <= noise_gen_cnt + 1;
				end if;
			end if;
		end if;
	end if;
	end process;
	
	noise_gen_op <= poly17(0);

	process (CLK)
		variable tone_gen_freq : array_3x12;
		variable tone_gen_comp : array_3x12;
	begin
	if CLK'event and CLK = '1' then
		-- looks like real chips count up - we need to get the Exact behaviour ..
		tone_gen_freq(1) := freq_a;
		tone_gen_freq(2) := freq_b;
		tone_gen_freq(3) := freq_c;
		-- period 0 = period 1
		for i in 1 to 3 loop
			if tone_gen_freq(i) = x"000" then
				tone_gen_comp(i) := x"000";
			else
				tone_gen_comp(i) := std_logic_vector( unsigned(tone_gen_freq(i)) - 1 );
			end if;
		end loop;
		if ENA = '1' then
			for i in 1 to 3 loop
				if ena_div = '1' then -- divider ena
					if tone_gen_cnt(i) >= tone_gen_comp(i) then
						tone_gen_cnt(i) <= x"000";
						tone_gen_op(i) <= not tone_gen_op(i);
					else
						tone_gen_cnt(i) <= std_logic_vector( unsigned(tone_gen_cnt(i)) + 1 );
					end if;
				end if;
			end loop;
		end if;
	end if;
	end process;

	process (CLK, ENA)
		variable env_gen_freq : std_logic_vector(15 downto 0);
		variable env_gen_comp : std_logic_vector(15 downto 0);
	begin
	if CLK'event and CLK = '1' then
		env_gen_freq := envelope;
		-- envelope freqs 1 and 0 are the same.
		if env_gen_freq = x"0000" then
			env_gen_comp := x"0000";
		else
			env_gen_comp := std_logic_vector( unsigned(env_gen_freq) - 1 );
		end if;
		if ENA = '1' then
			env_ena <= '0';
			if ena_div = '1' then -- divider ena
				if env_gen_cnt >= env_gen_comp then
					env_gen_cnt <= x"0000";
					env_ena <= '1';
				else
					env_gen_cnt <= std_logic_vector( unsigned( env_gen_cnt ) + 1 );
				end if;
			end if;
		end if;
	end if;
	end process;

	process (env_reset, CLK, shape)
		variable is_bot    : boolean;
		variable is_bot_p1 : boolean;
		variable is_top_m1 : boolean;
		variable is_top    : boolean;
	begin
		if env_reset = '1' then
			-- load initial state
			if shape(2) = '0' then -- attack
				env_vol <= "11111";
				env_inc <= '0'; -- -1
			else
				env_vol <= "00000";
				env_inc <= '1'; -- +1
			end if;
			env_hold <= '0';
		elsif CLK'event and CLK = '1' then
			is_bot    := (env_vol = "00000");
			is_bot_p1 := (env_vol = "00001");
			is_top_m1 := (env_vol = "11110");
			is_top    := (env_vol = "11111");
			if ENA = '1' then
				if env_ena = '1' then
					if env_hold = '0' then
						if env_inc = '1' then
							env_vol <= std_logic_vector(unsigned(env_vol) + "00001");
						else
							env_vol <= std_logic_vector(unsigned(env_vol) + "11111");
						end if;
					end if;
					-- envelope shape control.
					if shape(3) = '0' then
						if env_inc = '0' then -- down
							if is_bot_p1 then env_hold <= '1'; end if;
						else
							if is_top then env_hold <= '1'; end if;
						end if;
					else
						if shape(0) = '1' then -- hold = 1
							if env_inc = '0' then -- down
								if shape(1) = '1' then -- alt
									if is_bot    then env_hold <= '1'; end if;
								else
									if is_bot_p1 then env_hold <= '1'; end if;
								end if;
							else
								if shape(1) = '1' then -- alt
									if is_top    then env_hold <= '1'; end if;
								else
									if is_top_m1 then env_hold <= '1'; end if;
								end if;
							end if;
						elsif shape(1) = '1' then -- alternate
							if env_inc = '0' then -- down
								if is_bot_p1 then env_hold <= '1'; end if;
								if is_bot    then env_hold <= '0'; env_inc <= '1'; end if;
							else
								if is_top_m1 then env_hold <= '1'; end if;
								if is_top    then env_hold <= '0'; env_inc <= '0'; end if;
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;

	process (CLK, ENA, RESET)
	begin
		if RESET = '1' then
			OUT_A <= (others => '0');
			OUT_B <= (others => '0');
			OUT_C <= (others => '0');
		elsif CLK'event and CLK = '1' then
			if ENA = '1' then
				if ((settings(0) or tone_gen_op(1)) and (settings(3) or noise_gen_op)) = '0' then
					OUT_A <= (others => '0');
				elsif level_a(4) = '0' then
					OUT_A <= volTable(level_a(3 downto 0) & "1");
				else
					OUT_A <= volTable(env_vol);
				end if;
				if ((settings(1) or tone_gen_op(2)) and (settings(4) or noise_gen_op)) = '0' then
					OUT_B <= (others => '0');
				elsif level_b(4) = '0' then
					OUT_B <= volTable(level_b(3 downto 0) & "1");
				else
					OUT_B <= volTable(env_vol);
				end if;
				if ((settings(2) or tone_gen_op(3)) and (settings(5) or noise_gen_op)) = '0' then
					OUT_C <= (others => '0');
				elsif level_c(4) = '0' then
				OUT_C <= volTable(level_c(3 downto 0) & "1");
				else
					OUT_C <= volTable(env_vol);
				end if;
			end if;
		end if;
	end process;
	
end architecture rtl;