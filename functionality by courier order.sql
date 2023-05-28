
-- Создаем пользователя, пароль и права к схемам:


CREATE ROLE netocourier LOGIN PASSWORD 'NetoSQL2022';

GRANT all PRIVILEGES ON SCHEMA public TO netocourier;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO netocourier;
GRANT USAGE ON SCHEMA public TO netocourier;
GRANT INSERT, DELETE, REFERENCES, TRUNCATE, UPDATE, TRIGGER ON TABLE public.account TO netocourier;
GRANT INSERT, DELETE, REFERENCES, TRUNCATE, UPDATE, TRIGGER ON TABLE public.contact TO netocourier;
GRANT INSERT, DELETE, REFERENCES, TRUNCATE, UPDATE, TRIGGER ON TABLE public.contact TO netocourier;
GRANT INSERT, DELETE, REFERENCES, TRUNCATE, UPDATE, TRIGGER ON TABLE public.courier TO netocourier;
GRANT INSERT, DELETE, REFERENCES, TRUNCATE, UPDATE, TRIGGER ON TABLE public."user" TO netocourier;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO netocourier;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO netocourier;



-- Создаем отношения: 

create  type status_1 as enum ('В очереди', 'Выполняется', 'Выполнено', 'Отменен');
create  table courier (
  id uuid primary key default gen_random_uuid(),
  from_place varchar (250) not null,
  where_place varchar (250) not null,
  name varchar (50) not null,
  account_id uuid not null references account (id),
	contact_id uuid not null references contact (id),
	description TEXT,
	user_id uuid not null references "user" (id),
	status status_1 not null default 'В очереди',
	created_date date not null default now());

CREATE TABLE account (
	id uuid PRIMARY key default gen_random_uuid(), 
	name varchar (50) not null);


CREATE TABLE contact (
	id uuid PRIMARY key default gen_random_uuid(),
	last_name varchar (50) not null,
	first_name varchar (50) not null,
	account_id uuid not null references account (id));

CREATE TABLE "user" (
	id uuid PRIMARY key default gen_random_uuid(),
	last_name varchar(50) NOT NULL,
	first_name varchar(50) NOT NULL,
	dismissed boolean default false not null);

-- Для возможности тестирования приложения  реализуем процедуру insert_test_data(value), которая принимает на вход целочисленное значение:


create or replace procedure insert_test_data (int4 ) as $$
declare i int4;
        acc_id uuid;
       con_id uuid;
      us_id uuid;
     stat status_1;
   begin 
	i = 0;
	for i in 1..$1 
	loop
		insert into account (name)
		select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1, 50);
		end loop;
	i = 0;
    for  i in 1..$1 * 2 
    loop 
	 insert into contact (last_name, first_name, account_id)
	    select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1, 50),
		substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1, 50),
		id from account order by random() limit 1;
	     end loop;
	    i = 0;
	   for i in 1..$1 
	   loop
		   insert into "user" (last_name, first_name, dismissed)
		   select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1, 50) ,
		substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1, 50) ,
		random()::int4::boolean;
	   	end loop;
	   i = 0;
	     for i in 1..$1*5 
	     loop
		      acc_id = (select id from account order by random() limit 1);
       con_id = (select id from contact order by random() limit 1 );
      us_id = ( select id from "user" order by random() limit 1 );
     stat = (SELECT status FROM unnest(enum_range(NULL::status_1)) as status ORDER BY random() LIMIT 1);
		    insert into courier (from_place, where_place, name, account_id,
			contact_id, description, user_id, status, created_date)
			 select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1, 250) ,
		substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1,250) ,
		substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1, 50),
		acc_id,
		con_id,
		substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		ceiling((random()*33))::int2), ceiling((random()*10))::integer), 1, 100),
		us_id, 
		stat,
		(now() - interval '1 day' * round(random() * 1000))::date;
		end loop;
	     end;
	  

$$ language plpgsql


-- Реализуем процедуру по удалению тестовых данных из отношений:

create or replace procedure erase_test_data() as $$
begin 
	truncate account, contact, courier, "user";
end;

$$ language plpgsql

