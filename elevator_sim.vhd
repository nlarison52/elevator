library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity elevator_simulator is
  port(
    sysclk : in std_logic;                    -- System clock (assumed 2Hz)
    poc    : in std_logic;                    -- Power-on clear
    emvup  : in std_logic;                    -- Move up command from controller
    emvdn  : in std_logic;                    -- Move down command from controller
    eopen  : in std_logic;                    -- Door open command from controller
    eclose : in std_logic;                    -- Door close command from controller
    ef     : out std_logic_vector(4 downto 1);  -- One-hot current floor indicator (EF)
    ecomp  : out std_logic                     -- Command complete signal (ECOMP)
  );
end elevator_simulator;

architecture behavior of elevator_simulator is

  -- Define simulator states
  type sim_state_type is (SIM_IDLE, MOVING_UP, MOVING_DOWN, DOOR_OPENING, DOOR_CLOSING);
  signal sim_state : sim_state_type := SIM_IDLE;
  
  -- Current floor (1 to 4) and a timer for delay management
  signal current_floor : integer range 1 to 4 := 1;
  signal sim_timer     : integer := 0;
  
  -- Delay constants (assuming SYSCLK is 2Hz)
  constant MOVE_DELAY : integer := 4;  -- 2 seconds = 4 clock cycles
  constant DOOR_DELAY : integer := 6;  -- 3 seconds = 6 clock cycles

begin

  -- One-hot encoding for the current floor indicator EF
  with current_floor select
    ef <= "0001" when 1,
          "0010" when 2,
          "0100" when 3,
          "1000" when 4,
          "0000" when others;

  process(sysclk)
  begin
    if rising_edge(sysclk) then
      if poc = '1' then
        -- Reset condition: Initialize simulator
        current_floor <= 1;
        sim_state     <= SIM_IDLE;
        sim_timer     <= 0;
        ecomp         <= '1';  -- No command in progress
      else
        case sim_state is
          when SIM_IDLE =>
            -- In idle state, ECOMP is asserted to indicate readiness.
            ecomp <= '1';
            -- Check for movement or door commands.
            if emvup = '1' and current_floor < 4 then
              sim_state <= MOVING_UP;
              sim_timer <= 0;
              ecomp     <= '0';  -- Begin movement; command not complete
            elsif emvdn = '1' and current_floor > 1 then
              sim_state <= MOVING_DOWN;
              sim_timer <= 0;
              ecomp     <= '0';
            elsif eopen = '1' then
              sim_state <= DOOR_OPENING;
              sim_timer <= 0;
              ecomp     <= '0';
            elsif eclose = '1' then
              sim_state <= DOOR_CLOSING;
              sim_timer <= 0;
              ecomp     <= '0';
            end if;
          
          when MOVING_UP =>
            -- Simulate movement delay for moving up one floor.
            sim_timer <= sim_timer + 1;
            if sim_timer >= MOVE_DELAY then
              current_floor <= current_floor + 1;
              ecomp         <= '1';         -- Movement complete
              sim_state     <= SIM_IDLE;
              sim_timer     <= 0;
            end if;
          
          when MOVING_DOWN =>
            -- Simulate movement delay for moving down one floor.
            sim_timer <= sim_timer + 1;
            if sim_timer >= MOVE_DELAY then
              current_floor <= current_floor - 1;
              ecomp         <= '1';
              sim_state     <= SIM_IDLE;
              sim_timer     <= 0;
            end if;
          
          when DOOR_OPENING =>
            -- Simulate door open delay.
            sim_timer <= sim_timer + 1;
            if sim_timer >= DOOR_DELAY then
              ecomp     <= '1';  -- Door open operation complete
              sim_state <= SIM_IDLE;
              sim_timer <= 0;
            end if;
          
          when DOOR_CLOSING =>
            -- Simulate door close delay.
            sim_timer <= sim_timer + 1;
            if sim_timer >= DOOR_DELAY then
              ecomp     <= '1';  -- Door close operation complete
              sim_state <= SIM_IDLE;
              sim_timer <= 0;
            end if;
          
          when others =>
            sim_state <= SIM_IDLE;
        end case;
      end if;
    end if;
  end process;

end architecture behavior;
