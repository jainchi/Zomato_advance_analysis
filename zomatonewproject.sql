-- 1. Create Customers Table
DROP TABLE orders;
CREATE TABLE customers (
    customer_id varchar(7) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    reg_date DATE NOT NULL
);

-- 2. Create Restaurants Table
CREATE TABLE restaurants (
    restaurant_id varchar(7) PRIMARY KEY,
    restaurant_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    opening_hours VARCHAR(50)
);

-- 3. Create Riders Table
CREATE TABLE riders (
    rider_id VARCHAR(7) PRIMARY KEY,
    rider_name VARCHAR(100) NOT NULL,
    sign_up_date DATE NOT NULL
);

-- 4. Create Orders Table (Linked to Customers and Restaurants)
CREATE TABLE orders (
    order_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10) REFERENCES customers(customer_id),
    restaurant_id varchar(10) REFERENCES restaurants(restaurant_id),
    order_item VARCHAR(505) NOT NULL,
    order_date DATE NOT NULL,
    order_time VARCHAR(30),
    order_status VARCHAR(20) NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL
);

-- 5. Create Deliveries Table (Linked to Orders and Riders)
CREATE TABLE deliveries (
    delivery_id varchar(7) PRIMARY KEY,
    order_id VARCHAR(10) REFERENCES orders(order_id),
    delivery_status VARCHAR(20) NOT NULL,
    delivery_time VARCHAR(20),
    rider_id VARCHAR(7) REFERENCES riders(rider_id)
);



SELECT * FROM deliveries 
SELECT * FROM customers
SELECT * FROM riders
SELECT * FROM orders
SELECT * FROM restaurants

-- Q.0 -- Most frequently ordered dishes by a customer named 'Amity'in the last year
SELECT customer_name,order_item,count(*) as counts FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
WHERE order_date>CURRENT_DATE -Interval '365 days'
and customer_name='Amity'
GROUP BY 1,2
order by 3 DESC


-- Q1 Most frequently ordered dishes by  customers in the last year
SELECT c.customer_id,order_item,count(*) as totaltime FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
WHERE order_date>CURRENT_DATE -Interval '365 days'
GROUP BY 1,2
order by 1,3 DESC

-- Q.2 Popular time slots for orders(4-HOUR INTERVAL)
WITH cte1 AS(
SELECT *,
CASE
	WHEN EXTRACT(HOUR FROM order_time::TIME)<4 THEN '0 to 4'
	WHEN EXTRACT(HOUR FROM order_time::TIME)<8 THEN '4 to 8'
	WHEN EXTRACT(HOUR FROM order_time::TIME)<12 THEN '8 to 12'
	WHEN EXTRACT(HOUR FROM order_time::TIME)<16 THEN '12 to 16'
	WHEN EXTRACT(HOUR FROM order_time::TIME)<20 THEN '16 to 20'
	WHEN EXTRACT(HOUR FROM order_time::TIME)<24 THEN '20 to 24'
	end as timeslot
from orders
)SELECT timeslot,count(*) as totalordercount FROM cte1
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3

-- Q3 Average order value for high-volume customers


SELECT c.customer_id,AVG(total_amount) AS avgpurchase FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
GROUP BY 1
HAVING SUM(total_amount)>1500

-- Q.4 High value customers (spending over 1600)
SELECT c.customer_id,SUM(total_amount) AS totalpurchase FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
GROUP BY 1
HAVING SUM(total_amount)>1600


-- Q.5 orders without delivery
SELECT  restaurant_name, city,count(delivery_status) as totalundelivered 
FROM orders o
JOIN deliveries d
ON o.order_id=d.order_id
JOIN restaurants r
ON r.restaurant_id=o.restaurant_id
WHERE delivery_status ='notdelivered'
GROUP BY 1,2

-- Q.6 Restaurant Revenue Ranking
-- Rank by total revenue from last year,including their name, total revenue, and rank within its city

WITH ctee AS(
SELECT city,restaurant_name, SUM(total_amount) AS totalrevenue
FROM orders o
JOIN restaurants r
ON r.restaurant_id=o.restaurant_id
WHERE EXTRACT(YEAR FROM order_date) =2025
GROUP BY 1,2)
SELECT *, RANK() OVER(PARTITION BY city ORDER BY totalrevenue desc) as rnk
FROM ctee


-- Q.7 Most popular dish by city
-- Identify most popular dish  in each city based on the number of orders
SELECT * FROM
(
WITH dishcte AS
(
SELECT city,order_item,count(*) AS cnt
FROM orders o
JOIN restaurants r
ON r.restaurant_id=o.restaurant_id
GROUP BY 1,2
)
SELECT *, RANK() OVER(PARTITION BY city ORDER BY cnt DESC) as rnk
FROM dishcte
)WHERE rnk=1

