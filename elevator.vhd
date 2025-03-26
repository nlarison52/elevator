library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity elevator is
  port (
    up_req    : in  std_logic_vector(3 downto 1);  -- floors 1-3 (up requests)
    dn_req    : in  std_logic_vector(4 downto 2);  -- floors 2-4 (down requests)
    go_req    : in  std_logic_vector(4 downto 1);  -- floors 1-4 (inside elevator requests)
    poc       : in  std_logic;                     -- power-on clear
    clk       : in  std_logic;
    floor_ind : out std_logic_vector(4 downto 1);  -- one-hot current floor indicator
    emvup     : out std_logic;                     -- move up command
    emvdn     : out std_logic;                     -- move down command
    eopen     : out std_logic;                     -- door open command
    eclose    : out std_logic                      -- door close command
  );
end entity elevator;

architecture behavior of elevator is

  -- Define the elevator FSM states
  type state_type is (RESET, IDLE, MOVING, DOOR_OPENING, DOOR_OPEN, DOOR_CLOSING);
  signal state : state_type := RESET;
  
  -- Internal registers
  signal current_floor : integer range 1 to 4 := 1;
  signal target_floor  : integer range 1 to 4 := 1;
  signal current_dir   : std_logic := '1';  -- '1' for up, '0' for down
  signal timer         : integer := 0;
  
  -- Delay constants (assume clock is 2Hz: 2 sec = 4 cycles, 3 sec = 6 cycles)
  constant MOVE_DELAY : integer := 4;  -- delay for moving one floor
  constant DOOR_DELAY : integer := 6;  -- door remains open delay
  
  -- Combine external request signals into one pending vector (floor1..4)
  signal pending : std_logic_vector(4 downto 1);
  -- For floor 1, only up_req and go_req are valid; floor 4 has no up_req.
  -- (For floor 4, dn_req and go_req are used; floor 1 has no dn_req.)
  
  -- Internal command signals for outputs
  signal cmd_emvup, cmd_emvdn, cmd_eopen, cmd_eclose : std_logic := '0';

begin

  -- Generate the pending requests vector
  pending(1) <= go_req(1) or up_req(1);
  pending(2) <= go_req(2) or up_req(2) or dn_req(2);
  pending(3) <= go_req(3) or up_req(3) or dn_req(3);
  pending(4) <= go_req(4) or dn_req(4);

  -- Drive the floor indicator output as a one-hot encoding of current_floor.
  with current_floor select
    floor_ind <= "0001" when 1,
                 "0010" when 2,
                 "0100" when 3,
                 "1000" when 4,
                 "0000" when others;

  -- Assign the internal command signals to the outputs.
  emvup  <= cmd_emvup;
  emvdn  <= cmd_emvdn;
  eopen  <= cmd_eopen;
  eclose <= cmd_eclose;

  -- Main FSM process
  process(clk)
    variable found_floor : integer;
  begin
    if rising_edge(clk) then
      if poc = '1' then  -- Synchronous reset on power-on clear
        state         <= RESET;
        current_floor <= 1;
        target_floor  <= 1;
        current_dir   <= '1';
        timer         <= 0;
        cmd_emvup     <= '0';
        cmd_emvdn     <= '0';
        cmd_eopen     <= '0';
        cmd_eclose    <= '0';
      else
        case state is
          when RESET =>
            -- Transition to IDLE after reset
            state <= IDLE;
            timer <= 0;
            
          when IDLE =>
            -- In IDLE, clear movement and door commands.
            cmd_emvup  <= '0';
            cmd_emvdn  <= '0';
            cmd_eopen  <= '0';
            cmd_eclose <= '0';
            timer <= 0;
            -- If the current floor is requested, go open the door.
            if pending(current_floor) = '1' then
              state <= DOOR_OPENING;
            -- If any pending request exists...
            elsif pending /= "0000" then
              -- Determine the next target floor.
              found_floor := current_floor;  -- initialize with current floor
              if current_dir = '1' then  -- if current direction is up
                for i in current_floor+1 to 4 loop
                  if pending(i) = '1' then
                    found_floor := i;
                    exit;
                  end if;
                end loop;
                -- If no pending request found upward, search downward.
                if found_floor = current_floor then
                  for i in current_floor-1 downto 1 loop
                    if pending(i) = '1' then
                      found_floor := i;
                      current_dir <= '0';  -- change direction to down
                      exit;
                    end if;
                  end loop;
                end if;
              else  -- current_dir = '0', i.e., down
                for i in current_floor-1 downto 1 loop
                  if pending(i) = '1' then
                    found_floor := i;
                    exit;
                  end if;
                end loop;
                -- If no pending request found downward, search upward.
                if found_floor = current_floor then
                  for i in current_floor+1 to 4 loop
                    if pending(i) = '1' then
                      found_floor := i;
                      current_dir <= '1';
                      exit;
                    end if;
                  end loop;
                end if;
              end if;
              target_floor <= found_floor;
              state <= MOVING;
            else
              state <= IDLE;  -- Remain idle if no requests
            end if;
            
          when MOVING =>
            -- Issue movement command based on the direction.
            if current_dir = '1' then
              cmd_emvup <= '1';
              cmd_emvdn <= '0';
            else
              cmd_emvdn <= '1';
              cmd_emvup <= '0';
            end if;
            timer <= timer + 1;
            if timer >= MOVE_DELAY then
              timer <= 0;
              -- Update the current floor based on the direction.
              if current_dir = '1' then
                if current_floor < 4 then
                  current_floor <= current_floor + 1;
                end if;
              else
                if current_floor > 1 then
                  current_floor <= current_floor - 1;
                end if;
              end if;
              -- Stop the movement command once the floor is updated.
              cmd_emvup <= '0';
              cmd_emvdn <= '0';
              -- If we have reached the target floor, proceed to door sequence.
              if current_floor = target_floor then
                state <= DOOR_OPENING;
              else
                state <= MOVING;  -- Continue moving otherwise.
              end if;
            end if;
            
          when DOOR_OPENING =>
            -- Initiate the door opening command.
            cmd_eopen <= '1';
            cmd_eclose <= '0';
            timer <= timer + 1;
            -- Assume door open command is effective immediately (or in one cycle)
            if timer >= 1 then  
              timer <= 0;
              state <= DOOR_OPEN;
            end if;
            
          when DOOR_OPEN =>
            -- Keep the door open for the specified delay (simulate waiting period).
            cmd_eopen <= '0';
            timer <= timer + 1;
            if timer >= DOOR_DELAY then
              timer <= 0;
              state <= DOOR_CLOSING;
            else
              state <= DOOR_OPEN;
            end if;
            
          when DOOR_CLOSING =>
            -- Issue door close command.
            cmd_eclose <= '1';
            timer <= timer + 1;
            if timer >= 1 then  -- Assume door closes in one cycle
              cmd_eclose <= '0';
              timer <= 0;
              -- Here you might want to clear the request for current_floor.
              -- For simplicity, we assume that external logic clears the request,
              -- or you can design additional registers to hold and clear pending requests.
              state <= IDLE;
            end if;
            
          when others =>
            state <= IDLE;
        end case;
      end if;
    end if;
  end process;

end architecture behavior;
