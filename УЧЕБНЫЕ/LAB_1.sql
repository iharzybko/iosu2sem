create table branch (
    bno number(10) primary key,
    street varchar2(50),
    city varchar2(30),
    tel_no varchar2(10) unique
);

create table staff (
	sno number(10) primary key,
	fname varchar2(50),
	lname varchar2(50),
	address varchar2(50),
	tel_no varchar2(10),
	position varchar2(30),
	sex varchar2(6) check (sex='male'or sex='female'),
	dob date,
	salary number(5),
	bno references branch
	);

alter table staff modify sex varchar2(6);
alter table staff modify salary decimal(8,2);

 create table property_for_rent (
 	pno number(10) primary key,
 	street varchar2(50),
 	city varchar2(30),
 	type char(1) check (type='h' or type='f'),
 	rooms number(2),
 	rent decimal(8,2),
 	ono references owner,
 	sno references staff,
 	bno references branch
);

 create table renter (
 	rno number(10) primary key,
 	fname varchar2(50),
	lname varchar2(50),
	address varchar2(50),
	tel_no varchar2(10),
	pref_type char(1) check (pref_type in ('h', 'f')),
	max_rent decimal(8,2),
	bno references branch
 );

 create table owner (
 	ono number(10) primary key,
 	fname varchar2(50),
	lname varchar2(50),
	address varchar2(50),
	tel_no varchar2(10)
 );

 create table viewing (
 	rno references renter,
 	pno references property_for_rent,
 	date_o date,
 	comment_0 long,
 	constraint pr_key primary key (rno, pno) 
 );

create synonym objects for property_for_rent;

create sequence Staff_seq
increment by 5
start with 10;

insert into branch
values (1, 'Дзержинского, 95', 'Минск', '+375(29)5879654');
insert into branch
values (2, 'Пушкина, 4', 'Витебск', '+375(29)5859124');
insert into branch
values (3, 'Интернациональная, 12', 'Гомель', '+375(29)8756321');
insert into branch
values (4, 'Победы, 45', 'Брест', '+375(44)1728395');

insert into staff
values (Staff_seq.NEXTVAL, 'Строк', 'Марина', 'Солнечная, 6', '+375(33)6854321', 'Manager', 'female', to_date('1975/01/01', 'yyyy/mm/dd'), 12000, 1);
insert into staff
values (Staff_seq.NEXTVAL, 'Сорока', 'Ольга', 'Западная, 4', '+375(29)4365927', 'Bookkeeper', 'female', to_date('1985/02/01', 'yyyy/mm/dd'), 11000, 2);
insert into staff
values (Staff_seq.NEXTVAL, 'Алешко', 'Евгений', 'Слуцкая, 42', '+375(29)5848648', 'Programmer', 'male', to_date('1995/03/01', 'yyyy/mm/dd'), 10000, 3);
insert into staff
values (Staff_seq.NEXTVAL, 'Рэфкоф', 'Митяй', 'Берута, 66', '+375(33)3333333', 'Manager', 'male', to_date('1945/05/09', 'yyyy/mm/dd'), 1000, 2);

insert into objects
values (1, 'Коласа, 27', 'Гродно', 'h', 3, 100, 150, 150, 1 );
insert into objects
values (2, 'Ленина, 18', 'Пинск', 'f', 2, 150, 155, 155, 2);
insert into objects
values (3, 'Маркса, 17', 'Брест', 'h', 1, 200, 160, 160, 3);
insert into objects
values (4, 'Беды, 29', 'Ошмяны', 'h', 3, 200, 165, 170, 1);
insert into objects
values (5, 'Дударя, 77', 'Минск', 'f', 3, 400, 160, 160, 3);

insert into renter
values (1, 'Никита', 'Котович', 'Гродно, Богдановича, 15', '+375(29)5884685',  'h', 100, 3);
insert into renter
values (2, 'Василий', 'Петров', 'Зельва, Беды, 2', '+375(29)6588523',  'f', 200, 2);
insert into renter
values (3, 'Анна', 'Иванова', 'Волковыск, Купалы, 22', '+375(29)2257843',  'h', 300, 1);
insert into renter
values (4, 'Евгений', 'Иванов', 'Минск, Котова, 12', '+375(29)8432548',  'h', 250, 2);

insert into owner
select sno, fname, lname, address, tel_no from staff;

insert into viewing(rno, pno, date_o)
values (1, 1, to_date('2017/10/25', 'yyyy/mm/dd'));
insert into viewing(rno, pno, date_o)
values (1, 2, to_date('2017/10/22', 'yyyy/mm/dd'));
insert into viewing(rno, pno, date_o)
values (3, 1, to_date('2017/09/15', 'yyyy/mm/dd'));
insert into viewing
values (3, 2, to_date('2017/09/20', 'yyyy/mm/dd'),'great apartments');
insert into viewing(rno, pno, date_o)
values (1, 5, to_date('2017/10/15', 'yyyy/mm/dd'));


