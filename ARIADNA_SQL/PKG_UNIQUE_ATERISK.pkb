CREATE OR REPLACE package body SOLUTION_MED.PKG_UNIQUE_Aterisk as

  procedure Insert_doctor_in_asterisk(newkeyid     in varchar,
                                      d_firstname  in varchar,
                                      d_secondname in varchar,
                                      d_lastname   in varchar,
                                      d_type       in varchar,
                                      d_phone      in varchar,
                                      d_status     in number,
                                      d_spec_lu    in number)
  
   as
   phone_doc varchar(32);
   doc_type number:=3; --4- не выводим
                       --3-выводим
                                      
    pragma autonomous_transaction; --создает локальную транзакцию
  begin
    if d_spec_lu in (88982000,--  Водитель
89541,--  Водитель выходного дня
88916000,--  Массажист
89416,--  Медсестра по физиотерапии
89194000,--  Медсестра по ФТЛ
89845,--  Менеджер клиентского отдела
89407,--  Менеджер МЦ
89439,--  Менеджер отдела "Педиатрия"
89846,--  Менеджер ОТП
89732,--  Менеджер по работе с СК
26173,--  Невролог
85205,--  Ортопед
26180,--  Отоларинголог
26181,--  Офтальмолог
83123,--  Педиатр
89375,--  Руководитель диспетчеркой службы
89425,--  Руководитель отдела телефонных продаж 
26210,--  Хирург
85048--  Хирург-ортопед
                       )
       then
         doc_type:=3;
       else 
         doc_type:=4;
    end if; 
    
    phone_doc:=nvl(d_phone,0);
    
  
    insert into "phonebook"@MEDCALL
      ("doc_id",
       "name",
       "patronname",
       "surname",
       "type",
       "extnumber",
       "status")
    values
      (newkeyid,
       d_firstname,
       d_secondname,
       d_lastname,
       doc_type,
       phone_doc,
       d_status);
    commit;
  
  end Insert_doctor_in_asterisk;

  procedure Update_doctor_in_asterisk(newkeyid     in varchar,
                                      d_firstname  in varchar,
                                      d_secondname in varchar,
                                      d_lastname   in varchar,
                                      d_phone      in varchar,
                                      d_status     in number,
                                      d_spec_lu    in number)
  
   as
      doc_type number:=3; --4- не выводим
                       --3-выводим
    pragma autonomous_transaction; --создает локальную транзакцию, без этой фигни не работает 
  begin
    if d_spec_lu in (88982000,--	Водитель
89541,--	Водитель выходного дня
88916000,--	Массажист
89416,--	Медсестра по физиотерапии
89194000,--	Медсестра по ФТЛ
89845,--	Менеджер клиентского отдела
89407,--	Менеджер МЦ
89439,--	Менеджер отдела "Педиатрия"
89846,--	Менеджер ОТП
89732,--	Менеджер по работе с СК
26173,--	Невролог
85205,--	Ортопед
26180,--	Отоларинголог
26181,--	Офтальмолог
83123,--	Педиатр
89375,--	Руководитель диспетчеркой службы
89425,--	Руководитель отдела телефонных продаж 
26210,--	Хирург
85048--	Хирург-ортопед
                       )
       then
         doc_type:=3;
       else 
         doc_type:=4;
    end if; 
    update "phonebook"@MEDCALL
       set "name"       = d_firstname,
           "patronname" = d_secondname,
           "surname"    = d_lastname,
           "extnumber"  = d_phone,
           "status"     = d_status,
           "type"       = doc_type
     where "doc_id" = newkeyid;
    commit;
  
  end;
  --возвращает № отдела куда должен пойти звонок

  function fn_get_group_Asterisk(p_keyid in number) return number as
    Otdel               number;
    agr_pat_keyid       number;
    police_pat_keyid    number;
    abonement_pat_keyid number;
    rec_count           number;
  begin
    --по умолчинию звонок уходит в ОТП
    ---0-ОТП
    ---1-Ксендзова договора
    ---2-Страховой отдел
    ---3-Вакцинация
    ---4-Гепатит
    otdel := 0;
  
    select nvl(p.agrid, 0) as agr_key,
           nvl(p.policeid, 0) as agr_key,
           nvl((select ap.abonement_id
                 from police pol,abonementpat ap
                where pol.keyid = p.policeid
                      and pol.abonementpat_id=ap.keyid),
               0) as ab_key
      into agr_pat_keyid, police_pat_keyid, abonement_pat_keyid
      from patient p
     where p.keyid = p_keyid;
  
    ---если есть абонемент
    if (agr_pat_keyid > 0 and police_pat_keyid > 0 and
       abonement_pat_keyid > 0) then
      ---если договор входит в атрибут 28-8-2(Абонементы для договоров)
      select count(t.link_id)
        into rec_count
        from (SELECT LINK_ID
                FROM solution_med.attr,
                     (SELECT a.keyid AS link_id
                        FROM abonement a
                       ) t
               WHERE attr.rootid IN
                     (SELECT keyid
                        FROM attr
                       WHERE rootid = (SELECT keyid
                                         FROM ATTR
                                        WHERE TAG = 28
                                          AND CODE = 8
                                          AND ROOTID = 0)
                         AND code = 2)
                 AND t.link_id = attr.linkid) t
       where t.LINK_ID = abonement_pat_keyid;
    
      if rec_count != 0 then
        rec_count := 0;
        otdel     := 1;
        return otdel;
      end if;
    
      ---если договор входит в атрибут 28-8-3(Абонементы для страхового отдела)
      select count(t.link_id)
        into rec_count
        from (SELECT LINK_ID
              
                FROM solution_med.attr,
                     (SELECT a.keyid AS link_id
                        FROM abonement a
                       ) t
               WHERE attr.rootid IN
                     (SELECT keyid
                        FROM attr
                       WHERE rootid = (SELECT keyid
                                         FROM ATTR
                                        WHERE TAG = 28
                                          AND CODE = 8
                                          AND ROOTID = 0)
                         AND code = 3)
                 AND t.link_id = attr.linkid) t
       where t.link_id = abonement_pat_keyid;
    
      if rec_count != 0 then
        rec_count := 0;
        otdel     := 2;
        return otdel;
      end if;
    
      ---если договор входит в атрибут 28-8-4(Абонементы по вакцинации)
      select count(*)
        into rec_count
        from (SELECT LINK_ID
                FROM solution_med.attr,
                     (SELECT a.keyid AS link_id
                        FROM abonement a
                       ) t
               WHERE attr.rootid IN
                     (SELECT keyid
                        FROM attr
                       WHERE rootid = (SELECT keyid
                                         FROM ATTR
                                        WHERE TAG = 28
                                          AND CODE = 8
                                          AND ROOTID = 0)
                         AND code = 4)
                 AND t.link_id = attr.linkid) t
       where t.link_id = abonement_pat_keyid;
    
      if rec_count != 0 then
        rec_count := 0;
        otdel     := 3;
        return otdel;
      end if;
    
      ---если договор входит в атрибут 28-8-5(Гепатит)
      select count(*)
        into rec_count
        from (SELECT LINK_ID
                FROM solution_med.attr,
                     (SELECT a.keyid AS link_id
                        FROM abonement a
                       ) t
               WHERE attr.rootid IN
                     (SELECT keyid
                        FROM attr
                       WHERE rootid = (SELECT keyid
                                         FROM ATTR
                                        WHERE TAG = 28
                                          AND CODE = 8
                                          AND ROOTID = 0)
                         AND code = 5)
                 AND t.link_id = attr.linkid) t
       where t.link_id = abonement_pat_keyid;
    
      if rec_count != 0 then
        rec_count := 0;
        otdel     := 4;
        return otdel;
      end if;
    
    
    
    
    
    end if;
    ---если нет абонемента, то пробегаемся по атрибутам 90026(Атрибуты шифров (agr)-1(Шифры для астериска))
    if (agr_pat_keyid > 0 and police_pat_keyid > 0 and
       abonement_pat_keyid = 0) then
      ----если шифр входит в атрибут 90026-1-1(Шифры для ОТП), то отправляем в отп
      select count(*)
        into rec_count
        from (SELECT LINK_ID
              
                FROM solution_med.attr,
                     (SELECT a.keyid AS link_id FROM agr a) t
               WHERE attr.rootid IN
                     (SELECT keyid
                        FROM attr
                       WHERE rootid = (SELECT keyid
                                         FROM ATTR
                                        WHERE TAG = 90026
                                          AND CODE = 1
                                          AND ROOTID = 0)
                         AND code = 1)
                 AND t.link_id = attr.linkid) t
       where t.link_id = agr_pat_keyid;
    
      if rec_count != 0 then
        rec_count := 0;
        otdel     := 0;
        return otdel;
      end if;
    
      ----если шифр входит в атрибут 90026-1-2 (Шифры для договорного отдела), то отправляем в договорной отдел(ксендзова)
      select count(*)
        into rec_count
        from (SELECT LINK_ID
              
                FROM solution_med.attr,
                     (SELECT a.keyid AS link_id FROM agr a) t
               WHERE attr.rootid IN
                     (SELECT keyid
                        FROM attr
                       WHERE rootid = (SELECT keyid
                                         FROM ATTR
                                        WHERE TAG = 90026
                                          AND CODE = 1
                                          AND ROOTID = 0)
                         AND code = 2)
                 AND t.link_id = attr.linkid) t
       where t.link_id = agr_pat_keyid;
    
      if rec_count != 0 then
        rec_count := 0;
        otdel     := 1;
        return otdel;
      end if;
    
      ----если шифр входит в атрибут 90026-1-3 (Шифры для страхового отдела), то отправляем в страховой отдел(ломова)
      select count(*)
        into rec_count
        from (SELECT LINK_ID
              
                FROM solution_med.attr,
                     (SELECT a.keyid AS link_id FROM agr a ) t
               WHERE attr.rootid IN
                     (SELECT keyid
                        FROM attr
                       WHERE rootid = (SELECT keyid
                                         FROM ATTR
                                        WHERE TAG = 90026
                                          AND CODE = 1
                                          AND ROOTID = 0)
                         AND code = 3)
                 AND t.link_id = attr.linkid) t
       where t.link_id = agr_pat_keyid;
    
      if rec_count != 0 then
        rec_count := 0;
        otdel     := 2;
        return otdel;
      end if;
      ----если шифр входит в атрибут 90026-1-4 (Шифры для вакцинации), то отправляем диспетчеру по вакциинации, по идеи не нужен, но на всякий случай
      select count(*)
        into rec_count
        from (SELECT LINK_ID
              
                FROM solution_med.attr,
                     (SELECT a.keyid AS link_id FROM agr a) t
               WHERE attr.rootid IN
                     (SELECT keyid
                        FROM attr
                       WHERE rootid = (SELECT keyid
                                         FROM ATTR
                                        WHERE TAG = 90026
                                          AND CODE = 1
                                          AND ROOTID = 0)
                         AND code = 4)
                 AND t.link_id = attr.linkid) t
       where t.link_id = agr_pat_keyid;
    
      if rec_count != 0 then
        rec_count := 0;
        otdel     := 3;
        return otdel;
      end if;
    
    end if;
    return otdel;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
    
  end;
