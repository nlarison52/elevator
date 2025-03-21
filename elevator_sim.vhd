library ieee;
use ieee.std_logic_1164.all;


entity elevator_sim is
  port(
  poc : in std_logic;
  clk : in std_logic;
  emvup : in std_logic;
  emvdn : in std_logic;
  eopen : in std_logic;
  eclose : in std_logic;
  ecomp : out std_logic;
  ef : out std_logic_vector(4 downto 1)
      );
end elevator_sim;


architecture behavior of elevator_sim is


begin



end behavior;
