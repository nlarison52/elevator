library ieee;
use ieee.std_logic_1164.all;

entity elevator is
  port (
    up_req : in std_logic_vector(3 donwto 1);
    dn_req : in std_logic_vector(4 downto 2);
    go_req : in std_logic_vector(4 downto 1);
    poc : in std_logic;
    clk : in std_logic;
    floor_ind : out std_logic_vector(4 downto 1);
    emvup : out std_logic;
    emvdn : out std_logic;
    eopen : out std_logic;
    eclose : out std_logic
       );


end entity elevator;


architecture behavior of elevator is

begin


end  behavior;