---процедура к-рая формирует текст смс расписания на завтрашний день для врача и записывает в таблицу для отправки
procedure upload_sheduler_doctor
as
  begin
    
  for rc in(
 select distinct
rn.keyid as rnumb_id,
trim(d.phone)  as phone
,dd.text as doctor
,dep.text as dep
,rn.dat as time_v
,to_char(rn.dat, 'dd.mm')||' у Вас первый прием в '||to_char(rn.dat, 'hh24:mi')||' в МЦ '||dep.text as text
,p.num
,DEP.INTERNAL_CODE as senderid -- номер отправителя
from docdep dd,
     doctor d,
     rnumb rn,
     patient p,
     visit v,
     dep dep
where 
dd.docid=d.keyid
--and dep.keyid in (6000,8000,27000)
and rn.visitid=v.keyid
and v.depid=dep.keyid
and d.phone is not null
and rn.docdepid=dd.keyid
and trunc(rn.dat)=trunc(sysdate+1)
and nvl(rn.patientid,0)!=0
and rn.patientid=p.keyid
and p.num not in (51375,42994,39766)---врач не принимает, собрания
and dd.keyid not in (SELECT attr.linkid
          FROM solution_med.attr
               
         WHERE attr.rootid IN (SELECT keyid
                                 FROM attr
                                WHERE rootid = (SELECT keyid
                                                  FROM ATTR
                                                 WHERE TAG = 6
                                                   AND CODE = 516
                                                   AND ROOTID = 0)
                                  AND code in (1)))
and dd.salary_typ_id  in (select lu.keyid from lu where lu.tag=303 and lu.code=2)

--and dd.keyid=10553000--проверяем на тестовом

and rn.dat=( select min(r.dat) 
      from rnumb r 
      where r.docdepid=dd.keyid 
            and trunc(r.dat)=trunc(sysdate+1) 
            and nvl(r.patientid,0)!=0
            and nvl(r.visitid,0)!=0 )
and rn.keyid not in(select sm.link_keyid from send_message sm
                           where sm.link_keyid=rn.keyid
                                 and sm.sourcetable='RNUMB'))            

    loop       
      insert into send_message sm
      (sourcetable,link_keyid,text,status,phone,note,senderid)
      values
      ('RNUMB',
      rc.rnumb_id,
      rc.text,
      0,
      rc.phone,
      'клиент № '||rc.num||chr(10)||chr(13)||
      ' Врач: '||rc.doctor||chr(10)||chr(13)||
      ' Дата номерка: '||rc.time_v, 
      rc.senderid);
    end loop;
  commit;  
     
    
         
  end;
