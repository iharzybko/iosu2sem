/*5.1. Написать DML триггер, регистрирующий изменение данных (вставку, обновление, удаление)
в одной из таблиц БД. Во вспомогательную таблицу LOG1 записывать кто, когда (дата и время)
и какое именно изменение произвел, для одного из столбцов сохранять старые и новые значения.*/

create table log1 (
  id number(5) primary key,
  username varchar2(20),
  dateoper date default sysdate,
  change_type char(1) check (change_type in ('I', 'U', 'D')),
  table_name varchar(20),
  column_name varchar2(20),
  old_value varchar2(200),
  new_value varchar2(200)
);

create sequence log1_sequence;

create or replace trigger create_log1_id
before insert on log1
for each row
begin
  select log1_sequence.nextval
  into :new.id
  from dual;
end;
/

create or replace trigger register_changes
after insert or update or delete
on equipment
for each row
declare
  change_type log1.change_type%type;
  old_value log1.old_value%type;
  new_value log1.new_value%type;
begin
  case
    when inserting
      then change_type := 'I';
    when updating
      then change_type := 'U';
    when deleting
      then change_type := 'D';
  else
    null;
  end case;

  old_value := :old.quantity;
  new_value := :new.quantity;

  insert into log1 (username, dateoper, change_type, table_name, column_name, old_value, new_value)
  values(user, sysdate, change_type, 'equipment', 'quantity', old_value, new_value);
end;
/


/*5.2. Написать DDL триггер, протоколирующий действия пользователей по созданию,
изменению и удалению таблиц в схеме во вспомогательную таблицу LOG2 в определенное время
и запрещающий эти действия в другое время.*/

create table log2 (
  id number(5) primary key,
  change_type char(1) check(change_type in ('C', 'A', 'D')),
  dateoper date default sysdate
);

create sequence log2_sequence;

create or replace trigger create_log2_id
before insert on log2
for each row
begin
  select log2_sequence.nextval
  into :new.id
  from dual;
end;
/

create or replace trigger register_changes2
before create or alter or drop on database
declare
  change_type log2.change_type%type;
begin
  if to_char(sysdate, 'hh24') between 0 and 24
  then
    case ora_sysevent
      when 'CREATE'
        then change_type := 'C';
      when 'ALTER'
        then change_type := 'A';
      when 'DROP'
        then change_type := 'D';
      else
        null;
      end case;
    insert into log2 (change_type) values (change_type);
  else
    raise_application_error(-20000, 'Database can''t be changed at this time');
  end if;
end;
/


/*5.3. Написать системный триггер добавляющий запись во вспомогательную таблицу LOG3,
когда пользователь подключается или отключается. В таблицу логов записывается имя пользователя (USER),
тип активности (LOGON или LOGOFF), дата (SYSDATE), количество записей в основной таблице БД.*/

create table log3 (
  id number(5) primary key,
  username varchar2(10),
  change_type varchar2(6) check(change_type in ('LOGON', 'LOGOFF')),
  datelog date default sysdate,
  timelog varchar2(10) default to_char(sysdate, 'hh24:mi:ss'),
  records_count number
);

create sequence log3_sequence;

create or replace trigger create_log3_id
before insert on log3
for each row
begin
  select log3_sequence.nextval
  into :new.id
  from dual;
end;
/

create or replace trigger system_logoff_trigger
before logoff on database
when (user != 'SYS')
declare
  v_records_count number;
begin
  select count(*) into v_records_count from tk;
  insert into log3 (username, change_type, records_count)
  values (user, ora_sysevent, v_records_count);
end;
/

create or replace trigger system_logon_trigger
after logon on database
when (user != 'SYS')
declare
  v_records_count number;
begin
  select count(*) into v_records_count from tk;
  insert into log3 (username, change_type, records_count)
  values (user, ora_sysevent, v_records_count);
end;
/

/*5.4.1 Отслеживать наличие руководителя и количество человек в бригаде, так, 
чтобы оно было не меньше заданного в триггере минимального значения и не превышало заданный максимум.*/

