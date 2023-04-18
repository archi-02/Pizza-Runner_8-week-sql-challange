-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH cte AS (
SELECT *, (CASE
           WHEN EXTRACT(DAY FROM registration_date) <= 7 AND EXTRACT(MONTH FROM registration_date) = 1 THEN 'Week_1'
		   WHEN EXTRACT(DAY FROM registration_date) <= 14 AND EXTRACT(MONTH FROM registration_date) = 1 THEN 'Week_2'
		   WHEN EXTRACT(DAY FROM registration_date) <= 21 AND EXTRACT(MONTH FROM registration_date) = 1 THEN 'Week_3'
		   WHEN EXTRACT(DAY FROM registration_date) <= 28 AND EXTRACT(MONTH FROM registration_date) = 1 THEN 'Week_4'
		   ELSE 'Other' END) AS week
FROM runners)

SELECT week, COUNT(registration_date)
FROM cte
GROUP BY week
ORDER BY week
----------------------------------------------------------------------------------------------------------------------

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT runner_id, CONCAT(EXTRACT(MINUTE FROM AVG(time_to_reach_hq)), ' min ', ROUND(EXTRACT(SECOND FROM AVG(time_to_reach_hq))), ' sec') AS avg_time
FROM (SELECT *, (TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') - order_time) AS time_to_reach_hq
      FROM customer_orders AS co
      JOIN runner_orders AS ro
      ON co.order_id = ro.order_id
      WHERE pickup_time != 'null') AS sub_q
GROUP BY runner_id
ORDER BY runner_id
----------------------------------------------------------------------------------------------------------------------

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH cte AS (
SELECT co.order_id, COUNT(co.order_id) AS no_of_pizzas, AVG(TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') - order_time) AS prep_time
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE pickup_time != 'null'
GROUP BY co.order_id)

SELECT no_of_pizzas, CONCAT(EXTRACT(MINUTE FROM AVG(prep_time)), ' min ', ROUND(EXTRACT(SECOND FROM AVG(prep_time))), ' sec') AS avg_prep_time
FROM cte
GROUP BY no_of_pizzas
ORDER BY no_of_pizzas
----------------------------------------------------------------------------------------------------------------------

-- 4. What was the average distance travelled for each customer?
WITH cte AS (
SELECT *, CAST((CASE 
                WHEN distance LIKE '%km' THEN SUBSTRING(distance, 1,LENGTH(distance)-2)
		        ELSE distance END) AS DECIMAL)  AS dist_num
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE pickup_time != 'null')

SELECT customer_id, CONCAT(ROUND(AVG(dist_num),1), ' km') AS avg_dist
FROM cte
GROUP BY customer_id
ORDER BY customer_id
----------------------------------------------------------------------------------------------------------------------

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT CONCAT(MAX(delivery_time)-MIN(delivery_time),' mins') AS time_diff
FROM (SELECT *, CAST(SUBSTRING(duration,1,2) AS INTEGER) AS delivery_time
      FROM customer_orders AS co
      JOIN runner_orders AS ro
      ON co.order_id = ro.order_id
      WHERE pickup_time != 'null') AS sub_q
----------------------------------------------------------------------------------------------------------------------
	  
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH cte AS(
SELECT co.order_id, co.customer_id, co.pizza_id, ro.runner_id,
	   CAST((CASE 
             WHEN distance LIKE '%km' THEN SUBSTRING(distance, 1,LENGTH(distance)-2)
			 ELSE distance END) AS DECIMAL)*1000 AS dist_num_mtr,
       CAST(SUBSTRING(duration,1,2) AS INTEGER)*60 AS delivery_time_num_sec
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE pickup_time != 'null')

SELECT runner_id, order_id, CONCAT(ROUND(AVG(dist_num_mtr/delivery_time_num_sec),2), ' m/s') AS avg_speed
FROM cte
GROUP BY runner_id, order_id
ORDER BY runner_id, order_id
----------------------------------------------------------------------------------------------------------------------

-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id, CONCAT(ROUND(AVG(CASE WHEN cancellation LIKE '%Cancellation' THEN 0 ELSE 1 END)*100), ' %') AS success_percent
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
GROUP BY runner_id