--процедура выгрузки сформированных смс в бд asterisk
procedure upload_and_update_sms
  as
  sms_status number;
  begin
--выгружаем новые смс    
    for rc in(
select 
sm.keyid
,sm.phone
,sm.text
,sm.senderid
from 
send_message sm
where
sm.status=0
and not exists
(select *
from "sms"@MEDCALL s
where s."send_message_id"=sm.keyid )
      )
      loop
        insert into "sms"@MEDCALL
        ("number","text","send_message_id","signature")
        values
        (rc.phone,rc.text,rc.keyid,rc.senderid);
      end loop;
commit;      
---ставим статус 1-передано в asterisk
update send_message sm
set
sm.status=1
where 
sm.status=0;
commit;
----обномим стутусы в send_message 
---выбираем все новые и переданные в asterisk, в ожидании, отправленные, но на которые не пришел отчет о доставке

for rc2 in(
  select 
sm.keyid
,sm.phone
,sm.text
,sm.status
from 
send_message sm
where
nvl(sm.status,0) in(0,1,2,7,3,8)
  )loop
        ---сделаем циклом на всякий случай получаем статус
        for sms_rc in(
          
          select 
            "status"
          from 
            "sms"@MEDCALL sms
          where 
            sms."send_message_id"=rc2.keyid
                   )
         loop
           case 
             when sms_rc."status"='QUEUED' then sms_status:=1;--стоит в очереди
             when sms_rc."status"='TRYING' then sms_status:=2;--пытается отправить
             when sms_rc."status"='SMSCSUBMIT' then sms_status:=3;--отправлено
             when sms_rc."status"='SMSCREJECT' then sms_status:=4;--недоставлено смс центр "послал" нас сразу
             when sms_rc."status"='SMSCDELVRD' then sms_status:=5;--доставлено пришел отчет из смс центра что доставил
             when sms_rc."status"='SMSCFAILED' then sms_status:=6;--не доставлено. смс центр пытался но не смог отправить    
             when sms_rc."status"='SMSCPENDNG' then sms_status:=7;---в ожидании
               
           else
                sms_status:=8;
          end case;
          
         end loop; 
         
