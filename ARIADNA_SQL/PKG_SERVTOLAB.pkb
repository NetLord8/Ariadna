CREATE OR REPLACE PACKAGE BODY SOLUTION_MED.pkg_servtolab IS

  procedure checkserv(p_patserv IN NUMBER
                     ,p_srvdep  IN NUMBER
                     ,rc1       IN OUT pkg_global.ref_cursor_type) as
  
    emp_cv      pkg_global.ref_cursor_type;
    patserv_rec patserv%rowtype;
    srvdep_rec  srvdep%rowtype;
  
  begin
    if nvl(p_patserv, 0) <> 0 then
      OPEN emp_cv FOR 'SELECT * FROM solution_med.patserv WHERE keyid = ' || p_patserv;
      FETCH emp_cv
        INTO patserv_rec;
    
      OPEN emp_cv FOR 'SELECT * FROM solution_med.srvdep WHERE keyid = ' || patserv_rec.srvdepid;
      FETCH emp_cv
        INTO srvdep_rec;
    else
      OPEN emp_cv FOR 'SELECT * FROM solution_med.srvdep WHERE keyid = ' || p_srvdep;
      FETCH emp_cv
        INTO srvdep_rec;
    end if;
  
    open rc1 for
      select pkg_global.err_no as error_code
            ,'Исправьте что-нибудь в услуге:' || chr(13) || chr(10) ||
             srvdep_rec.code || ' - ' || srvdep_rec.text as error_text
        from dual;
  end;

  procedure materialsforServ(p_patserv            IN NUMBER
                            ,p_srvdep             IN NUMBER
                            ,p_is_research_create IN NUMBER
                            ,rc1                  IN OUT pkg_global.ref_cursor_type) as
  
    emp_cv      pkg_global.ref_cursor_type;
    patserv_rec patserv%rowtype;
    srvdep_rec  srvdep%rowtype;
  
  begin
  
    if nvl(p_patserv, 0) <> 0 then
      OPEN emp_cv FOR 'SELECT * FROM solution_med.patserv WHERE keyid = ' || p_patserv;
      FETCH emp_cv
        INTO patserv_rec;
    
      OPEN emp_cv FOR 'SELECT * FROM solution_med.srvdep WHERE keyid = ' || patserv_rec.srvdepid;
      FETCH emp_cv
        INTO srvdep_rec;
    else
      OPEN emp_cv FOR 'SELECT * FROM solution_med.srvdep WHERE keyid = ' || p_srvdep;
      FETCH emp_cv
        INTO srvdep_rec;
    end if;
  
    if nvl(patserv_rec.material_id, 0) <> 0
       and nvl(p_is_research_create, 0) <> 0 then--при создании лаб.направления использовать метриал из patserv.material_id
      open rc1 for
        SELECT sm.id as id
              ,l.text as material
              ,fn_get_dep_name(srvdep_rec.depid) as dep
              ,l.id as mat_lu_id
          from solution_med.patserv     ps
              ,solution_lab.lu          l
              ,solution_lab.srvmaterial sm
         where ps.material_id = l.id
           and ps.keyid = p_patserv
           and sm.material_id = l.id
           and ps.srvdepid = sm.service_id
         ORDER BY material;
    else
/*      open rc1 for
        SELECT DISTINCT sm.id AS id
                       ,l.text AS material
                       ,fn_get_dep_name(sd.depid) AS dep
                       ,l.id AS mat_lu_id
          FROM solution_med.srvdep      sd
              ,solution_lab.srvmaterial sm
              ,solution_lab.lu          l
              ,solution_lab.workflow    wf
         WHERE sd.keyid = sm.service_id
           AND wf.service_id = sm.service_id
           AND wf.status = 1
           AND sd.status = '1'
           AND sm.material_id = l.id
           AND sd.keyid = srvdep_rec.keyid
         ORDER BY material;*/
         
