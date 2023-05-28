-- Задание 1. Создайте подключение к удаленному облачному серверу базы HR (база данных postgres, схема hr), 
-- используя модуль postgres_fdw.
-- Напишите SQL-запрос на выборку любых данных используя 2 сторонних таблицы, соединенных с помощью JOIN.
-- В качестве ответа на задание пришлите список команд, использовавшихся для настройки подключения, 
-- создания внешних таблиц, а также получившийся SQL-запрос.



select *
from pg_catalog.pg_available_extensions pae 
where installed_version is not null 

create extension postgres_fdw

create server andrey_server 
foreign data wrapper postgres_fdw
options(host'51.250.106.132', port '19001', dbname 'postgres')

create user mapping for postgres
server andrey_server 
options (user 'netology', password 'NetoSQL2019')

create foreign table city1 ( city_id int4 NOT NULL,
	                        city varchar(50) NOT NULL)                            
 server andrey_server 
  options ( schema_name 'hr', table_name 'city')
  
 create foreign table address1 ( address_id int4 NOT NULL,
	                             full_address varchar(250) NOT NULL,
	                             city_id int4 NOT NULL,
	                              postal_code varchar(10) NULL )
 server andrey_server 
  options ( schema_name 'hr', table_name 'address')
  
  
  select *
  from a.address1 as aa
  join a.city1 as ac on ac.city_id = aa.city_id
  where city = 'Владимир'
  
 
  
  
  
