#!/usr/bin/python
import csv
v_len = 40
v_nchan = 3
f=csv.reader(open("test_data.csv","r"))
fo=open("test_data_pkg.vhd","w")
fo.write("""
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package test_data_pkg is
""")
s=[]
for i in range(0,v_nchan):
  s.append(f.next())
  if len(s[i]) != v_len:
     raise(Exception("Wrong length of data"))
for i in range(0,v_nchan):
  sl="constant data_ch"+str(i)+" : unsigned(639 downto 0) := \""
  for j in range(0,v_len):
    sl+=format(int(s[i][j]),"0>16b")
  sl+="\";\n"
  fo.write(sl)
fo.write("""
end package;
""")


