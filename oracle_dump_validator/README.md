Oracle dump file validator
==========================

How to use it:

2 ways:
1) Login to the oracle as sysdba and copy to the console all the content of the sql file <b> except first lone with CONNECT!!!! </b>
2) Correct user/name in the first line of sql file (in CONNECT section). And then execute this file via @

  Then in the same console execute such commands:
<i>

  SET serveroutput on SIZE 1000000  
  exec show_dumpfile_info(p_dir=> 'my_dir', p_file=> 'expdp_s.dmp')

</i>

where p_dir - full path to the dump file folder, p_file - dump file name
# usefull_scripts