create or replace trigger max_people 
  before insert or update on brigades
  for each row
declare
  max_p brigades.numb_of%type := 15;
  min_p brigades.numb_of%type := 5;
  br exception;
  max_br exception;
  min_br exception;
  br_and_max exception;

begin
  if :new.brig_surname is null and :new.brig_name is null and :new.numb_of > max.p  then
    raise br_and_max;
  elsif :new.brig_surname is null and :new.brig_name is null then
    raise br;
  elsif :new.numb_of > max_p then 
    raise max_br;
  elsif :new.numb_of < min_p then
    raise min_br;
  end if;
  
  exception
    when br then raise_application_error(-20001, 'В бригаде должен быть бригадир!');
    when max_br then raise_application_error(-20001, 'В бригаде не может быть более 15 человек!');
    when min_br then raise_application_error(-20001, 'В бригаде должно быть не менее 5 человек!')
    when br_and_max then raise_application_error(-20001, 'В бригаде должен быть бригадир и количество человек не должно превышать 15 человек!');
end max_people;
/


insert into brigades values (12, null, 'Петров', 16);
insert into brigades values (13, 'Зыбко', 'Игорь', 16);
update brigades set brig_surname = null where bno = 4;


/*5.4.2 На одной единице оборудования в день не должно производиться больше 
технологических процессов, чем это установлено в таблице с описанием оборудования.*/

create or replace trigger tr_date
before insert on tech_card
for each row
declare
  v_amount_of_used_tk_today number(5);
  v_equipment_row equipment%rowtype;
  no_free_facilities exception;
begin
  select count(*) into v_amount_of_used_tk_today 
  from tk
  where eno = :new.eno and to_char(date_card, 'YYYY.MM.DD') = to_char(sysdate, 'YYYY.MM.DD');

  select * into v_equipment_row
  from equipment
  where eno = :new.eno;

  if v_amount_of_used_tk_today >= v_equipment_row.quantity then
    if v_amount_of_used_tk_today >= v_equipment_row.quantity * v_equipment_row.using_times then
      raise no_free_facilities;
    elsif v_equipment_row.is_free_facilities_exist = 'n' then
      raise no_free_facilities;
    end if;
  end if;

  exception
    when no_free_facilities then
    raise_application_error(-20001, 'There is no free facilities'); 
end;
/

insert into tk (tno, date_card, eno, pno, bno, lno)
values (27, sysdate, 6, 2, 2, 25);

--5.4.3 Обновлять максимальное и минимальное количество партий деталей, обработанных в день (месяц).

create table lots_today (
    min_lots number(10),
    max_lots number(10));
  
  
create or replace procedure min_max
  is
  v_amount number(5);
  first_day char(1);
  v_lots_today lots_today%rowtype;

begin
  
  select distinct count(*) into v_amount
  from lots l, tech_card t 
  where l.lno=t.lno and to_char(t.date_card, 'DD.MM.YYYY') = to_char(sysdate, 'DD.MM.YYYY'); 

  begin
    select * into v_lots_today
    from lots_today;
    exception
      when no_data_found then 
      first_day := 'y';
  end;
  
  if first_day = 'y' then 
    insert into lots_today values(v_amount, v_amount);
  end if;

  select * into v_lots_today
  from lots_today;

  if v_amount < v_lots_today.min_lots then
    insert into lots_today (min_lots) values (v_amount);
  elsif v_amount > v_lots_today.max_lots then
    insert into lots_today (max_lots) values (v_amount);
  end if;   
end;
/
  
  
begin
  dbms_scheduler.create_job(
    job_name => 'system.daily_job',
    job_type => 'plsql_block',
    job_action => 'begin system.min_max(); end;',
    start_date => sysdate,
    repeat_interval => 'freq=daily',
    enabled => true
  );
end;
/

begin
dbms_scheduler.run_job(job_name => 'system.daily_job');
end;
/

/*5.5  *Самостоятельно или при консультации преподавателя составить задание на триггер,
который будет вызывать мутацию таблиц, и решить эту проблему двумя способами:
1) при помощи переменных пакета и двух триггеров;
2) при помощи COMPAUND триггера.*/


