-- D. Pricing and Ratings
/* 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
how much money has Pizza Runner made so far if there are no delivery fees? */
WITH cte AS (
SELECT *, (CASE
           WHEN pn.pizza_name = 'Meatlovers' THEN 12
		   ELSE 10 END) AS price
FROM customer_orders AS co
JOIN pizza_names AS pn
ON co.pizza_id = pn.pizza_id
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE distance != 'null')

SELECT CONCAT('$ ', SUM(price)) AS revenue
FROM cte
---------------------------------------------------------------------------------------------------------------------

-- 2. What if there was an additional $1 charge for any pizza extras?
/* Add cheese is $1 extra */
WITH cte_1 AS (
SELECT co.order_id, co.customer_id, co.pizza_id, co.exclusions, co.extras, ro.runner_id, ro.distance, 
	   UNNEST(string_to_array(co.extras, ',')) AS extra_topping_id, 1 AS extra_charge
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE distance != 'null' AND (extras!='null' AND extras!='' AND extras IS NOT NULL)),
cte_2 AS (
SELECT order_id, customer_id, pizza_id, extras, runner_id, SUM(extra_charge) AS charge
FROM cte_1
GROUP BY customer_id, order_id, runner_id, pizza_id, extras
UNION ALL
SELECT co.order_id, co.customer_id, co.pizza_id, co.extras, ro.runner_id, 0 AS extra_charge
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE distance != 'null' AND (extras='null' OR extras='' OR extras IS NULL))

SELECT SUM((CASE WHEN pizza_name='Meatlovers' THEN 12 ELSE 10 END)+charge) AS price
FROM cte_2 AS c_2
JOIN pizza_names AS pn
ON c_2.pizza_id=pn.pizza_id
---------------------------------------------------------------------------------------------------------------------

/* 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their 
runner, how would you design an additional table for this new dataset - generate a schema for this new table 
and insert your own data for ratings for each successful customer order between 1 to 5. */
DROP TABLE IF EXISTS runner_rating;
CREATE TABLE runner_rating (
    "start_delivery_duration" INTEGER,
	"end_delivery_duration" INTEGER,
	"rating" INTEGER
);

INSERT INTO runner_rating
("start_delivery_duration", "end_delivery_duration", "rating")
VALUES
('1', '10', '5'),
('11', '20', '4'),
('21', '30', '3'),
('31', '40', '2'),
('41', '50', '1')
---------------------------------------------------------------------------------------------------------------------

/* 4. Using your newly generated table - can you join all of the information together to form a table which has the 
following information for successful deliveries?
   customer_id
   order_id
   runner_id
   rating
   order_time
   pickup_time
   Time between order and pickup
   Delivery duration
   Average speed
   Total number of pizzas */
SELECT DISTINCT co.order_id, co.customer_id, ro.runner_id, co.order_time, ro.pickup_time, 
      (TO_TIMESTAMP(ro.pickup_time, 'YYYY-MM-DD HH24:MI:SS') - co.order_time) AS time_tetween_pickup_and_order, 
       SUBSTRING(ro.duration,1,2) || ' mins' AS delivery_duration, 
       ROUND(CAST((CASE 
             WHEN distance LIKE '%km' THEN SUBSTRING(distance, 1,LENGTH(distance)-2)
			 ELSE distance END) AS DECIMAL)*1000 /
	         CAST(SUBSTRING(duration,1,2) AS INTEGER)*60) || ' m/s' AS avg_speed,
       COUNT(co.order_id)OVER(PARTITION BY co.customer_id, co.order_id, ro.runner_id)
FROM runner_orders AS ro
JOIN customer_orders AS co
ON ro.order_id=co.order_id
WHERE duration!='null'
---------------------------------------------------------------------------------------------------------------------

/*  5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is
paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries? */
WITH cte AS (
SELECT co.order_id,  SUM(CASE WHEN pizza_name='Meatlovers' THEN 12 ELSE 10 END) AS price, CAST((CASE 
             WHEN ro.distance LIKE '%km' THEN SUBSTRING(distance, 1,LENGTH(distance)-2) 
			 ELSE ro.distance END) AS DECIMAL)*0.30 AS dist_cost_per_km
FROM customer_orders AS co
JOIN runner_orders AS ro
ON co.order_id=ro.order_id
JOIN pizza_names AS pn
ON co.pizza_id=pn.pizza_id
WHERE distance!='null'
GROUP BY co.order_id, co.customer_id, co.order_time, ro.distance)

SELECT '$ ' || ROUND(SUM(price-dist_cost_per_km),1) AS left_over
FROM cte