--обновим статус         
update  send_message sms
set sms.status=nvl(sms_status,8)
where sms.keyid=rc2.keyid;  

  end loop;
  commit;
  end;



function get_phone_osn_kont(pat_id in number)
return varchar
as
tel varchar(15):=0; 
begin
  select
 nvl(fn_get_only_numbers(replace(p_rsr.fn_get_osn_contakt_phone(pat_id),'+7','8')),0)
 into tel
 from dual;
return tel;
 exception
    when others then
      return 0;
end;  

function get_phone_dop_kont(pat_id in number)
return varchar
as
tel varchar(15):=0; 
begin
  select
 nvl(fn_get_only_numbers(replace((SELECT DISTINCT t.text AS form_item_value
                         FROM SOLUTION_REG.FORM_RESULT_VALUE_PATCARD t, SOLUTION_REG.FORM_RESULT_PATCARD rp
                         WHERE t.form_result_id = rp.id
                         AND t.col_num IS NULL AND t.row_num IS NULL
                         AND t.form_item_id  = 10000
                         AND rp.patient_id = pat_id AND ROWNUM=1),'+7','8')),0)
 into tel
 from dual;
return tel;
 exception
    when others then
      return 0;
end;  
procedure set_call_status_visit
  as
  begin
  -- Test statements here
  for rc in
    (
    select
v.keyid as v_keyid,
--fn_pat_name_by_id( v.patientid)||' '||p.num r_p_fio,
--v.dat,
--a."datetotell",
--a."calltime",
a.result as call_status
from
autodialout a,
visit v
--patient p
where 
a.visit_id=v.keyid(+)
and nvl(a.visit_id,0)!=0
and a.visit_id!=2147483647
and a.result!=96
--and v.patientid=p.keyid
and trunc(a.datetotell)=trunc(sysdate+1)
    )
    loop
      update 
      visit v
      set
      v.call_status=rc.call_status
      where 
      v.keyid=rc.v_keyid;
    end loop;
    commit;