create or replace trigger tr_mut
  after insert on tech_card
  for each row

begin
  if :new.eno = 1 and :new.pno !=3 then
    update tech_card set pno = 3 where tno =: new.tno;
  elsif :new.eno = 2 and :new.pno !=1 then
    update tech_card set pno = 1 where tno =: new.tno;
  elsif :new.eno = 3 and :new.pno !=2 then
    update tech_card set pno = 2 where tno =: new.tno;
  elsif :new.eno = 4 and :new.pno !=4 then
    update tech_card set pno = 4 where tno =: new.tno;
  end if;
    
end tr_mut;

insert into tk values (12, '26.12.2017', 3, 2, 2, 23);

--1) при помощи переменных пакета и двух триггеров;
create or replace package pack_mut
is
  bool boolean;
  id_proc tech_card.pno%type;
  id_tk tech_card.tno%type;
  procedure upd_proc;
end pack_mut;
/

create or replace package body pack_mut
is
  procedure upd_proc is
    begin
      if bool then
      bool := false;
      update tech_card set pno = id_proc where tno = id_tk;
      end if;
    end upd_proc;
end pack_mut;
/

create or replace trigger tr_mut_1
  before insert on tech_card
  for each row
begin
  if :new.eno = 1 and :new.pno != 3 then
    pack_mut.id_proc := 3;
    pack_mut.id_tk :=:new.tno;
    pack_mut.bool := true;
  elsif :new.eno = 2 and :new.pno != 1 then
    pack_mut.id_proc := 1;
    pack_mut.id_tk :=:new.tno;
    pack_mut.bool := true;
  elsif :new.eno = 3 and :new.pno != 2 then
    pack_mut.id_proc := 2;
    pack_mut.id_tk :=:new.tno;
    pack_mut.bool := true;
  elsif :new.eno = 4 and :new.pno != 4 then
    pack_mut.id_proc := 4;
    pack_mut.id_tk :=:new.tno;
    pack_mut.bool := true;
  end if;

end tr_mut_1;
/

create or replace trigger tr_mut_2
  after insert on tech_card

begin
  pack_mut.upd_proc;
end tr_mut_1;
/

alter trigger tr_mut disable;
alter trigger tr_mut_2 disable;
insert into tech_card values (14, '28.12.2017', 4, 3, 2, 23);

--2) при помощи COMPAUND триггера.

create or replace trigger tr_mut_compound
for insert on tech_card
  COMPOUND TRIGGER
    bool boolean;
  id_proc tech_card.pno%type;
  id_tk tech_card.tno%type;
    
  before each row is

  begin
  if :new.eno = 1 and :new.pno != 3 then
    pack_mut.id_proc := 3;
    pack_mut.id_tk :=:new.tno;
    pack_mut.bool := true;
  elsif :new.eno = 2 and :new.pno != 1 then
    pack_mut.id_proc := 1;
    pack_mut.id_tk :=:new.tno;
    pack_mut.bool := true;
  elsif :new.eno = 3 and :new.pno != 2 then
    pack_mut.id_proc := 2;
    pack_mut.id_tk :=:new.tno;
    pack_mut.bool := true;
  elsif :new.eno = 4 and :new.pno != 4 then
    pack_mut.id_proc := 4;
    pack_mut.id_tk :=:new.tno;
    pack_mut.bool := true;
  end if;
  end before each row;

  after statement is

    begin
      if bool then
        bool := false;
        update tech_card set pno = id_proc where tno = id_tk;
      end if;
    end after statement;
end tr_mut_compound;
/

/*5.6. *Написать триггер INSTEAD OF для работы с необновляемым представлением.
Изменение материала деталей*/

create or replace view details_material as
select name, diameter, height, material from details d
join lots l on l.dno=d.dno
where numb_of < 1400;

update details_material
set material = 'Cталь'
where name = 'Гайка';

create or replace trigger update_dm
instead of update on details_material
for each row
begin
  update details
  set material = :new.material
  where name = :old.name;
end;
/