--------------------------тестовый кусок------------------------------------------------         
        open rc1 for
       select distinct s.id as id
                       ,s.text as material 
                       ,fn_get_dep_name_by_srvdep(l.serv_id) as dep
                       ,s.id as mat_lu_id        
         from solution_lab.lu l
            , solution_lab.lu_lu ll
            , solution_lab.lu s
        where l.serv_id = p_srvdep--1984
          and l.status = 1
          and ll.lu_to_id = l.id
          and s.id = ll.lu_from_id
          and s.tag = 1
          and s.status = 1
        order by material;
        /*select distinct l.id as id
                       ,(select text from solution_lab.lu where id = r.specimen_id) as material 
                       ,fn_get_dep_name_by_srvdep(l.serv_id) as dep
                       ,r.specimen_id as mat_lu_id        
         from solution_lab.order_info oi, solution_lab.lu l, solution_lab.research r
        where oi.patserv_id = p_patserv
          and oi.research_id = r.root_id
          and l.id = oi.service_id
        ORDER BY material;*/
---------------------------------------------------------------------------------------- 
    end if;
  
  end;

  procedure materialsforServCount(p_patserv            IN NUMBER
                                 ,p_srvdep             IN NUMBER
                                 ,p_is_research_create IN NUMBER
                                 ,rc1                  IN OUT pkg_global.ref_cursor_type) as
    rowcnt       number := 0;
    material_rec materialsforServ_ref;
    error_code   number;
    error_text   varchar2(300);
    emp_cv       pkg_global.ref_cursor_type;
    patserv_rec  patserv%rowtype;
    srvdep_rec   srvdep%rowtype;
    materialid   number;
    mat_lu_id    number;
    material     varchar2(300);
  
  begin
  
    materialid := 0;
    material   := '';
    mat_lu_id  := 0;
  
    if nvl(p_patserv, 0) <> 0 then
      OPEN emp_cv FOR 'SELECT * FROM solution_med.patserv WHERE keyid = ' || p_patserv;
      FETCH emp_cv
        INTO patserv_rec;
    
      OPEN emp_cv FOR 'SELECT * FROM solution_med.srvdep WHERE keyid = ' || patserv_rec.srvdepid;
      FETCH emp_cv
        INTO srvdep_rec;
    else
      OPEN emp_cv FOR 'SELECT * FROM solution_med.srvdep WHERE keyid = ' || p_srvdep;
      FETCH emp_cv
        INTO srvdep_rec;
    end if;
  
    --вызываем запрос для списка но нам от него нужно только количество
    materialsforServ(p_patserv, p_srvdep, p_is_research_create, rc1);
  
    LOOP
      --если есть вариант лучше чтобы узнать количество строк в курсоре исправьте
      fetch rc1
        into material_rec;
      rowcnt := rc1%rowcount;
      EXIT WHEN rc1%ROWCOUNT > 1 OR rc1%NOTFOUND;
    END LOOP;
  
    if rowcnt = 0 then
      error_code := pkg_global.err_crit;
      error_text := 'Услуге:' || chr(13) || chr(10) || srvdep_rec.code || ' - ' ||
                    srvdep_rec.text || 'не соответствует ни один материал';
    elsif rowcnt = 1 THEN
      error_code := pkg_global.err_no;
      error_text := '';
      materialid := material_rec.keyid;
      material   := material_rec.material;
      mat_lu_id  := material_rec.material_lu_id;
    elsif rowcnt = 2 THEN
      error_code := pkg_global.err_no;
      error_text := 'Данной услуге не соответствует ни один материал';
    Else
      error_code := pkg_global.err_crit;
      error_text := 'Непредвиденная ошибка';
    end if;
  
    open rc1 for
      select error_code as error_code
            ,error_text as error_text
            ,materialid as materialid
            ,material   as material
            ,mat_lu_id  as mat_lu_id
        from dual;
  end;

  procedure CreateLabResearch(patientid         in number
                             ,PATSERVMATERARRAY in varchar2
                             ,rc1               IN OUT pkg_global.ref_cursor_type) as
    fetch_vsp           number;
    sqltest             varchar2(4000);
    patservid           number := 0;
    materialid          number := 0;
    researchid          number := 0;
    rec                 patserv_servmat_ref;
    material_row        solution_lab.lu%rowtype;
    servmat_row         solution_lab.srvmaterial%rowtype;
    patserv_row         solution_med.patserv%rowtype;
    patient_row         solution_med.patient%rowtype;
    research_first_row  solution_lab.research%rowtype;
    research_second_row solution_lab.research%rowtype;
  
    order_info_first_id  number;
    order_info_second_id number;
    p_rc2                pkg_global.ref_cursor_type;
    
    p_service_id        number;
  begin
  
    select *
      into patient_row
      from solution_med.patient
     where keyid = patientid;
    --создадим лаб исследование (первого уровня)
    researchid := pkg_global.get_next_id('solution_lab', 'research');
    insert into solution_lab.research
      (id
      ,patient_id
      ,agr_id
      ,status
      ,regdate
      ,orderdate
      ,orderid)
    values
      (researchid
      ,patientid
      ,patient_row.agrid
      ,5
      ,sysdate
      ,sysdate
      ,researchid);
  
    commit;
  
    select *
      into research_first_row
      from solution_lab.research
     where id = researchid;
  
    --из прикрепим наши услуги к исследованию через создание orderid
    sqltest := 'select * from ( 
                  select to_number(listagg(decode(mod(rownum, 2), 1, text, null), '', '') within group(order by text)) as patservid
                        ,to_number(listagg(decode(mod(rownum, 2), 0, text, null), '', '') within group(order by text)) as servmaterialid
                    from (select (column_value).getnumberval() as text from xmltable(''' ||
               PATSERVMATERARRAY ||
               '''))
                   group by ceil(rownum/2)) t order by t.servmaterialid';
  
    open rc1 for sqltest;
    loop
    
      fetch rc1
        into rec;
    
      EXIT WHEN rc1%NOTFOUND;
      --чтобы на последней итерации дважды не получить последнюю пару (курсор становится NOTFOUND не тогда когда вытащили посл. значения., а когда попытались 
      --вытащить те которых нет
      rec := rec;
    
      /*select *
        into servmat_row
        from solution_lab.srvmaterial
       where id = rec.servmaterialid;*/
      select *
        into material_row 
        from solution_lab.lu
       where id = rec.servmaterialid;
      select *
        into patserv_row
        from solution_med.patserv
       where keyid = rec.patservid;
      
      begin
        select id
          into p_service_id
          from solution_lab.lu
         where tag = 3
           and status = 1
           and serv_id = patserv_row.srvdepid;
      exception
        when no_data_found then
          p_service_id := null;
      end;
    
      --создаеём заказ первого уровня
      order_info_first_id := pkg_global.get_next_id('solution_lab', 'order_info');
      insert into solution_lab.order_info
        (id
        ,RESEARCH_ID
        ,CITO
        ,AGR_ID
        ,SERVICE_ID
        ,SRVDEP_ID
        ,SRVMATERIAL_ID
        ,patserv_id)
      values
        (order_info_first_id
        ,research_first_row.id
        ,research_first_row.cito_status
        ,research_first_row.agr_id
        ,p_service_id
        ,patserv_row.srvdepid
        ,servmat_row.material_id
        ,patserv_row.keyid);
    
      --создаеём исследование второго уровня
      p_lab_research.create_material_dep_research4(research_first_row.id,
                                                   /*servmat_row.material_id*/material_row.id, null,
                                                   '', null, patserv_row.srvdepid,
                                                   p_rc2);
      fetch p_rc2
        into fetch_vsp;
      select *
        into research_second_row
        from solution_lab.research
       where id = fetch_vsp;
    
      --создаеём заказ второго уровня
      order_info_second_id := pkg_global.get_next_id('solution_lab', 'order_info');
      insert into solution_lab.order_info
        (id
        ,research_id
        ,cito
        ,agr_id
        ,service_id
        ,srvdep_id
        ,srvmaterial_id
        ,root_id
        ,patserv_id)
      values
        (order_info_second_id
        ,research_second_row.id
        ,research_first_row.cito_status
        ,research_first_row.agr_id
        ,p_service_id
        ,patserv_row.srvdepid
        ,servmat_row.material_id
        ,order_info_first_id
        ,patserv_row.keyid);
    
      commit;
    
    end loop;
  
    open rc1 for
      select pkg_global.err_no as error_code
            ,PATSERVMATERARRAY as error_text
            ,researchid        as Labresearchid
        from dual;
  end;
END;
/