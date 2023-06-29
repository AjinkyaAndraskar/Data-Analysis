

-- Problem statement 1 : What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_amount_spend
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


-- problem Statement 2 : How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS no_of_days
FROM sales
GROUP BY customer_id;

-- problem statement 3 : What was the first item from the menu purchased by each customer?

SELECT customer_id, order_date, STUFF((SELECT ', ' + product_name
                                      FROM (SELECT s.customer_id, s.order_date, m.product_name,
                                                   DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
                                            FROM sales s
                                            JOIN menu m ON s.product_id = m.product_id) b
                                      WHERE a.customer_id = b.customer_id AND b.rnk = 1
                                      FOR XML PATH ('')), 1, 2, '') AS first_order
FROM (SELECT s.customer_id, s.order_date, m.product_name,
             DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
      FROM sales s
      JOIN menu m ON s.product_id = m.product_id) a
WHERE a.rnk = 1
GROUP BY customer_id, order_date;

-- Problem Statement 4 : What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH most_purchased_products AS (
  SELECT TOP 1 product_id, COUNT(1) AS most_purchased
  FROM sales
  GROUP BY product_id
  ORDER BY most_purchased DESC
)
SELECT m.product_name, s.most_purchased
FROM most_purchased_products s
JOIN menu m ON s.product_id = m.product_id;


 
 -- Problem Statement 5 : Which item was the most popular for each customer?
 
WITH cte_FavItem AS (
     SELECT s.customer_id, m.product_name, COUNT(s.product_id) AS fav_count, 
     DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rnk 
     FROM sales s 
     JOIN menu m 
     ON s.product_id = m.product_id
     GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, STUFF((
    SELECT DISTINCT ', ' + product_name
    FROM cte_FavItem
    WHERE customer_id = c.customer_id AND rnk = 1
    FOR XML PATH('')), 1, 2, '') AS fav_Items
FROM cte_FavItem c
GROUP BY customer_id;


 
 -- Problem Statement 6 : Which item was purchased first by the customer after they became a member?
 
;WITH cte_member_sales AS (
    SELECT s.customer_id, s.order_date, s.product_id,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
    FROM sales s 
    JOIN members mem 
    ON s.customer_id = mem.customer_id 
    WHERE s.order_date >= mem.join_date
) 
    
SELECT c.customer_id, c.order_date, m.product_name
FROM cte_member_sales c
JOIN menu m 
ON c.product_id = m.product_id
WHERE rnk = 1
ORDER BY c.customer_id;

-- Problem Statement 7 : Which item was purchased just before the customer became a member? 

WITH cte_member_sales AS (
    SELECT s.customer_id, s.order_date, s.product_id,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
    FROM sales s 
    JOIN members mem 
    ON s.customer_id = mem.customer_id 
    WHERE s.order_date < mem.join_date
) 
    
SELECT c.customer_id, c.order_date, STRING_AGG(m.product_name, ',') AS products
FROM cte_member_sales c
JOIN menu m 
ON c.product_id = m.product_id
WHERE rnk = 1
GROUP BY c.customer_id, c.order_date
ORDER BY c.customer_id;



-- Problem Statement 8 : What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS total_items, SUM(m.price) AS total_price
FROM sales s  
JOIN menu m 
ON s.product_id = m.product_id 
JOIN members mem 
ON s.customer_id = mem.customer_id 
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;


-- Problem Statement 9 : If each $1 spent equates to 10 points and sushi has a 2x points multiplier how many points would each customer have?

WITH cte_points AS (
    SELECT *,
        CASE WHEN product_id = 1 THEN price * 20
            ELSE price * 10
        END AS points
    FROM menu
)
SELECT s.customer_id, SUM(c.points) AS total_points
FROM cte_points c
JOIN sales s ON s.product_id = c.product_id
GROUP BY s.customer_id;


-- Bonus Question : Join all the things 

SELECT s.customer_id, s.order_date, m.product_name, m.price,
    CASE
        WHEN s.order_date >= mem.join_date THEN 'Y'
        WHEN s.order_date < mem.join_date THEN 'N'
        ELSE 'N'
    END AS member
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON s.customer_id = mem.customer_id;


-- Bonus Question : Rank all the things 

WITH cte_bonus AS (
    SELECT s.customer_id, s.order_date, m.product_name, m.price,
        CASE
            WHEN s.order_date >= mem.join_date THEN 'Y'
            WHEN s.order_date < mem.join_date THEN 'N'
            ELSE 'N'
        END AS member
    FROM sales s
    LEFT JOIN menu m ON s.product_id = m.product_id
    LEFT JOIN members mem ON s.customer_id = mem.customer_id
)
SELECT *,
    CASE
        WHEN member = 'Y' THEN CAST(DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) AS varchar(10))
        ELSE NULL
    END AS ranking
FROM cte_bonus;

