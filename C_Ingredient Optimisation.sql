-- C. Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?
WITH cte AS (
SELECT pizza_id, CAST(UNNEST(string_to_array(toppings, ',')) AS INTEGER) AS topping_id
FROM pizza_recipes)

SELECT pt.topping_name
FROM cte AS c
JOIN pizza_toppings AS pt
ON c.topping_id=pt.topping_id
GROUP BY pt.topping_name
HAVING COUNT(pt.topping_id)=2
----------------------------------------------------------------------------------------------------------------------

-- 2. What was the most commonly added extra?
WITH cte AS (
SELECT pizza_id, CAST(UNNEST(string_to_array(extras, ',')) AS INTEGER) AS topping_id
FROM customer_orders AS co
WHERE extras !='null' AND extras IS NOT NULL AND extras!='')

SELECT pt.topping_name
FROM cte AS c
JOIN pizza_toppings AS pt
ON c.topping_id=pt.topping_id
GROUP BY topping_name
ORDER BY COUNT(pt.topping_id) DESC
LIMIT 1
----------------------------------------------------------------------------------------------------------------------

-- 3. What was the most common exclusion?
WITH cte AS (
SELECT pizza_id, CAST(UNNEST(string_to_array(exclusions, ',')) AS INTEGER) AS topping_id
FROM customer_orders AS co
WHERE exclusions !='null' AND exclusions IS NOT NULL AND exclusions!='')

SELECT pt.topping_name
FROM cte AS c
JOIN pizza_toppings AS pt
ON c.topping_id=pt.topping_id
GROUP BY topping_name
ORDER BY COUNT(pt.topping_id) DESC
LIMIT 1
----------------------------------------------------------------------------------------------------------------------

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
/* Meat Lovers
   Meat Lovers - Exclude Beef
   Meat Lovers - Extra Bacon
   Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */
WITH extra AS (
SELECT c.order_id, c.pizza_id, 'Extra ' || STRING_AGG(DISTINCT pt.topping_name, ', ') AS excluded
FROM (SELECT order_id, pizza_id, CAST(UNNEST(string_to_array(exclusions, ',')) AS INTEGER) AS topping_id
      FROM customer_orders AS co
      WHERE exclusions !='null' AND exclusions IS NOT NULL AND exclusions!='') AS c
JOIN pizza_toppings AS pt
ON c.topping_id=pt.topping_id
GROUP BY c.order_id, c.pizza_id),
excluded AS (
SELECT c.order_id, c.pizza_id, 'Exclude ' || STRING_AGG(DISTINCT pt.topping_name, ', ') AS extra
FROM (SELECT order_id, pizza_id, CAST(UNNEST(string_to_array(extras, ',')) AS INTEGER) AS topping_id
      FROM customer_orders AS co
      WHERE extras !='null' AND extras IS NOT NULL AND extras!='') AS c
JOIN pizza_toppings AS pt
ON c.topping_id=pt.topping_id
GROUP BY c.order_id, c.pizza_id)

SELECT order_id, final
FROM 
(SELECT co.order_id, excluded, extra, 
SUBSTRING(pizza_name, 1, 4) || ' ' || SUBSTRING(pizza_name, 5, 10) || ' - ' || COALESCE(excluded, '') || ' ' || COALESCE(extra, '') AS final
FROM customer_orders AS co
LEFT JOIN extra AS a
ON co.order_id=a.order_id AND co.pizza_id=a.pizza_id
LEFT JOIN excluded AS b
ON co.order_id=b.order_id AND co.pizza_id=b.pizza_id
JOIN pizza_names AS pn
ON co.pizza_id=pn.pizza_id
WHERE pizza_name='Meatlovers') AS sub_q
GROUP BY final, order_id
HAVING final != 'Meat lovers -  '
----------------------------------------------------------------------------------------------------------------------

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
/* For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" */
-- To be continued
----------------------------------------------------------------------------------------------------------------------

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
-- To be continued