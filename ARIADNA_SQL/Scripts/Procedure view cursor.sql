declare 

rc1                pkg_global.ref_cursor_type;
begin

pkg_servtolab.materialsforServCount ('627501776505', '1562200', 1,
	 rc1);
:r:=rc1;	 
end;