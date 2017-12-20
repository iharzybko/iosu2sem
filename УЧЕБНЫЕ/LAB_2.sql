------------1----------

select fname ||' '|| tel_no as FT
from staff
where position in('Manager');

------------2----------
	
select distinct fname, lname, address, tel_no
from owner,objects
where rooms='3' and objects.ono=owner.ono;

------------3----------

select bno||' '||count(sno) as AMOUNT_OF_COWORKERS
from staff
group by bno;

------------4----------
			
select t1.bno, city, street, tel_no, staff_number, renter_number from (
select b.bno, count(r.rno) renter_number from branch b
join renter r on b.bno = r.bno
group by b.bno
having count(r.rno) > 1
) t1
join (
select b.bno, count(s.sno) staff_number from branch b
join staff s on b.bno = s.bno
group by b.bno
having count(s.sno) > 1
) t2 on t1.bno = t2.bno
join branch b on t1.bno = b.bno;
