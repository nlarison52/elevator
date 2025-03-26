library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Test bench entity has no ports.
entity testbench_elevator is
end entity testbench_elevator;

architecture behavior of testbench_elevator is

  ----------------------------------------------------------------------------
  -- Component Declarations
  ----------------------------------------------------------------------------
  -- Elevator Controller component declaration
  component elevator is
    port (
      up_req    : in  std_logic_vector(3 downto 1);
      dn_req    : in  std_logic_vector(4 downto 2);
      go_req    : in  std_logic_vector(4 downto 1);
      poc       : in  std_logic;
      clk       : in  std_logic;
      floor_ind : out std_logic_vector(4 downto 1);
      emvup     : out std_logic;
      emvdn     : out std_logic;
      eopen     : out std_logic;
      eclose    : out std_logic
    );
  end component;

  -- Elevator Simulator component declaration
  component elevator_simulator is
    port (
      sysclk : in std_logic;
      poc    : in std_logic;
      emvup  : in std_logic;
      emvdn  : in std_logic;
      eopen  : in std_logic;
      eclose : in std_logic;
      ef     : out std_logic_vector(4 downto 1);
      ecomp  : out std_logic
    );
  end component;

  ----------------------------------------------------------------------------
  -- Signal Declarations
  ----------------------------------------------------------------------------
  signal clk      : std_logic := '0';
  signal poc      : std_logic := '0';

  -- External request vectors. You can change these to stimulate different floors.
  signal up_req   : std_logic_vector(3 downto 1) := (others => '0');
  signal dn_req   : std_logic_vector(4 downto 2) := (others => '0');
  signal go_req   : std_logic_vector(4 downto 1) := (others => '0');

  -- Signals connecting the controller to the simulator.
  signal floor_ind : std_logic_vector(4 downto 1);
  signal emvup     : std_logic;
  signal emvdn     : std_logic;
  signal eopen     : std_logic;
  signal eclose    : std_logic;
  signal ef        : std_logic_vector(4 downto 1);
  signal ecomp     : std_logic;

  -- Clock period constant. For a 2Hz clock, period = 500 ms.
  constant CLK_PERIOD : time := 500 ms;

begin

  ----------------------------------------------------------------------------
  -- Instantiate the Elevator Controller
  ----------------------------------------------------------------------------
  UUT_Controller: elevator
    port map (
      up_req    => up_req,
      dn_req    => dn_req,
      go_req    => go_req,
      poc       => poc,
      clk       => clk,
      floor_ind => floor_ind,
      emvup     => emvup,
      emvdn     => emvdn,
      eopen     => eopen,
      eclose    => eclose
    );

  ----------------------------------------------------------------------------
  -- Instantiate the Elevator Simulator
  ----------------------------------------------------------------------------
  UUT_Simulator: elevator_simulator
    port map (
      sysclk => clk,   -- Using the same clock signal as the controller
      poc    => poc,
      emvup  => emvup,
      emvdn  => emvdn,
      eopen  => eopen,
      eclose => eclose,
      ef     => ef,
      ecomp  => ecomp
    );

  ----------------------------------------------------------------------------
  -- Clock Generation Process
  ----------------------------------------------------------------------------
  clock_process : process
  begin
    -- Generate a periodic clock with CLK_PERIOD
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process clock_process;

  ----------------------------------------------------------------------------
  -- Stimulus Process
  ----------------------------------------------------------------------------
  stim_proc : process
  begin
    ----------------------------------------------------------------------------
    -- Initialization & Reset:
    -- Apply a reset (POC high) for a few clock cycles, then deassert it.
    ----------------------------------------------------------------------------
    poc <= '1';
    wait for 2 * CLK_PERIOD;
    poc <= '0';
    wait for CLK_PERIOD;

    ----------------------------------------------------------------------------
    -- Test 1: Up Request on Floor 1
    -- Example: Simulate a request for upward movement from floor 1.
    ----------------------------------------------------------------------------
    up_req(1) <= '1';
    wait for 2 * CLK_PERIOD;
    up_req(1) <= '0';

    ----------------------------------------------------------------------------
    -- Wait for the elevator to process the door operation and movement.
    ----------------------------------------------------------------------------
    wait for 10 * CLK_PERIOD;

    ----------------------------------------------------------------------------
    -- Test 2: Inside Request (GO_REQ) to go to Floor 3
    -- Example: Simulate a request from within the elevator to go to floor 3.
    ----------------------------------------------------------------------------
    go_req(3) <= '1';
    wait for 2 * CLK_PERIOD;
    go_req(3) <= '0';

    ----------------------------------------------------------------------------
    -- Wait for the elevator to complete the movement and door sequence.
    ----------------------------------------------------------------------------
    wait for 15 * CLK_PERIOD;

    ----------------------------------------------------------------------------
    -- Test 3: Down Request from Floor 4
    -- Example: Simulate a down request on floor 4.
    ----------------------------------------------------------------------------
    dn_req(4) <= '1';
    wait for 2 * CLK_PERIOD;
    dn_req(4) <= '0';

    ----------------------------------------------------------------------------
    -- Wait for a while to observe the behavior before ending simulation.
    ----------------------------------------------------------------------------
    wait for 20 * CLK_PERIOD;
    assert false report "Simulation Finished" severity failure;

    ----------------------------------------------------------------------------
    -- End of Simulation:
    -- You can stop the simulation here or add more tests.
    ----------------------------------------------------------------------------
    wait;
  end process stim_proc;

end architecture behavior;
