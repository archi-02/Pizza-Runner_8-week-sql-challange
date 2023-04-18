-- A. Pizza Metrics

-- 1. How many pizzas were ordered ?
SELECT COUNT(*) AS orders
FROM customer_orders
----------------------------------------------------------------------------------------------------------------------

-- 2. How many unique customer orders were made ?
SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders
----------------------------------------------------------------------------------------------------------------------

-- 3. How many successful orders were delivered by each runner ?
SELECT runner_id, COUNT(order_id)
FROM runner_orders
WHERE duration != 'null'
GROUP BY runner_id
ORDER BY runner_id
----------------------------------------------------------------------------------------------------------------------

-- 4. How many of each type of pizza was delivered ?
SELECT pn.pizza_name, COUNT(co.pizza_id) AS pizzas_delivered
FROM runner_orders AS ro
JOIN customer_orders AS co
ON ro.order_id = co.order_id
JOIN pizza_names AS pn
ON co.pizza_id = pn.pizza_id
WHERE duration != 'null'
GROUP BY pizza_name
----------------------------------------------------------------------------------------------------------------------

-- 5. How many Vegetarian and Meatlovers were ordered by each customer ?
SELECT co.customer_id, pn.pizza_name, COUNT(co.pizza_id)
FROM customer_orders AS co
JOIN pizza_names AS pn
ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name
ORDER BY co.customer_id
----------------------------------------------------------------------------------------------------------------------

-- 6. What was the maximum number of pizzas delivered in a single order ?
SELECT co.order_id, COUNT(co.order_id) AS orders
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE distance != 'null'
GROUP BY co.order_id
ORDER BY orders DESC
LIMIT 1
----------------------------------------------------------------------------------------------------------------------

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes ?
WITH cte_1 AS
   (SELECT *, (CASE
               WHEN exclusions = 'null' OR exclusions ='' THEN 'no' ELSE 'yes' END) AS change_1,
	          (CASE
		       WHEN extras = 'null' OR extras IS NULL OR extras = '' THEN 'no' ELSE 'yes' END) AS change_2
    FROM customer_orders AS co
    JOiN runner_orders AS ro
    ON co.order_id=ro.order_id),
cte_2 AS 
   (SELECT *, (CASE 
               WHEN CONCAT(change_1, ' and ', change_2)='no and no' THEN 'no' ELSE 'yes' END) AS change
    FROM cte_1
    WHERE distance != 'null'),
cte_3 AS
   (SELECT customer_id, change, COUNT(pizza_id) AS orders
    FROM cte_2
    GROUP BY customer_id, change
    ORDER BY customer_id)
	
SELECT customer_id, SUM(CASE WHEN change='no' THEN orders ELSE 0 END) AS no_changes,
       SUM(CASE WHEN change='yes' THEN orders ELSE 0 END) AS atleast_1_change
FROM cte_3
GROUP BY customer_id
----------------------------------------------------------------------------------------------------------------------

-- 8. How many pizzas were delivered that had both exclusions and extras?
WITH cte AS
   (SELECT *, (CASE
               WHEN exclusions = 'null' OR exclusions ='' THEN 'no' ELSE 'yes' END) AS change_1,
	          (CASE
		       WHEN extras = 'null' OR extras IS NULL OR extras = '' THEN 'no' ELSE 'yes' END) AS change_2
    FROM customer_orders AS co
    JOIN runner_orders AS ro
    ON co.order_id=ro.order_id
    WHERE distance != 'null')
	
SELECT COUNT(*) AS pizzas_with_exclusion_and_extra
FROM cte
WHERE change_1='yes' AND change_2='yes'
----------------------------------------------------------------------------------------------------------------------

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT  EXTRACT(HOUR FROM order_time) AS hr, COUNT(pizza_id)
FROM customer_orders
GROUP BY hr
ORDER BY hr
----------------------------------------------------------------------------------------------------------------------

-- 10. What was the volume of orders for each day of the week?
SELECT TO_CHAR(order_time,'Day') AS day_of_week, COUNT(pizza_id)
FROM customer_orders
GROUP BY day_of_week
ORDER BY day_of_week