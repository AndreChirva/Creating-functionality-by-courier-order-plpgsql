-- Какие самолеты имеют более 50 посадочных мест?

select model 
from aircrafts a 
join seats s on a.aircraft_code = s.aircraft_code 
group by 1
having count(seat_no)>50 


-- В каких аэропортах есть рейсы, в рамках которых можно добраться бизнес-
 --классом дешевле, чем эконом - классом? 
 
with c1 as (
select distinct flight_id , fare_conditions, max(amount)  
from ticket_flights tf 
where fare_conditions = 'Economy'
group by 1,2
order by 1),
 c2 as (
 select distinct flight_id , fare_conditions , min(amount)  
from ticket_flights tf 
where fare_conditions = 'Business'
group by 1,2
order by 1)
select airport_name 
from c1
join c2 on c1.flight_id = c2.flight_id
join flights f on c1.flight_id = f.flight_id 
join airports a on f.departure_airport  = a.airport_code
where  min < max 

-- Есть ли самолеты, не имеющие бизнес - класса?

with cte as(
select model, 
( SELECT  array_agg(distinct fare_conditions)
 FROM seats s
 WHERE s.aircraft_code = a.aircraft_code
 AND s.fare_conditions = 'Business'
)
FROM aircrafts a)
select cte.model
from cte
where cte.array_agg is null

--  Найдите количество занятых мест для каждого рейса, 
-- процентное отношение количества занятых мест 
--  к общему количеству мест в самолете, 
-- добавьте накопительный итог вывезенных пассажиров по каждому аэропорту 
--  на каждый день. 

select k.flight_id,k.flight_no,k.scheduled_departure,k.departure_airport,
k.aircraft_code, k.колличество_мест, k.занятые_места,
round((k.занятые_места ::numeric / k.колличество_мест)::numeric ,2)*100 as процент_занятых_мест,
sum(занятые_места) over (partition by actual_departure::date, 
departure_airport order by actual_departure) as накопительный_итог
from
(select f.flight_id ,f.flight_no,f.scheduled_departure, f.departure_airport,
f.actual_departure,f.aircraft_code, count(bp.seat_no) as занятые_места,
(select count(s.seat_no) 
from seats s
where s.aircraft_code = f.aircraft_code ) as колличество_мест
from boarding_passes bp 
join flights f on bp.flight_id = f.flight_id
group by 1,2,3,4) as k
join aircrafts a on k.aircraft_code = a.aircraft_code

--Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов. 
--Выведите в результат названия аэропортов и процентное отношение. 


select f.departure_airport ,f.arrival_airport ,
round(count(f.flight_id)::numeric / sum(count(f.flight_id)) over(),4) *100 as Процентное_отношение
from routes r 
join flights f on r.flight_no = f.flight_no 
group by 1,2 

--Выведите количество пассажиров по каждому коду сотового оператора, если учесть, 
-- что код оператора - это три символа после +7


select count(*) as Колличество_пассажиров, 
substring(right(contact_data::text, 14),3,3) as Код_сотового_оператора
from tickets t 
group by 2

-- Между какими городами не существует перелетов?
-- Декартово произведение.


select distinct a.city ,a2.city 
from airports a 
cross join airports a2 
where a.city != a2.city 
except select distinct  r.departure_city ,r.arrival_city 
from routes r 


-- Классифицируйте финансовые обороты (сумма стоимости билетов) по маршрутам:
-- До 50 млн - low
-- От 50 млн включительно до 150 млн - middle
-- От 150 млн включительно - high
-- Выведите в результат количество маршрутов в каждом классе.
with cte as(
select r.flight_no , sum(tf.amount),
case when sum(tf.amount) < 50000000 then 'low'
     when sum(tf.amount) >= 50000000 and sum(tf.amount) <= 150000000 then 'middle'  
     when sum(tf.amount) > 150000000 then 'high' end as classes  
from ticket_flights tf 
join flights f on tf.flight_id = f.flight_id 
join routes r on f.flight_no = r.flight_no 
group by r.flight_no)
select count(cte.flight_no)as classes_routes  ,cte.classes 
from cte
group by cte.classes

-- Выведите пары городов между которыми расстояние более 5000 км


with cte as(
select distinct f.departure_airport,f.arrival_airport, 
	round(((acos((sind(d.latitude)*sind(a.latitude) + cosd(d.latitude) * 
	cosd(a.latitude) * cosd((d.longitude - a.longitude))))) * 6371)::numeric, 2)
	as Distance,
	f.flight_no,
	d.airport_name, 
	a.airport_name 
	from 
	flights f,
	airports d,
	airports a
	where f.departure_airport = d.airport_code and 
	f.arrival_airport = a.airport_code)
	select distinct r.departure_city , r.arrival_city 
	from routes r 
	join cte on r. flight_no = cte.flight_no
	where cte.Distance > 5000


