/*
Создать процедуру изменения стоимости услуги.
Входные параметры – id услуги и новая стоимость.
Вывести отчет о том какая именно услуга подорожала или подешевела и на сколько %.

Написать функцию, которая за указанный период определяет количество заключенных договоров.
В качестве параметра передать начальную и конечную даты периода.

При создании следует выполнить следующие минимальные требования к синтаксису:
-    использовать явный курсор или курсорную переменную, а также атрибуты курсора;
-    использовать пакет DBMS_OUTPUT для вывода результатов работы в SQLPlus;
-    предусмотреть секцию обработки исключительных ситуаций, причем обязательно использовать
     как предустановленные исключительные ситуации, так и собственные
    (например, стоит контролировать наличие в БД значений, передаваемых в процедуры и функции, как параметры);
*/

--  Объединить все процедуры и функции в пакет.
create or replace package my_package is
  procedure change_cost(id in number, new_cost in number);
  function agreements_number(start_date in date, end_date in date) return number;
end my_package;
/


create or replace package body my_package is
  -- procedure
  procedure change_cost
    (id in number, new_cost in number)
  is
    old_cost service.cost%type;
    service_name service.name%type;
    cost_ratio number;
    output_message varchar2(60);

    min_cost exception;
    pragma exception_init(min_cost, -02290);
  begin

    select cost, name
    into old_cost, service_name
    from service
    where id_service = id;

    if old_cost < new_cost then
      cost_ratio := round((new_cost - old_cost) / old_cost * 100);
      output_message := ' has risen in price by ' || cost_ratio || '%.';
    elsif old_cost > new_cost then
      cost_ratio := round((old_cost - new_cost) / old_cost * 100);
      output_message := ' has become cheaper by ' || cost_ratio || '%.';
    else output_message := ' price has remained the same.';
    end if;

    update service set cost = new_cost
    where id_service = id;

    commit;

    dbms_output.put_line(service_name || output_message);

  exception
    when no_data_found then
      dbms_output.put_line('There is no records with such id');
    when min_cost then
      dbms_output.put_line('Cost of service mustn''t be so cheap');
  end change_cost;

  -- function
  function agreements_number(start_date in date, end_date in date)
    return number
  is
    agr_number number := 0;
  begin
    for agr in (
      select id_agreement, order_date
      from agreement
    )
    loop
      if agr.order_date between start_date and end_date then
        agr_number := agr_number + 1;
      end if;
    end loop;

  return agr_number;

  exception
    when others then return 0;
  end agreements_number;

end my_package;
/


-- anonymous block
declare
  agr_count number := 0;
begin
  my_package.change_cost(7, 120); -- correct
  my_package.change_cost(1, 20); -- there's no record with such id
  my_package.change_cost(3, 19); -- cost is too low(constraint)

  select my_package.agreements_number(
    to_date('2017/09/01', 'yyyy/mm/dd'),
    to_date('2017/11/07', 'yyyy/mm/dd')
  ) as "Agreements number" into agr_count from dual;

  dbms_output.put_line('Number of agreements is ' || agr_count);

end;
/


-- local and overloaded programm
declare
    procedure change_cost
      (id in number, new_cost in number)
    is
      old_cost service.cost%type;
      service_name service.name%type;
      cost_ratio number;
      output_message varchar2(60);

      min_cost exception;
      pragma exception_init(min_cost, -02290);
    begin

      select cost, name
      into old_cost, service_name
      from service
      where id_service = id;

      if old_cost < new_cost then
        cost_ratio := round((new_cost - old_cost) / old_cost * 100);
        output_message := ' has risen in price by ' || cost_ratio || '%.';
      elsif old_cost > new_cost then
        cost_ratio := round((old_cost - new_cost) / old_cost * 100);
        output_message := ' has become cheaper by ' || cost_ratio || '%.';
      else output_message := ' price has remained the same.';
      end if;

      update service set cost = new_cost
      where id_service = id;

      commit;

      dbms_output.put_line(service_name || output_message);

    exception
      when no_data_found then
        dbms_output.put_line('There is no records with such id');
      when min_cost then
        dbms_output.put_line('Cost of service mustn''t be so cheap');
    end change_cost;


    procedure change_cost
      (id in varchar2, new_cost in number)
    is
      old_cost service.cost%type;
      service_name service.name%type;
      cost_ratio number;
      output_message varchar2(60);

      min_cost exception;
      pragma exception_init(min_cost, -02290);
    begin

      select cost, name
      into old_cost, service_name
      from service
      where name = id;

      if old_cost < new_cost then
        cost_ratio := round((new_cost - old_cost) / old_cost * 100);
        output_message := ' has risen in price by ' || cost_ratio || '%.';
      elsif old_cost > new_cost then
        cost_ratio := round((old_cost - new_cost) / old_cost * 100);
        output_message := ' has become cheaper by ' || cost_ratio || '%.';
      else output_message := ' price has remained the same.';
      end if;

      update service set cost = new_cost
      where name = id;

      commit;

      dbms_output.put_line(service_name || output_message);

    exception
      when no_data_found then
        dbms_output.put_line('There is no records with such id');
      when min_cost then
        dbms_output.put_line('Cost of service mustn''t be so cheap');
    end change_cost;


begin
  dbms_output.put_line(chr(13));
  change_cost(4, 60);
  change_cost('Furniture assembly', 50);
end;
/