-- Q.8 Customer Churn
-- FIND CUSTOMERS WHO HAVEN'T PLACED AN ORDER IN 2026 BUT DID IN 2025

SELECT c.customer_id, c.customer_name 
FROM customers c
WHERE c.customer_id IN (
    -- Step 1: Get all customers who ordered in 2025
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE EXTRACT(YEAR FROM order_date) = 2025
)
AND c.customer_id NOT IN (
    -- Step 2: Exclude anyone who ordered in 2026
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE EXTRACT(YEAR FROM order_date) = 2026
);

-- Q.9 Cancellation Rate Comparison
-- Calculate and compare the order cancellation rate for each restaurant between the current year and the previous year
WITH cte1 AS(
SELECT o.restaurant_id,count(o.order_id) AS totalorders,
COUNT(CASE WHEN d.delivery_status='notdelivered'  THEN 1  END) AS totalcancelled
FROM orders o 
LEFT JOIN deliveries d
ON o.order_id=d.order_id
WHERE EXTRACT(YEAR FROM order_date)=2025
GROUP BY 1),
cancellationcte1 AS(
SELECT restaurant_id,totalorders,totalcancelled,100.0*(totalcancelled/totalorders) AS cancellationrate
FROM cte1)
,

cte2 AS(
SELECT o.restaurant_id,count(o.order_id) AS totalorders,
COUNT(CASE WHEN d.delivery_status ='notdelivered' THEN 1  END) AS totalcancelled
FROM orders o 
JOIN deliveries d
ON o.order_id=d.order_id
WHERE EXTRACT(YEAR FROM order_date)=2026
GROUP BY 1),
cancellationcte2 AS(
SELECT restaurant_id,totalorders,totalcancelled,100.0*(totalcancelled/totalorders) AS cancellationrate
FROM cte2)

SELECT c2.restaurant_id,
		c1.cancellationrate AS cancellation25,
		c2.cancellationrate as cancellation26
FROM cancellationcte1 c1
JOIN cancellationcte2 c2
ON c1.restaurant_id=c2.restaurant_id



-- Q.10 Rider's average delivery time
-- Determine each rider's average deliver time
WITH cte1 AS(
SELECT rider_id, o.order_id, delivery_time::TIME,order_time::TIME, delivery_time::TIME -order_time::TIME AS timetooktodeliver
FROM orders o
JOIN deliveries d
ON o.order_id=d.order_id
),
cte2 AS(
SELECT order_id,(timetooktodeliver +INTERVAL '24 HOURS') as timetooks2 from cte1
WHERE timetooktodeliver<'00:00:00'::INTERVAL
),
cte3 AS(
SELECT  rider_id,order_time,delivery_time::TIME,coalesce(timetooks2,timetooktodeliver) AS timetook
from cte1
LEFT JOIN cte2
ON cte1.order_id=cte2.order_id
)
SELECT rider_id,avg(timetook) AS avgtimetakes from cte3
GROUP BY 1


-- Q.11 Monthly restaurant growth ratio:
-- Calculate each restaurant's growth ratio based on total no. of deliveried order since its joining

WITH ctee1 AS(
SELECT restaurant_name,EXTRACT(YEAR FROM order_date)as years,EXTRACT(MONTH FROM order_date) as months,Count(*) as orderdelivered
FROM restaurants r
JOIN orders o 
ON r.restaurant_id=o.restaurant_id
JOIN deliveries d
ON o.order_id=d.order_id
WHERE delivery_status='delivered'
GROUP BY 1,2,3
),
ctee2 AS
(
SELECT *, LAG(orderdelivered) OVER(PARTITION BY restaurant_name ORDER BY years,months) AS lastmonthdelivered
FROM ctee1
)
SELECT *,100.0*(orderdelivered-lastmonthdelivered)/lastmonthdelivered   as percentagegrowth
from ctee2


-- Q.12	Customer Segmentation:
--	Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their spending.
--  Compare to the AOV, IF a customer's total spending exceed the aov label them as 'gold', otherwise 'silver'
--  Write a SQl Query to determine each segment's total number of orders and total revenue

