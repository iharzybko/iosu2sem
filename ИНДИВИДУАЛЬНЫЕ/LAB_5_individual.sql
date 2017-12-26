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


/*5.6. *Написать триггер INSTEAD OF для работы с необновляемым представлением.
Изменение материала деталей*/

create or replace view details_material as
select name, diameter, height, material from details d
join lots l on l.dno=d.dno
where numb_of < 1400;

update details_material
set material = 'Железо'
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