/*Задание к лабораторной работе: 

1. Создать процедуру.

2. Создать функцию.

При создании следует выполнить следующие минимальные требования к синтаксису:
-    использовать явный курсор или курсорную переменную, а также атрибуты курсора;
-    использовать пакет DBMS_OUTPUT для вывода результатов работы в SQLPlus;
-    предусмотреть секцию обработки исключительных ситуаций;

Создать процедуру, которая копирует строки с информацией об оборудовании указанного вида
во вспомогательную таблицу и подсчитывает количество деталей на нем произведенного.

Создайте функцию, возвращающую количество рабочих в бригаде. Входной параметр функции – id бригады.
Если в бригаде менее 8 человек, то обновить количество до 10 человек.

3. Объединить все процедуры и функции в пакет.

4. Написать анонимный PL/SQL блок, в котором будут вызовы реализованных функций и процедур пакета
с различными характерными значениями параметров для проверки правильности
работы основных задач и обработки исключительных ситуаций.

5. Написать локальную программу.

6. Написать перегруженную программу.*/


-- Последовательность, созданная для работы с вспомогательной таблицей.
create sequence equipment_seq start with 1 increment by 1 nomaxvalue;


/*Создание пакета, процедуры и функции.*/

create or replace package MY_package is
procedure equip(kind in varchar2);
function amount_workers(id_brig in number) return number ;
end MY_package;
/

create or replace package body MY_package is

	procedure equip(kind in varchar2) is 
	wrong_kind exception;
	amount_det lots.numb_of%type;
	cursor str is
		select * from equipment 
		where name = kind; 
	tabl str%rowtype;

	cursor kol is
		select sum(numb_of) from lots join tk on lots.lno=tk.lno 
		where tk.tno in (select tno from tk join equipment on tk.eno=equipment.eno 
		where equipment.name = 'Станок сверлильный')
		group by tk.eno;
	cursor del is
	select * from equipment2;	
	
	del1 del%rowtype;
 begin
  open str;
  open kol;
  open del;
  fetch del into del1;
  if del%FOUND then 
  delete from equipment2;
  	end if;
  fetch str into tabl;
	if str%notfound then 
		raise wrong_kind;
	else 
	 fetch kol into amount_det;
		while str%found
			loop 
	insert into equipment2 values (equipment_seq.nextval, tabl.name,tabl.mark,tabl.manuf_country,tabl.quantity,tabl.price,amount_det);
	fetch str into tabl;
	fetch kol into amount_det;
			end loop;
	end if;
  close str;
  close kol;

  commit;
  
  exception 
  when wrong_kind then 
  dbms_output.put_line('Оборудования данного вида нет');
  when others then
    raise_application_error(-20002, 'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
end equip;

function amount_workers(id_brig in number) 
return number 
is 
result number;
	wrong_id exception;
	cursor brig is
	select numb_of from brigades where bno=id_brig;
	
	procedure edit_amount_brigades(id_edit in number) is
		begin 
		update brigades set numb_of=10 where bno=id_edit;
		end edit_amount_brigades;
begin 
	open brig;
	fetch brig into result;
	if brig%notfound then 
		raise wrong_id;
	else 
		if result <= 8 then 
			edit_amount_brigades(id_brig);
			result :=10;
			commit;
		end if;
	return result;
	end if;
	close brig;
	
	exception 
  when wrong_id then 
  dbms_output.put_line('Такой бригады нет');
  when others then
    raise_application_error(-20002, 'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
end amount_workers;

end MY_package;
/


--Создание анонимного блока:

declare
  count_brig number := 0;
begin
    MY_package.equip('Станок сверлильный');
    MY_package.equip('Станок руковыпрямительный');


    count_brig:=MY_package.amount_workers(2);
	dbms_output.put_line('Количество человек в бригаде: '||count_brig);
end;
/

-- Создание локальной программы:

/*function amount_workers(FIO_brig in varchar2) 
return number;
is
result number;
	wrong_id exception;
	cursor brig is
	select amount from brigades where brigadier=FIO_brig;
begin 
	open brig;
	fetch brig into result;
	if brig%notfound then
		raise wrong_id;
	else
		if result <= 8 then 
			update brigades set amount=10 where brigadier=FIO_brig;
			result := 10;
			commit;
		end if;
	return result;
	end if;
	close brig;
	
	exception 
  when wrong_id then 
  dbms_output.put_line('Такой бригады нет');
  when others then
    raise_application_error(-20002, 'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
end amount_workers;
/
*/

-- Создание перегруженной программы:








































--Вызов
SET SERVEROUTPUT ON
DECLARE
count_a NUMBER;
BEGIN
count_a:=MY_package.amount_workers(1);
dbms_output.put_line(count_a);
END;
 /
 ALTER TABLE brigades ADD amount NUMBER;
 update brigades set amount=8 WHERE bk=4;
SET SERVEROUTPUT ON
DECLARE
count_a NUMBER;
BEGIN
count_a:=MY_package.amount_workers('Бобров Виктор Михайлович');
dbms_output.put_line(count_a);
END;
 /

