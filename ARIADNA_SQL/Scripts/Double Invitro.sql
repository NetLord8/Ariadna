/*–езультаты повтор€ющихс€ нализов от »нвитро, повтор€ющиес€ по счетам test2*/
(select to_date(to_char(PE.DAT,'dd/mm/yyyy'),'dd/mm/yyyy'),pa.num,PA.LASTNAME,se.text,count(*)
from bill_ext be, invoice_ext ie, patserv pe ,srvdep se,patient pa
where ie.billid = be.keyid and be.company_ext_id=39001 and PE.KEYID=IE.PATSERVID and PE.SRVDEPID=SE.KEYID
and PA.KEYID=PE.PATIENTID
group by to_char(PE.DAT,'dd/mm/yyyy'),pa.num,PA.LASTNAME,se.text
having count(*)>1)
minus
(select to_date(to_char(PE.DAT,'dd/mm/yyyy'),'dd/mm/yyyy'),pa.num,PA.LASTNAME,se.text,count(*)
from bill_ext be, invoice_ext ie, patserv pe ,srvdep se,patient pa
where ie.billid = be.keyid and be.company_ext_id=39001 and PE.KEYID=IE.PATSERVID and PE.SRVDEPID=SE.KEYID
and PA.KEYID=PE.PATIENTID
group by to_char(PE.DAT,'dd/mm/yyyy'),pa.num,PA.LASTNAME,se.text,be.code,be.dat
having count(*)>1)
/*order by to_date(to_char(PE.DAT,'dd/mm/yyyy'),'dd/mm/yyyy')*/