end;

/*----------------------------------------------------------------
процедура, которая формирует смс клиентов, у которых в CRM  стоит анализы длябассейна, 
берется записи, которых дата фактическая истекает через 2 недели
------------------------------------------------------------------*/
   procedure upload_crm_row
as

begin
for rc1 in (
  select
p.num,
fn_pat_name_by_id(p.keyid) as fio,
decode(nvl(pkg_unique_aterisk.get_phone_osn_kont(p.keyid),0),0,p.cellular,pkg_unique_aterisk.get_phone_osn_kont(p.keyid)) as tel,
'CRM' as source_table,
'Уважаемый клиент, '|| to_char(trunc(c.plan_dat),'dd.mm.yyyy')||' истекает срок действия ваших анализов. Аквадоктор'  as send_text,
c.plan_dat,
c.keyid,
'0006122' as senderid --всегда Аквадоктор
from
patient p,
crm c,
lu l
where
c.patientid=p.keyid
and c.luid=l.keyid
and l.code=16
and trunc(c.plan_dat)=trunc(sysdate+14)
-----
--and p.num in (95126,27262)--тестовые 
-----
  )
  loop
  insert into send_message
   (sourcetable,link_keyid,text,status,phone,note,senderid)
   values
   (
   'CRM'
   ,rc1.keyid
   ,rc1.send_text
   ,0
   ,rc1.tel
   ,'отправлено клиенту № '||rc1.num||' на номер '||rc1.tel
   ,rc1.senderid);
 end loop;
commit;

  end upload_crm_row;
  
end PKG_UNIQUE_Aterisk;
/