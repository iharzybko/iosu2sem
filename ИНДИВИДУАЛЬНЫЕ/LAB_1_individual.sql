/*создание таблиц*/

create table equipment2 (
    ano number(10) primary key,
    name varchar2(50),
    mark varchar2(30),
    manuf_country varchar2(20) check(manuf_country!='China'),
    quantity number(5),
    price number(10) check(price>=2000)
);

create table facilities_for_work (
    eno number(10) primary key,
    name varchar2(50),
    mark varchar2(30),
    manuf_country varchar2(20) check(manuf_country!='China'),
    quantity number(5),
    price number(10) check(price>=2000)
);

/*добавление столбца для выполнения триггера
лабораторной работы №5*/

alter table equipment add using_times number(2);

/*заполнение добавленного столбца*/

update equipment
set using_times = 2
where eno=1;
update equipment
set using_times = 1
where eno=2;
update equipment
set using_times = 3
where eno=3;
update equipment
set using_times = 4
where eno=4;
update equipment
set using_times = 2
where eno=5;
update equipment
set using_times = 1
where eno=8;

/*продолжаем создание таблиц*/

create table brigades (
	bno number(10) primary key,
	brig_surname varchar2(50),
	brig_name varchar2(50),
	numb_of number(2) check(numb_of>=5 and numb_of<=20)
);

 create table lots (
 	lno number(10) primary key,
 	customer varchar2(50),
 	numb_of number(4) check(numb_of>=1000 and numb_of<=2000),
 	date_of date,
 	state char(1) check(state in('r', 'n')),
 	dno references details,
);

 create table details (
 	dno number(10) primary key,
 	name varchar2(50),
	diameter number(5),
	height number(5),
	material varchar2(20),
);

 create table processes (
 	pno number(10) primary key,
 	name varchar2(50) unique,
	type_of varchar2(4) check(type_of in('high', 'low')),
);

 create table tech_card (
 	tno number(10) primary key,
 	date_card date,
 	eno references equipment,
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
insert into equipment
values(6, 'Станок сверлильный', 'БУР13Ш', 'Румыния', '2', '7000', 1);

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
values(1, to_date('2017/11/06', 'yyyy/mm/dd'), 1, 2, 3, 1);
insert into tk
values(2, to_date('2017/11/07', 'yyyy/mm/dd'), 2, 2, 4, 3);
insert into tk
values(3, to_date('2017/11/09', 'yyyy/mm/dd'), 3, 3, 1, 9);
insert into tk
values(5, to_date('2017/12/09', 'yyyy/mm/dd'), 6, 3, 1, 27);