--  На бэкенде реализована функция по добавлению новой записи о заявке на курьера:
 function add($params) --добавление новой заявки
    {
        $pdo = Di::pdo();
        $from = $params["from"]; 
        $where = $params["where"]; 
        $name = $params["name"]; 
        $account_id = $params["account_id"]; 
        $contact_id = $params["contact_id"]; 
        $description = $params["description"]; 
        $user_id = $params["user_id"]; 
        $stmt = $pdo->prepare('CALL add_courier (?, ?, ?, ?, ?, ?, ?)');
        $stmt->bindParam(1, $from); --from_place
        $stmt->bindParam(2, $where); --where_place
        $stmt->bindParam(3, $name); --name
        $stmt->bindParam(4, $account_id); --account_id
        $stmt->bindParam(5, $contact_id); --contact_id
        $stmt->bindParam(6, $description); --description
        $stmt->bindParam(7, $user_id); --user_id
        $stmt->execute();
    }
 -- реализовуем  процедуру add_courier(from_place, where_place, name, account_id, contact_id, description, user_id), 
 --  которая принимает на вход вышеуказанные аргументы и вносит данные в таблицу courier:
    
    create or replace procedure  add_courier(varchar(250), varchar(250), varchar(150),
	uuid, uuid, text, uuid) as $$
begin 
	insert into  courier (from_place, where_place, name, account_id, contact_id, description, user_id)
		values ($1, $2, $3, $4, $5, $6, $7);
end;

$$ language plpgsql

 --  На бэкенде реализована функция по получению записей о заявках на курьера: 
static function get() --получение списка заявок
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_courier()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        return $data;
    }
 -- реализуем функцию get_courier(), которая возвращает таблицу:
    
    create or replace function get_courier() returns table ( id uuid, from_place varchar(250),
 where_place varchar(250), name varchar(150), account_id uuid, account varchar(150), 
 contact_id uuid, contact varchar(150), description text, user_id uuid, "user" varchar(150), 
 status status_1, created_date date) as $$
 begin 
 	return query 
 	select co.id , co.from_place ,co.where_place, co.name , co.account_id , a.name , co.contact_id ,
  (c.last_name ||' '|| c.first_name):: varchar(150) as contact , co.description , co.user_id,
 	(u.last_name ||' '|| u.first_name):: varchar(150)  as user, co.status, co.created_date  
 	from courier co
 	join account a on co.account_id = a.id  
 	join contact c on co.contact_id = c.id 
 	join "user" u on co.user_id = u.id 
 	order by co.status, co.created_date desc;
 end;
 
 
 $$ language plpgsql
 
 
 --  На бэкенде реализована функция по изменению статуса заявки.
function change_status($params) --изменение статуса заявки
    {
        $pdo = Di::pdo();
        $status = $params["new_status"];
        $id = $params["id"];
        $stmt = $pdo->prepare('CALL change_status(?, ?)');
        $stmt->bindParam(1, $status); --новый статус
        $stmt->bindParam(2, $id); --идентификатор заявки
        $stmt->execute();
    }
 -- реализуем  процедуру change_status(status, id), которая будет изменять статус заявки. 
 -- На вход процедура принимает новое значение статуса и значение идентификатора заявки.


create or replace procedure  change_status( status_1,  uuid ) as $$ 
 begin 
 	update courier set status = $1 
 	where id = $2;
 end;
 
 $$ language plpgsql
 
 --  На бэкенде реализована функция получения списка сотрудников компании.
static function get_users() --получение списка пользователей
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_users()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['user'];
        }
        return $result;
    }
 -- реализеум  функцию get_users(), которая возвращает таблицу согласно следующей структуры:
 -- user - фамилия и имя сотрудника через пробел
    
    create or replace function get_users() returns table ( "user" varchar(150)) as $$ 
begin 
	return query 
	select (u.last_name ||' '|| u.first_name)::varchar(150) as "user"  
	from "user" u
	where dismissed is false 
	order by last_name;
end;

$$ language plpgsql 

-- На бэкенде реализована функция получения списка контрагентов.
static function get_accounts() --получение списка контрагентов
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_accounts()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['account'];
        }
        return $result;
    }
-- реализуем  функцию get_accounts(), которая возвращает таблицу согласно следующей структуры:
-- account - название контрагента.

    create or replace function get_accounts() returns table ( account varchar (150)) as $$ 
begin 
	return query 
	select name as asccount
	from account
	order by name;
end;


$$ language plpgsql

