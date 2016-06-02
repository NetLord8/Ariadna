CREATE OR REPLACE procedure SOLUTION_MED.MEDCALL_SYNC
as
p_pat_call number;  --номер пациента
p_num_call varchar2(100);
p_num_call2 varchar2(100);
p_num_call3 varchar2(100);
p_spec_ex number;
p_finance varchar2(100);
p_count number;
pat_cell varchar2(100);
res_medcall varchar2(100);
marker number:=0;--отметка об отмене номерка
pat_visitid varchar(255);--id визита 
old_dialnum varchar(255):='';--для логирования старый номер телефона
old_dialnum2 varchar(255):='';--для логирования старый номер телефона
old_dialnum3 varchar(255):='';--для логирования старый номер телефона
old_result varchar(255):='';--для логирования старый статус
count_doc number:=0;--переменная нужна чтобы узнать мсключен ли локтор или нет 
dep_v number:=0;--id отделения
doc_d number :=0;--id врача на отделении
res varchar(126):=''; 
v_pat_id number; 
exception_pat number:=0;--переменная нужна чтобы узнать мсключен ли пациент или нет 

begin

--проверим на вшивость то что уже есть.
for rc_call in (
SELECT id,
       dialnum,
       dialnum2,
       dialnum3,
       tn,
       result
  FROM autodialout where datetotell >sysdate
  and nvl(result,0) in (0,98))

loop

begin
select nvl(patientid,0),
nvl(substr(pkg_unique_aterisk_test.get_phone_osn_kont(p.keyid),-11),pkg_unique_aterisk_test.get_phone_osn_kont(p.keyid)) as osn_tel, 
nvl(substr(nvl(fn_get_only_numbers(replace(p.cellular,'+7','8')),0),-11),nvl(fn_get_only_numbers(replace(p.cellular,'+7','8')),0)) as p_cellular,
nvl(substr(nvl(fn_get_only_numbers(replace(p.phone,'+7','8')),0),-11),nvl(fn_get_only_numbers(replace(p.phone,'+7','8')),0)) as p_cell,
nvl(r.visitid,0) as visitid,
(select nvl(v.depid,0) from visit v where r.visitid=v.keyid(+)) as dep_v,
r.docdepid, 
p.keyid
---pkg_unique_aterisk_test.get_phone_dop_kont(p.keyid) as dop_tel---убрал 24,07
into 
p_pat_call,
p_num_call,
p_num_call2,
p_num_call3,--добавлено baa 24,06,2015 чтобы писались еще и допконтакты
pat_visitid,---добавлено baa 30.07.2015
dep_v,--добавлено 
doc_d,
v_pat_id
from rnumb r, patient p where r.keyid=rc_call.tn
and p.keyid(+)=r.patientid;

exception when no_data_found then
  p_pat_call:=0;
  p_num_call:=0;
  p_num_call2:=0;
  p_num_call3:=0;
  pat_visitid:='';
  dep_v:=0;
  v_pat_id:=0;
  
end;


---"старые" номер телефонов и статус
--=================================----
old_dialnum:=rc_call.dialnum;
old_dialnum2:=rc_call.dialnum2;
old_dialnum3:=rc_call.dialnum3;
old_result:=rc_call.result;
/*select
am."dialnum"
,am."dialnum2"
,am."dialnum3"
,am."result"
into
old_dialnum,
old_dialnum2,
old_dialnum3,
old_result
from 
"autodialout"@MEDCALL am
where 
am."id"=rc_call."id";*/
--=====================================------

--отмена, если номерок снят
if (nvl(p_pat_call,0)=0 or p_pat_call=51422000) --(врач не принимает, для закрытия расписания)
  then
  marker:=1;
  
update  autodialout
set result='96'
,visit_id=0--добавлено 30,07,2015 baa 
--,"dialnum"='0'--убрано по просьбе Вадима 24,06,2015
where id=rc_call.id;
--commit;
    --запись в лог
 /*update_log_autodialout(autodialout_id => rc_call."id"
                        ,rnumb_keyid => rc_call."tn"
                        ,old_dialnum => old_dialnum
                        ,old_dialnum2 => old_dialnum2
                        ,old_dialnum3 => old_dialnum3
                        ,old_result => old_result
                        ,new_result => '96');*/
                        
end if;

--смена номера
if ((p_num_call!=rc_call.dialnum
 or p_num_call2!=rc_call.dialnum2
 or p_num_call3!=rc_call.dialnum3) and marker=0)then
 
  select 
  nvl(p_num_call,'0')
  into pat_cell
  from dual;
  
  
  
   --считаем кол-во исключенных
  select
  count(dd.keyid)
  into 
  count_doc
  from
  docdep dd
  where 
  dd.keyid=doc_d
  and dd.keyid in(SELECT attr.linkid
          FROM solution_med.attr
               
         WHERE attr.rootid IN (SELECT keyid
                                 FROM attr
                                WHERE rootid = (SELECT keyid
                                                  FROM ATTR
                                                 WHERE TAG = 6
                                                   AND CODE = 515
                                                   AND ROOTID = 0)
                                  AND code = 1));
                                  
           --or
          -- dep_v in (27000)--аквадоктор 2