WITH cte1 AS(
SELECT c.customer_id,c.customer_name,total_amount,SUM(total_amount) AS totalspentamt , AVG(total_amount) as avgspent,COUNT(total_amount) AS totalorders
FROM customers c
JOIN orders o 
ON c.customer_id=o.customer_id
GROUP BY 1,2,3),
cte2 AS(
SELECT *,CASE WHEN avgspent>(SELECT AVG(total_amount) from orders) THEN 'GOLD' ELSE 'SILVER' END AS labled
from cte1
)
SELECT labled,SUM(total_amount),count(total_amount)
FROM 
cte2
GROUP BY 1

OR

WITH cte1 AS(
SELECT c.customer_id,c.customer_name,SUM(total_amount) AS totalspentamt , AVG(total_amount) as avgspent,COUNT(total_amount) AS totalorders
FROM customers c
JOIN orders o 
ON c.customer_id=o.customer_id
GROUP BY 1,2),
cte2 AS(
SELECT *,CASE WHEN avgspent>(SELECT AVG(total_amount) from orders) THEN 'GOLD' ELSE 'SILVER' END AS labeld
from cte1
)
SELECT labeld,SUM(totalspentamt) AS totalamountspent,SUM(totalorders) as totaltransactions,Count(*) as totalcustomers
FROM 
cte2
GROUP BY 1

/*
🏆 Which one is correct?
According to the project prompt: "Segment customers into 'Gold' or 'Silver' groups based on their spending... 
IF a customer's avg spending exceed the aov label them as gold."

Because the business requirement wants to segment the actual human customers rather than individual transactions, 
2nd query structure is the logically correct approach.My second query accurately identifies who my high-value users are as whole individuals. 
*/


-- Q.13 Rider's monthly earnings: Assume they earn 8% of the amount


SELECT r.rider_id,
EXTRACT(YEAR FROM o.order_date) AS order_year,
EXTRACT(MONTH FROM o.order_date) AS order_month,
SUM(total_amount)*0.08 as earning
FROM orders o 
JOIN deliveries d
ON o.order_id=d.order_id
JOIN riders r 
ON d.rider_id=r.rider_id
WHERE d.delivery_status = 'delivered'
GROUP BY 1,2,3
order by 1,2


---Q.14 Rider Ratings Analysis:
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
-- riders receive this rating based on delivery time.
-- If orders are delivered less than 1hour of order received time the rider get 5 star rating,
-- if they deliver more than 1 to less than 4 hour they get 4-star rating
-- if they deliver more than 4 to less than 8 hour they get 3-star rating
-- if they deliver more than 8 to less than 12 hour they get 2-star rating
-- else 1-star ratings

WITH cte1 AS
(
SELECT rider_id, o.order_id, delivery_time::TIME,order_time::TIME, delivery_time::TIME -order_time::TIME AS timetooktodeliver
FROM orders o
JOIN deliveries d
ON o.order_id=d.order_id
),
cte2 AS(
SELECT order_id,(timetooktodeliver +INTERVAL '24 HOURS') as timetooks2 from cte1
WHERE timetooktodeliver<'00:00:00'::INTERVAL
),
cte3 AS(
SELECT  rider_id,order_time,delivery_time::TIME,coalesce(timetooks2,timetooktodeliver) AS timetook
from cte1
LEFT JOIN cte2
ON cte1.order_id=cte2.order_id
),
cte4 AS(
SELECT *,
CASE
	WHEN timetook<=Interval '1 hour' THEN '5-Star ratings'
	WHEN timetook>Interval '1 hour' AND timetook<=Interval '4 hour' THEN '4-Star ratings'
	WHEN timetook>Interval '4 hour' AND timetook<=Interval '8 hour' THEN '3-Star ratings'
	WHEN timetook>Interval '8 hour' AND timetook<=Interval '12 hour' THEN '2-Star ratings'
	else '1-Star ratings'
	end as starredcategorisation
FROM cte3
)
SELECT rider_id,starredcategorisation, count(*) as totalstarratingcount
FROM cte4 
GROUP by 1,2
ORDER BY 1,3 DESC



-- Q.15 Order Frequency by Day:
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.

SELECT * FROM(
WITH cte as(
SELECT restaurant_id,extract(DOW from order_date) as dayofweek,count(*) as ordercount
FROM orders o
GROUP BY 1,2
ORDER BY 1,2
)
SELECT *,RANK() OVER(PARTITION BY restaurant_id ORDER BY ordercount DESC) AS rnk FROM cte
)
WHERE rnk=1


-- Q.16 Customer Lifetime Value (CLV):
-- Calculate the total revenue generated by each customer over all their orders


SELECT customer_id, sum(total_amount) as totalrevenue FROM orders
group by 1




-- Q.17 Rider Efficiency:
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.


