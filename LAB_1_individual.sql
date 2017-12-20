/*создание таблиц*/

create table facilities_for_work (
    eno number(10) primary key,
    name varchar2(50),
    mark varchar2(30),
    manuf_country varchar2(40) check(manuf_country!='Китай'),
    quantity number(5),
    price number(10) check(price>=2000)
);

alter table facilities_for_work modify price decimal(8,2);


create table brigades (
	bno number(10) primary key,
	brig_surname varchar2(50),
	brig_name varchar2(50),
	numb_of number(2) check(numb_of>=5 and numb_of<=20)
);

 create table lots (
 	lno number(10) primary key,
 	customer varchar2(50),
 	dno references details,
 	numb_of number(4) check(numb_of>=1000 and numb_of<=2000),
 	date_of date,
 	state char(1) check(state in('r', 'n')) 	
);

 create table details (
 	dno number(10) primary key,
 	name varchar2(50),
	diameter number(5),
	height number(5),
	material varchar2(20)
);

 create table processes (
 	pno number(10) primary key,
 	name varchar2(50) unique,
	type_of varchar2(4) check(type_of in('high', 'low'))
);

 create table tech_card (
 	tno number(10) primary key,
 	date_card date,
 	eno references facilities_for_work,
 	pno references processes,
 	bno references brigades,
 	lno references lots
);

/*создание синонимов*/ 
create synonym equipment for facilities_for_work;
create synonym tk for tech_card;

/*создание последовательности*/
create sequence lots_seq
increment by 2
start with 1;

/*cоздание индекса*/
create index FNAME on brigades(fname);
	
insert into equipment
values(1, 'Станок протяжной', 'СП-123', 'Россия', '12', '2500');
insert into equipment
values(2, 'Станок сверлильный', 'СС-15', 'Беларусь', '36', '3000');
insert into equipment
values(3, 'Станок токарный', 'СТ-28', 'Украина', '15', '2200');
insert into equipment
values(4, 'Станок фрезерный', 'SF-45A', 'Великобритания', '7', '5600');
insert into equipment
values(5, 'Станок шлифовальный', 'СШ-2', 'Болгария', '41', '3200');

insert into brigades
values(1, 'Нечай', 'Валерий','10');
insert into brigades
values(2, 'Веретило', 'Алексей','12');
insert into brigades
values(3, 'Перминов', 'Владимир','7');
insert into brigades
values(4, 'Сыс', 'Анатолий', '11');

insert into details
values(1, 'Втулка', '15', '40', 'Сталь');
insert into details
values(2, 'Гайка', '7', '5', 'Сталь');
insert into details
values(3, 'Отвод', '5', '25', 'Пластик');
insert into details
values(4, 'Муфта', '16', '38', 'Карбон');
insert into details
values(5, 'Стакан', '6', '18', 'Чугун');

insert into processes
values(1, 'Шлифование', 'high');
insert into processes
values(2, 'Прессование', 'high');
insert into processes
values(3, 'Сверление', 'low');
insert into processes
values(4, 'Нарезание резьбы', 'high');
insert into processes
values(5, 'Фрезеровка', 'low');

insert into lots
values(lots_seq.nextval, 'ООО "КСОМ"', 2, '1200', to_date('2017/11/05', 'yyyy/mm/dd'), 'n');
insert into lots
values(lots_seq.nextval, 'ОАО "ГродноАзот"', 4, '1300', to_date('2017/11/09', 'yyyy/mm/dd'), 'n');
insert into lots
values(lots_seq.nextval, 'ЗАО "Атлант-М"', 5, '1500', to_date('2017/06/18', 'yyyy/mm/dd'), 'r');
insert into lots
values(lots_seq.nextval, 'ОАО "Сад и огород"', 3, '2000', to_date('2017/09/08', 'yyyy/mm/dd'), 'r');
insert into lots
values(lots_seq.nextval, 'Гаражный кооператив №8', 1, '1000', to_date('2017/08/16', 'yyyy/mm/dd'), 'n');
insert into lots
values(lots_seq.nextval, 'ООО "КричевЦемент"', 5, '1111', to_date('2017/10/15', 'yyyy/mm/dd'), 'r');
insert into lots
values(lots_seq.nextval, 'БСЗ Атлант', 4, '1234', to_date('2017/10/06', 'yyyy/mm/dd'), 'r');

insert into tk
values(1, to_date('2017/11/06', 'yyyy/mm/dd'), 1, 2, 3, 15);
insert into tk
values(2, to_date('2017/11/07', 'yyyy/mm/dd'), 2, 2, 4, 17);
insert into tk
values(3, to_date('2017/11/09', 'yyyy/mm/dd'), 3, 3, 1, 23);
insert into tk
values(4, to_date('2017/11/15', 'yyyy/mm/dd'), 1, 1, 3, 15);