--  На бэкенде реализована функция получения списка контактов.
function get_contacts($params) --получение списка контактов
    {
        $pdo = Di::pdo();
        $account_id = $params["account_id"]; 
        $stmt = $pdo->prepare('SELECT * FROM get_contacts(?)');
        $stmt->bindParam(1, $account_id); --идентификатор контрагента
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['contact'];
        }
        return $result;
    }
-- реализуем  функцию get_contacts(account_id), которая принимает на вход идентификатор контрагента и возвращает таблицу с контактами переданного контрагента согласно следующей структуры:
-- contact - фамилия и имя контакта через пробел.
    
    create or replace function get_contacts(uuid default null )
returns table (contact varchar(150)) as $$ 
begin 
	if $1 is null 
	then 
	return query 
	select 'Выберите контрагента' ;
	else 
	return query 
	select (c.last_name ||' '|| c.first_name) :: varchar (150) as contact  
	from contact c
	where account_id = $1
	order by c.last_name;
	end if;
end ;



$$ language plpgsql

--  На бэкенде реализована функция по получению статистики о заявках на курьера: 
static function get_stat() -- получение статистики
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM courier_statistic');
        $stmt->execute();
        $data = $stmt->fetchAll();
        return $data;
    }
-- Реализуем  представление courier_statistic, со следующей структурой:
-- account_id - идентификатор контрагента
-- account - название контрагента
-- count_courier - количество заказов на курьера для каждого контрагента
-- count_complete - количество завершенных заказов для каждого контрагента
-- count_canceled - количество отмененных заказов для каждого контрагента
-- percent_relative_prev_month -  процентное изменение количества заказов текущего месяца к предыдущему месяцу для каждого контрагента, если получаете деление на 0, то в результат вывести 0.
-- count_where_place - количество мест доставки для каждого контрагента
-- count_contact - количество контактов по контрагенту, которым доставляются документы
-- cansel_user_array - массив с идентификаторами сотрудников, по которым были заказы со статусом "Отменен" для каждого контрагента


create or replace view courier_statistic as 
with f1 as ( select c.account_id, count(c.id) as count_courier 
              from courier c
              where c. status = 'Выполняется'
              group by 1),
 f2 as (select c2.account_id, count(c2.id) as count_complete 
              from courier c2
              where c2. status = 'Выполнено'
              group by 1 ),
  f3 as (select c.account_id, count(c.id) as count_canceled
              from courier c
              where c. status = 'Отменен'
              group by c.account_id ),
   f4 as ( select c3.account_id , count( distinct  c3.where_place) as count_where_place
            from courier c3
            group by 1),
    f5 as ( select c4.account_id, count(c4.id) as count_contact
            from contact c4
            group by 1),
    f6 as (select account_id , count(c.id) as current_month
from courier c 
where date_trunc('Month', created_date ) = date_trunc('Month', current_date  )
group by account_id),
  f7 as (select account_id ,  count(c.id) as previous_month
from courier c 
where date_trunc('Month', created_date - interval '1 month' ) = 
date_trunc('Month', current_date  - interval '1 month') 
group by 1 ),
 f8 as (select c.account_id, array_agg(c.user_id) as cansel_user_array 
              from courier c
              where c. status = 'Отменен'
              group by c.account_id  )
  select a.id , a."name" , coalesce(f1.count_courier, 0) as count_courier,
  coalesce(f2.count_complete, 0) as count_complete,
  coalesce(f3.count_canceled, 0) as count_canceled,
  case 
  	when coalesce( f7.previous_month, 0) = 0
  	then 0
  	else (coalesce( f6.current_month, 0) -  f7.previous_month) / f6.current_month * 100
    end percent_relative_prev_month,
    coalesce(f4.count_where_place, 0) as count_where_place,
    coalesce(f5.count_contact, 0) as count_contact,
    f8.cansel_user_array
    from account a 
   left join f1 f1 on a.id = f1.account_id
  left join f2 f2 on a.id = f2.account_id
  left join f3 f3 on a.id = f3.account_id
  left join f4 f4 on a.id = f4.account_id
  left join f5 f5 on a.id = f5.account_id
  left join f6 f6 on a.id = f6.account_id
  left join f7 f7 on a.id = f7.account_id
  left join f8 f8 on a.id = f8.account_id
  
  