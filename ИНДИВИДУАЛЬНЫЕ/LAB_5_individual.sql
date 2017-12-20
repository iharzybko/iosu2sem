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


-- Написать DDL триггер, протоколирующий действия пользователей по созданию,
-- изменению и удалению таблиц в схеме во вспомогательную таблицу LOG2 в определенное время
-- и запрещающий эти действия в другое время.

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


-- Написать системный триггер добавляющий запись во вспомогательную таблицу LOG3,
-- когда пользователь подключается или отключается. В таблицу логов записывается имя пользователя (USER),
-- тип активности (LOGON или LOGOFF), дата (SYSDATE), количество записей в основной таблице БД.

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


/*5.4. Написать триггеры, реализующие бизнес-логику (ограничения) в заданной предметной области.
Тип триггера: строковый или операторный,выполнятся AFTER или BEFORE определить самостоятельно, 
исходя из сути задания, третий пункт задания предполагает использование триггера с предложением WHEN.*/

/*a) Отслеживать наличие руководителя и количество человек в бригаде, так,
чтобы оно было меньше заданного в триггере минимального значения и не превышало заданный максимум.*/

create or replace trigger count_people
before insert or update on brigades
for each row
declare
  agreement_record agreement%rowtype;
  service_record service%rowtype;
  n_expiration_date agreement.expiration_date%type;
  n_total_cost agreement.total_cost%type;
  n_discount agreement.discount%type;
begin
  select * into service_record from service
  where service.id_service = :new.id_service;

  begin
    select * into agreement_record from agreement
    where agreement.id_agreement = :new.id_agreement;
    exception
    when no_data_found
    then agreement_record.id_agreement := null;
  end;

  if agreement_record.id_agreement is not null
  then
    if agreement_record.expiration_date >= sysdate + service_record.max_term
    then n_expiration_date := agreement_record.expiration_date;
    else n_expiration_date := sysdate + service_record.max_term;
    end if;
    n_discount := 5;
    n_total_cost := (100 - n_discount) / 100 * (agreement_record.total_cost + service_record.cost);
    update agreement
    set expiration_date = n_expiration_date,
        order_date = sysdate,
        discount = n_discount,
        total_cost = n_total_cost
    where id_agreement = :new.id_agreement;
  else
    n_expiration_date := sysdate + service_record.max_term;
    n_total_cost := service_record.cost;
    insert into agreement (id_agreement, expiration_date, order_date, total_cost)
    values (:new.id_agreement, n_expiration_date, sysdate, n_total_cost);
  end if;
end;
/

-- Рассчитывать общую сумму стоимости по договору, делая скидку клиентам
-- в зависимости от количества или общей суммы их заказов.

