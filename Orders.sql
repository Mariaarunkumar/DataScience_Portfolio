if object_id('orders')is not null drop table orders

Create table orders(
delivery_id Varchar(2),
delivery_date date,
delivery_status Varchar(15),
order_type Varchar(20),
total_amount int,
merchant_id Varchar(2),
merchant_rating float,
consumer_id Varchar(2),
city_id Varchar(10)
)

Insert into orders
Values ('D6','2021-02-05','completed','delivery',120,'M2',4.7,'C1','city2'),
('D1','2021-01-01','placed','delivery',100,'M1',NULL,'C1','city1'),
('D9','2021-02-07','placed','delivery',300,'M2',NULL,'C6','city2'),
('D4','2021-02-03','completed','delivery',200,'M3',4.2,'C3','city1'),
('D2','2021-01-02','cancelled','pickup',50,'M2',4.5,'C2','city2'),
('D7','2021-02-06','placed','delivery',60,'M3',NULL,'C5','city1'),
('D5','2021-02-04','placed','pickup',80,'M1',NULL,'C4','city3'),
('D8','2021-02-07','completed','pickup',90,'M1',2.9,'C2','city3'),
('D3','2021-02-02','placed','pickup',150,'M1',NULL,'C1','city2'),
('D6','2021-02-05','placed','delivery',120,'M2',NULL,'C1','city2'),
('D9','2021-02-07','completed','delivery',300,'M2',4.9,'C6','city2'),
('D4','2021-02-03','placed','delivery',200,'M3',NULL,'C3','city1'),
('D1','2021-01-01','completed','delivery',100,'M1',2.5,'C1','city1'),
('D8','2021-02-07','placed','pickup',90,'M1',NULL,'C2','city3'),
('D7','2021-02-06','cancelled','delivery',60,'M3',NULL,'C5','city1'),
('D2','2021-01-02','placed','pickup',50,'M2',4.5,'C2','city2'),
('D5','2021-02-04','cancelled','pickup',80,'M1',NULL,'C4','city3');

--Find the daily count of orders
select count(distinct delivery_id) as NUM_ORDERS, delivery_date
from orders
where delivery_status <> 'cancelled'
group by delivery_date

--Find the DoD sum of sales to see how the business is doing
select delivery_date, lag(Sum_orders,1,0)over(order by delivery_date) as pr_orders, Sum_orders as crnt_orders
from (select delivery_date, sum(total_amount) as Sum_orders
		from orders
		group by delivery_date) a

--Find the list of merchants with a minimum 3 avg rating
select merchant_id
from (select merchant_id,avg(merchant_rating) as avg_rating
	from orders
	where merchant_rating is not null
	group by merchant_id)a
where avg_rating>3

--In every city, find the merchants that have the highest rating
select merchant_id, city_id
from(
select merchant_id,city_id, row_number()over(partition by city_id order by avg_rating desc) as rnk
from(
select merchant_id,city_id, avg(merchant_rating) as avg_rating
from orders
group by merchant_id,city_id) a)b
where rnk = 1

--Find the merchant who has maximum cancelled orders overall
select merchant_id 
from(
select merchant_id,row_number()over(order by cnt desc) as rnk
from(
Select merchant_id, count(distinct delivery_id) as cnt
from orders
where delivery_status = 'cancelled'
group by merchant_id)a)b
where rnk=1

--Find the consumers and merchants from whom consumers ordered 2 or more times
select merchant_id, consumer_id, count(distinct delivery_id) as cnt
from orders
group by merchant_id, consumer_id
having count(distinct delivery_id)>=2

--The number of first time customers who placed an order with the top selling merchant of that day (top performing means those having maximum orders)

With top_merchant as (
select delivery_date, merchant_id
from(
Select delivery_date, merchant_id, row_number()over(partition by delivery_date order by cnt desc) as rnk
from(
select delivery_date, merchant_id, count(delivery_id) cnt
from orders
group by delivery_date, merchant_id)a)b
where rnk = 1),

First_cust as ( 
select consumer_id, min(delivery_date) as first_date
from orders
group by consumer_id),

first_cust_merchnt as(
select f.consumer_id,f.first_date, o.merchant_id
from First_cust f
left join orders o
on f.first_date=o.delivery_date)

select t.delivery_date, t.merchant_id, count(fc.consumer_id)
from top_merchant t
left join first_cust_merchnt fc
on t.delivery_date=fc.first_date and t.merchant_id=fc.merchant_id
group by t.delivery_date, t.merchant_id

--select * from orders