library ieee;
use ieee.std_logic_1164.all;

entity elevator is
  port (
    up_req : in std_logic_vector(3 donwto 1); -- floors requiring upwards transportation
    dn_req : in std_logic_vector(4 downto 2); -- floors requiring downward transportaion
    go_req : in std_logic_vector(4 downto 1); -- floors pressed from inside elevator
    poc : in std_logic;
    clk : in std_logic;
    floor_ind : out std_logic_vector(4 downto 1); -- current floor occupied
    emvup : out std_logic; -- move up command
    emvdn : out std_logic; -- move down command 
    eopen : out std_logic; -- open door command 
    eclose : out std_logic -- close door command 
       );


end entity elevator;


architecture behavior of elevator is
  signal current_dir : std_logic := '0'; -- 1 is up, 0 is down (internal signal)
  signal moving : std_logic := '0'; -- 0 is not moving, 1 is moving

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if (poc = '1') then -- reset state

      else -- normal operation



      end if
    end if
  end process

end  behavior;