/*create or replace trigger total_cost
before insert or update on orders
for each row
declare
  agreement_record agreement%rowtype;
  service_record service%rowtype;
  n_expiration_date agreement.expiration_date%type;
  n_total_cost agreement.total_cost%type;
  n_discount agreement.discount%type;
begin
  select * into service_record from service
  where service.id_service = :new.id_service;

  begin
    select * into agreement_record from agreement
    where agreement.id_agreement = :new.id_agreement;
    exception
    when no_data_found
    then agreement_record.id_agreement := null;
  end;

  if agreement_record.id_agreement is not null
  then
    if agreement_record.expiration_date >= sysdate + service_record.max_term
    then n_expiration_date := agreement_record.expiration_date;
    else n_expiration_date := sysdate + service_record.max_term;
    end if;
    n_discount := 5;
    n_total_cost := (100 - n_discount) / 100 * (agreement_record.total_cost + service_record.cost);
    update agreement
    set expiration_date = n_expiration_date,
        order_date = sysdate,
        discount = n_discount,
        total_cost = n_total_cost
    where id_agreement = :new.id_agreement;
  else
    n_expiration_date := sysdate + service_record.max_term;
    n_total_cost := service_record.cost;
    insert into agreement (id_agreement, expiration_date, order_date, total_cost)
    values (:new.id_agreement, n_expiration_date, sysdate, n_total_cost);
  end if;
end;
/

---
insert into orders(id_agreement, id_service, id_material, material_amount, id_tool, tool_amount, id_employee, id_client)
values (1, 4, 1, 1, 1, 1, 3, 1);

insert into orders(id_agreement, id_service, id_material, material_amount, id_tool, tool_amount, id_employee, id_client)
values (1, 5, 1, 1, 1, 1, 3, 1);

insert into orders(id_agreement, id_service, id_material, material_amount, id_tool, tool_amount, id_employee, id_client)
values (2, 7, 1, 1, 1, 1, 3, 1);

-- error, service is already booked
insert into orders(id_agreement, id_service, id_material, material_amount, id_tool, tool_amount, id_employee, id_client)
values (2, 3, 1, 1, 1, 195, 3, 1);


-- Контролировать количество материала и продукции в наличии при заключении договора, не допускать
-- одновременного оказания одних и тех же услуг нескольким клиентам.

create or replace trigger check_mater_and_tools
before insert or update on orders
for each row
declare
  material_record material%rowtype;
  tool_record tool%rowtype;
  service_record service%rowtype;
begin
  select * into material_record from material
  where :new.id_material = material.id_material;

  select * into tool_record from tool
  where :new.id_tool = tool.id_tool;

  select * into service_record from service
  where :new.id_service = service.id_service;

  if :new.material_amount > material_record.amount or :new.tool_amount > tool_record.amount
  then raise_application_error(-20001, 'There is no so much material or tool, sorry');
  elsif service_record.completed = 'n'
  then raise_application_error(-20002, 'This service is already booked');
  else
    update material
    set amount = amount - :new.material_amount
    where id_material = :new.id_material;

    update tool
    set amount = amount - :new.tool_amount
    where id_tool = :new.id_tool;

    update service
    set completed = 'n'
    where id_service = :new.id_service;
  end if;
end;
/

---
insert into orders(id_agreement, id_service, id_material, material_amount, id_tool, tool_amount, id_employee, id_client)
values (1, 3, 1, 1, 1, 199, 3, 1);



-- Ежедневно вести учет договоров, по которым истечение сроков
-- исполнения произойдет менее чем через три дня.

create table registration (
  id_registration number(5) primary key,
  id_agreement references agreement,
  check_date date default sysdate
);

create sequence registration_seq;

create or replace trigger registration_id_trigger
before insert on registration
for each row
begin
  select registration_seq.nextval
  into :new.id_registration
  from dual;
end;
/

begin
  dbms_scheduler.create_job(
    job_name => 'system.daily_job',
    job_type => 'plsql_block',
    job_action => 'begin system.check_agreements(); end;',
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

begin
dbms_scheduler.drop_job('system.daily_job');
end;
/

create or replace procedure check_agreements is
begin
  for agreement_item in (select id_agreement, expiration_date from agreement)
  loop
    if agreement_item.expiration_date - sysdate <= 3
    then
      insert into registration (id_agreement) values(agreement_item.id_agreement);
    end if;
  end loop;
end;
/
*/

ААААААААААААААААААААААААААААААААААААААААА
ААААААААААААААААААААААААААААААААААААААААА
ААААААААААААААААААААААААААААААААААААААААА
ААААААААААААААААААААААААААААААААААААААААА
ААААААААААААААААААААААААААААААААААААААААА
ААААААААААААААААААААААААААААААААААААААААА


/*5.5. *Самостоятельно или при консультации преподавателя составить задание на триггер,
который будет вызывать мутацию таблиц, и решить эту проблему двумя способами:
1) при помощи переменных пакета и двух триггеров;
2) при помощи COMPAUND триггера.*/

update agreement
set discount = 3
where discount is null;


-- Первый способ:

create or replace package my_package1 is
  procedure set_max_discount(max_discount in agreement.discount%type);
  function get_max_discount return agreement.discount%type;
end my_package1;
/

create or replace package body my_package1 is
  vmax_discount agreement.discount%type;

  procedure set_max_discount(max_discount in agreement.discount%type) is
  begin
    select max(discount) into my_package1.vmax_discount from agreement;
  end set_max_discount;

  function get_max_discount return agreement.discount%type is
  begin
    return my_package1.vmax_discount;
  end get_max_discount;
end;
/

create or replace trigger agreement_discount1
before update on agreement
declare
  max_discount agreement.discount%type;
begin
  select max(discount) into max_discount from agreement;
  my_package1.set_max_discount(max_discount);
end;
/

create or replace trigger agreement_discount2
before update on agreement
for each row
begin
  if :new.discount > my_package1.get_max_discount() then
    raise_application_error(-20003, 'Discount mustn''t be less than the minimal discount');
  end if;
end;
/



-- Второй способ:

create or replace trigger agreement_discount
for update of discount on agreement
compound trigger
max_discount agreement.discount%type;

before statement is
begin
  select max(discount) into max_discount from agreement;
end before statement;

before each row is
begin
  if :new.discount > max_discount then
    raise_application_error(-20003, 'Discount mustn''t be less than the minimal discount');
  end if;
end before each row;
end;
/


-- create or replace trigger agreement_discount
-- before update on agreement
-- for each row
-- declare
--   max_discount agreement.discount%type;
-- begin
--   select max(discount) into max_discount from agreement;
--   if :new.discount > max_discount then
--   raise_application_error(-20003, 'Discount mustn''t be less than the minimal discount');
--   end if;
-- end;
-- /
*/


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