--==========================================  
---- смотрим, исключен ли пациент или нет
SELECT count(attr.linkid)
        into exception_pat
          FROM solution_med.attr
               
         WHERE attr.rootid IN (SELECT keyid
                                 FROM attr
                                WHERE rootid = (SELECT keyid
                                                  FROM ATTR
                                                 WHERE TAG = 90027
                                                   AND CODE = 1
                                                   AND ROOTID = 0)
                                  AND code=1)
and 
attr.linkid=v_pat_id;
    
    --если >0, то исключаем    
    if count_doc>0 or exception_pat>0
     then 
         res_medcall:='92';
    else
    res_medcall:=rc_call.result;
  end if;
  

  
  if (p_num_call=0 and p_num_call2=0
    and p_num_call3=0)
  then
    res_medcall:='96';
 end if;



 
update  autodialout
set dialnum=pat_cell-----nvl(p_num_call,'0')
,dialnum2=p_num_call2--добавлено baa 24,06,2015 чтобы писались еще и осн. контакты
,dialnum3=p_num_call3--добавлено baa 24,06,2015 чтобы писались еще и допконтакты
,result=res_medcall----decode(nvl(p_num_call,'0'),'0','96',"result")
,visit_id=pat_visitid
where id=rc_call.id;
--commit;
    --запись в лог
/*
 update_log_autodialout(autodialout_id => rc_call."id"
                        ,rnumb_keyid => rc_call."tn"
                        ,old_dialnum => old_dialnum
                        ,old_dialnum2 => old_dialnum2
                        ,old_dialnum3 => old_dialnum3
                        ,old_result => old_result
                        ,new_result => res_medcall);
                        */
end if;
  

---- проверяем в любом случае, исключен ли клиент или нет
   --считаем кол-во исключенных
  select
  count(dd.keyid)
  into 
  count_doc
  from
  docdep dd
  where 
  dd.keyid=doc_d
  and dd.keyid in(SELECT attr.linkid
          FROM solution_med.attr
               
         WHERE attr.rootid IN (SELECT keyid
                                 FROM attr
                                WHERE rootid = (SELECT keyid
                                                  FROM ATTR
                                                 WHERE TAG = 6
                                                   AND CODE = 515
                                                   AND ROOTID = 0)
                                  AND code = 1));
--==========================================  
---- смотрим, исключен ли пациент или нет
SELECT count(attr.linkid)
        into exception_pat
          FROM solution_med.attr
               
         WHERE attr.rootid IN (SELECT keyid
                                 FROM attr
                                WHERE rootid = (SELECT keyid
                                                  FROM ATTR
                                                 WHERE TAG = 90027
                                                   AND CODE = 1
                                                   AND ROOTID = 0)
                                  AND code=1)
and 
attr.linkid=v_pat_id;
    --если >0, то исключаем    
    if count_doc>0 or exception_pat>0
     then 
          update  autodialout
          set dialnum=nvl(pat_cell,0)-----nvl(p_num_call,'0')
          ,dialnum2=nvl(p_num_call2,0)--добавлено baa 24,06,2015 чтобы писались еще и осн. контакты
          ,dialnum3=nvl(p_num_call3,0)--добавлено baa 24,06,2015 чтобы писались еще и допконтакты
          ,result='92'----decode(nvl(p_num_call,'0'),'0','96',"result")
          ,visit_id=pat_visitid
          where id=rc_call.id;
   end if;


--обнуляем все
  p_pat_call:=0;
  p_num_call:=0;
  p_num_call2:=0;
  p_num_call3:=0;
  pat_visitid:='';
  marker:=0;
  old_dialnum:='';
  old_dialnum2:='';
  old_dialnum3:='';
  old_result:='';
  res_medcall:='';
  dep_v:=0;
  doc_d:=0;
  v_pat_id:=0;


end loop;

commit;

--=====================---
--1)основной контакт
--2)сотовый
--3)домашний

