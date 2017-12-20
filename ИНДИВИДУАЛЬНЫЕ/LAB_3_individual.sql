/*горизонтальное обновляемое представление
Вывод деталей диаметром меньше шести*/

create or replace view ready_details as
	select * from details 
	where diameter < 6
with check option;

/*Верная и неверная DML-инструкции*/

update ready_details set height ='36' where dno=3; --верная

insert into ready_details
values(8, 'Машинка', 15, 70, 'Дерево'); --неверная


/*смешанное необновляемое представление
ФИ бригадира, бригада которого работала на сверлильном станке*/

create or replace view eq_brig as
	select distinct b.brig_surname, b.brig_name
	from brigades b
	join tk on b.bno=tk.bno
	join equipment e on e.eno=tk.eno
	where e.name='Станок сверлильный';

insert into eq_brig
values('Зыбко', 'Игорь'); --добавление не происходит

/*обновляемое представление для работы с основной задачей БД 
Разрешить работу с данными только в рабочие дни (с понедельника по пятницу) и в рабочие часы (с 9 до 17)*/

create or replace view worktime as
select *
from tk
where to_char (sysdate, 'd') between 1 and 5
      and to_char(sysdate, 'hh24:mi:ss') between '09:00:00' and '17:00:00'
with check option;

/*Проверка: */

insert into worktime
values(5, to_date('2017/11/16', 'yyyy/mm/dd'), 1, 2, 3, 15); /*добавление не происходит в 1:04 в среду.
															   добавление происходит в 16:00 в среду.*/