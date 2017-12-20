/*Список оборудования для высококачественной обработки деталей(условная выборка)*/

select e.eno, e.name, e.mark
from equipment e
join tk on tk.eno=e.eno
join processes p on p.pno=tk.pno
where type_of='high';


/*Загруженность оборудования(итоговый запрос)*/

select eno, count(pno) as CONGESTION
from tk
group by eno;


/*Партии, проходящие заданную операцию(параметрический запрос)*/

select l.lno, l.customer 
from lots l
join tk on tk.lno=l.lno
join processes p on p.pno=tk.pno
where name='Прессование';

/*Общий список деталей и оборудования с количеством использований в картах(запрос на объединениe)*/

select e.name, count(tk.eno) "AMOUNT" from equipment e, tk
where e.eno = tk.eno
group by e.name
union
select d.name, count(tk.lno) "AMOUNT" from details d, lots l, tk
where d.dno = l.dno and l.lno = tk.lno
group by d.name;
/*доделать*/

/*Количество деталей по месяцам текущего года(запрос по полю с типом дата)*/

select month_cur, count(*), sum(numb_of)
from
(
	select distinct dno, to_char(date_of, 'month','nls_date_language = english') as month_cur, numb_of from lots
)
group by month_cur;

/*Запрос с внутренним соединением таблиц(natural join)
Соединение таблиц детали и партии*/

select * from details
natural join lots;

/*Запрос с внешним соединением таблиц(right join)
Соединение таблиц ТК и оборудование*/

select tk.date_card, e.name from tk
right join equipment e on e.eno=tk.eno;


 /*доделать*/


/*Запрос с использованием предиката IN с подзапросом
Вывести заказчика гаек*/

select customer
from lots
where dno in(select dno from details where name='Гайка');

/*Запрос с использованием предиката ANY/ALL с подзапросом
Вывести детали, высота которых больше cамой маленькой готовой детали*/

select * from details
where height >
any(
	select height
	from details
	join lots using (dno)
	where lots.state='r'
	);
/*Запрос с использованием предиката EXISTS/NOT EXISTS с подзапросом
Выбрать фи бригадира, чья бригада не задействована в ТК*/

select brig_surname, brig_name from brigades b
where not exists(select * from tk
				where tk.bno=b.bno);