--добавляем новые записи
  for rc in (
  select
nvl(substr(pkg_unique_aterisk_test.get_phone_osn_kont(p.keyid),-11),pkg_unique_aterisk_test.get_phone_osn_kont(p.keyid))as dialnum,
nvl(substr(nvl(fn_get_only_numbers(replace(p.cellular,'+7','8')),0),-11),nvl(fn_get_only_numbers(replace(p.cellular,'+7','8')),0)) as dialnum2,
nvl(substr(nvl(fn_get_only_numbers(replace(p.phone,'+7','8')),0),-11),nvl(fn_get_only_numbers(replace(p.phone,'+7','8')),0)) as dialnum3,        
 -- pkg_unique_aterisk.get_phone_dop_kont(p.keyid)as dialnum3,--убрано 24,07
  sysdate as date_sys,
  nvl(fn_get_lu_omscode(dd.specid),fn_get_lu_code(dd.specid)) as spescode,
  r.dat,
   (select v.depid from visit v where  r.visitid=v.keyid ) as dep,
  r.updatedate,
  fn_man_code_by_id(r.updateby) as reg_code,
  fn_get_lu_name(dd.specid) as specname,
  r.keyid,
  r.visitid,
  (select a.finance /*fn_get_agr_finance_name(v.agrid)*/ from visit v,agr a where v.keyid=r.visitid and v.agrid=a.keyid) as finance,
  r.docdepid as doc_d,
  p.keyid as pat_id
  from rnumb r, patient p, docdep dd where 
  r.dat>sysdate
  and r.patientid>0
  and r.patientid=p.keyid
  and r.docdepid=dd.keyid
  ----добавлено чтобы исключить номерки которые еще недооформили
  and r.edit_now_status!=1
  ---
  and nvl(nvl(fn_get_only_numbers(replace(p.cellular,'+7','8')),
  fn_get_only_numbers(replace(p.phone,'+7','8'))),' ')!=' '
  and not exists (SELECT *
  FROM autodialout  where tn=r.keyid and nvl(result,0)!='96')
  )
  loop

 --считаем кол-во исключенных
  select
  count(dd.keyid)
  into 
  count_doc
  from
  docdep dd
  where 
  dd.keyid=rc.doc_d
  and dd.keyid in(SELECT attr.linkid
          FROM solution_med.attr
               
         WHERE attr.rootid IN (SELECT keyid
                                 FROM attr
                                WHERE rootid = (SELECT keyid
                                                  FROM ATTR
                                                 WHERE TAG = 6
                                                   AND CODE = 515
                                                   AND ROOTID = 0)
                                  AND code = 1))
          -- or
          -- rc.dep in (27000)--аквадоктор 2
           ;
--==========================================  
---- смотрим, исключен ли пациент или нет
SELECT count(attr.linkid)
        into exception_pat
          FROM solution_med.attr
               
         WHERE attr.rootid IN (SELECT keyid
                                 FROM attr
                                WHERE rootid = (SELECT keyid
                                                  FROM ATTR
                                                 WHERE TAG = 90027
                                                   AND CODE = 1
                                                   AND ROOTID = 0)
                                  AND code=1)
and 
attr.linkid=rc.pat_id;
    --если >0, то исключаем
    if count_doc>0 or exception_pat>0
     then 
         res_medcall:='92';
       ---все равно добавляем запись со статусом 92
  insert into autodialout (dialnum,dialnum2,dialnum3,datetime,type,datetotell,datebeg,mis_code,tn,finance,filial,visit_id,result,patient_id)
  values                           (rc.dialnum,rc.dialnum2,rc.dialnum3,rc.date_sys,rc.spescode,rc.dat,rc.updatedate,rc.reg_code,rc.keyid,rc.finance,rc.dep,rc.visitid,res_medcall,rc.pat_id);


     else   
         res_medcall:='0';
    ---иначе добавляем                
   -- dbms_output.put_line('новый пациент '||rc.dialnum);
     insert into autodialout(dialnum,dialnum2,dialnum3,datetime,type,datetotell,datebeg,mis_code,tn,finance,filial,visit_id,patient_id)
  values                           (rc.dialnum,rc.dialnum2,rc.dialnum3,rc.date_sys,rc.spescode,rc.dat,rc.updatedate,rc.reg_code,rc.keyid,rc.finance,rc.dep,rc.visitid,rc.pat_id);
 
    end if;
    commit;



  select count(*)
  into p_spec_ex
  from "codes"@MEDCALL where "code"=rc.spescode;





  if p_spec_ex=0 then
   --set_medcal_codes(rc.spescode,rc.specname); 
  insert into "codes"@MEDCALL ("code","name")
 values(rc.spescode,rc.specname);
  end if;
 commit;
 


    --логирование

/*  insert_log_autodialout(rnumb_keyid =>rc.keyid,
                         new_result=>res_medcall);*/

 count_doc:=0;
res_medcall:=''; 
 end loop;





 for rc_call2 in (
SELECT *
  FROM autodialout  where datetotell <= sysdate
  and datetotell >= trunc(sysdate)-5
  and nvl(result,0)=0)

loop

  select count(*)
  into p_count
  from rnumb r, visit v where
  r.visitid=v.keyid
  and nvl(v.vistype,0)>0
  and r.keyid=rc_call2.tn;

  if nvl(p_count,0)>0 then

  select 
  ---fn_get_agr_finance_name(v.agrid)
  (select a.finance from agr a where a.keyid=v.agrid)
  into p_finance
  from rnumb r, visit v where
  r.visitid=v.keyid
  and r.keyid=rc_call2.tn;

    update autodialout
  set visit=1 ,
  finance=p_finance
  where
  id=rc_call2.id;
  end if;


 end loop;
 commit;



end;
/