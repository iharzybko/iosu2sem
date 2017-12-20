-----------1(инф_брест)-------------

create or replace view inf_brest as
	select * from branch
	where city='Брест'; 


-----------1(мин_стоим)-------------

create or replace view min_stoim as
	select *
	from objects
	where rent in(select min(rent) from objects);
	
-----------1(осм_с_комм)-------------

create or replace view watch_comm as
	select count(comment_0) COUNT_COMMENT
	from viewing;

-----------1(жел_аренд_3)------------

create or replace view inf_rent as
	select distinct r.lname, r.fname, r.tel_no
    from renter r
	join viewing v on v.rno=r.rno
	join property_for_rent o on o.pno=v.pno 
	where o.rooms = 3
	and o.city = substr(r.address,1,instr(r.address,',')-1);

-----------1(максимальное_кол-во_сотрудников)-----------

create or replace view max_count as
	select *
	from branch
	where  bno in (
		select bno
		from staff
		group by bno
		having count(*)>=all(select count(*) from staff group by bno)
		);


---------1(аренда_текущий_квартал)--------------------

/*поправить*/
create or replace view current_q as
	select owner.fname, owner.lname, ob.street,ob.city, ob.type, ob.rooms, ob.rent
	from objects ob
	join owner on owner.ono = ob.ono
	join viewing v on v.pno = ob.pno
		where to_char(date_o,'q') in
			(
				select to_char(sysdate, 'q')from dual
			);
 

--------1(осмотр>2)---------------


create or replace view visit_over as
	select *
	from owner
	where ono in(
		select distinct ono 
		from objects
		where pno in(
			select pno
			from viewing
			group by pno
			having count(*)>2
		)
	);	