WITH cte1 AS
(
SELECT rider_id, o.order_id, delivery_time::TIME,order_time::TIME, delivery_time::TIME -order_time::TIME AS timetooktodeliver
FROM orders o
JOIN deliveries d
ON o.order_id=d.order_id
),
cte2 AS
(
SELECT order_id,(timetooktodeliver +INTERVAL '24 HOURS') as timetookstodeliver2
FROM cte1
WHERE timetooktodeliver<'00:00:00'::INTERVAL
),
cte3 AS
(
SELECT  rider_id,coalesce(timetookstodeliver2,timetooktodeliver) AS timetook
FROM cte1
LEFT JOIN cte2
ON cte1.order_id=cte2.order_id
),
rideraverages AS(
SELECT rider_id,AVG(timetook) as avgtimetook
FROM cte3
GROUP BY 1
),
ranked_efficiency AS (
    -- Step 5: Rank them from fastest to slowest AND slowest to fastest
    SELECT 
        rider_id,
        avgtimetook,
        RANK() OVER (ORDER BY avgtimetook ASC) AS fastest_rank,
        RANK() OVER (ORDER BY avgtimetook DESC) AS slowest_rank
    FROM rideraverages
)
SELECT rider_id,
    avgtimetook,
    CASE 
        WHEN fastest_rank = 1 THEN 'Highest Efficiency (Fastest)'
        WHEN slowest_rank = 1 THEN 'Lowest Efficiency (Slowest)'
    END AS efficiency_tier
FROM ranked_efficiency
WHERE fastest_rank = 1 OR slowest_rank = 1;


-----Less automation part

WITH cte1 AS
(
SELECT rider_id, o.order_id, delivery_time::TIME,order_time::TIME, delivery_time::TIME -order_time::TIME AS timetooktodeliver
FROM orders o
JOIN deliveries d
ON o.order_id=d.order_id
),
cte2 AS
(
SELECT order_id,(timetooktodeliver +INTERVAL '24 HOURS') as timetookstodeliver2
FROM cte1
WHERE timetooktodeliver<'00:00:00'::INTERVAL
),
cte3 AS
(
SELECT  rider_id,coalesce(timetookstodeliver2,timetooktodeliver) AS timetook
FROM cte1
LEFT JOIN cte2
ON cte1.order_id=cte2.order_id
),
rideraverages AS(
SELECT rider_id,AVG(timetook) as avgtimetook
FROM cte3
GROUP BY 1
),
ranked_efficiency AS (
    -- Step 5: Rank them from fastest to slowest AND slowest to fastest
    SELECT 
        rider_id,
        avgtimetook,
        RANK() OVER (ORDER BY avgtimetook ASC) AS fastest_rank,
        RANK() OVER (ORDER BY avgtimetook DESC) AS slowest_rank
    FROM rideraverages
)
SELECT * from ranked_efficiency
where fastest_rank=1
or slowest_rank=1


-- Selected order_id because we need to make a join later
-- We can easily check manually riders with max and min average



-- Q.18 Order Item Popularity:
-- Track the popularity of specific order items over time and identify seasonal demand spikes.

SELECT * FROM(
WITH MYCTE AS(
SELECT order_item,extract(year from order_date) as years,extract(month from order_date) as months ,COUNT(*) AS totalorde
FROM ORDERS
GROUP BY 1,2,3
)
SELECT *,RANK() OVER(PARTITION BY order_item ORDER BY totalorde DESC) rnk
FROM MYCTE)
WHERE rnk<=2


-- Q.19 Monthly Restaurant Growth Ratio:
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining

WITH cte1 AS(
SELECT r.restaurant_id,restaurant_name,DATE_TRUNC('month',order_date) AS ordermonthdate,total_amount
FROM ORDERS O
JOIN restaurants r
ON o.restaurant_id=r.restaurant_id
JOIN DELIVERIES d
ON d.order_id=o.order_id
WHERE d.delivery_status = 'delivered'
),
cte2 AS(
SELECT restaurant_id,restaurant_name,EXTRACT(YEAR FROM ordermonthdate) AS years,EXTRACT(MONTH FROM ordermonthdate) AS months,
COUNT(*) AS current_orders
FROM cte1
GROUP BY 1,2,3,4
)
SELECT * , LAG(current_orders) OVER(PARTITION BY restaurant_id ORDER BY years,months) AS lastmonthsale,
		100.0*(current_orders-LAG(current_orders) OVER(PARTITION BY restaurant_id ORDER BY years,months))/
		LAG(current_orders) OVER(PARTITION BY restaurant_id ORDER BY years,months) AS growthpercentage
FROM cte2



