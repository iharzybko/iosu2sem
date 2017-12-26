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
	v_name equipment.name%type;
	v_found char(1) := 'y';
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

 begin
  open str;
  open kol;
  fetch str into tabl;
  if str%notfound then raise wrong_kind;
  end if;

  while str%found
  loop 

	  begin
	  	select name into v_name from equipment2
	  	where name = tabl.name and mark = tabl.mark;

	  	exception
	  		when no_data_found then
	  		v_found := 'n'; 
	  end; 

	  if v_found = 'n' then
			fetch kol into amount_det;	
			insert into equipment2 values (equipment_seq.nextval, tabl.name,tabl.mark,tabl.manuf_country,tabl.quantity,tabl.price,amount_det);
		end if;

		fetch str into tabl;
		fetch kol into amount_det;
  end loop;
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

SET SERVEROUTPUT ON
declare
  count_brig number := 0;
  begin
    MY_package.equip('Станок сверлильный');
    MY_package.equip('Станок олег');

	count_brig := MY_package.amount_workers(3);
	dbms_output.put_line('Количество человек в бригаде: '||count_brig);
end;
/


/*предустановленные ошибки и локальная программа*/

-- Создание локальной перегруженной программы:

declare
	count_brig number := 0;

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


function amount_workers(fname in varchar2) 
return number
is
result number;
	wrong_id exception;
	cursor brig is
	select numb_of from brigades where brig_surname=fname;
begin 
	open brig;
	fetch brig into result;
	if brig%notfound then
		raise wrong_id;
	else
		if result <= 8 then 
			update brigades set numb_of = 10 where brig_surname=fname;
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

begin
  count_brig := amount_workers(2);
	dbms_output.put_line('Количество человек в бригаде: '||count_brig);
	count_brig := amount_workers('Нечай');
	dbms_output.put_line('Количество человек в бригаде: '||count_brig);
end;
/

