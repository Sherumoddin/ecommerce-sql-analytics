create database E_Commerce_Analytics

use E_Commerce_Analytics

--Q1: Display all records from the Customers table.
select * from customers;

--Q2: Display only customer_name and city from Customers
select customer_name, city from customers;

--Q3: Find all unique cities where customers live.
select distinct(city) as Unique_Cities from customers;

--Q4: Display all products whose unit_price is greater than 3,000.
select * from products where unit_price > 3000;

--Q5: Find all orders with order_status = 'Delivered'.
select * from orders where order_status = 'Delivered';

--Q6: Display products in descending order of unit_price.
select * from products order by unit_price desc;

--Q7: Show the top 5 most expensive products.
select top 5 * from products order by unit_cost desc;

--Q8: Count the total number of customers.
select count(customer_id) as Total_Customers from customers;

--Q9: Count the total number of orders in each order_status.
select order_status, count(order_status) as Total_Orders from orders
group by order_status;

--Q10: Find the average unit_price of all products.
select product_name, avg(unit_price) as AVG_Unit_Price from products
group by product_name;

--Q11: Find the total quantity sold for each product_id using OrderItems.
select product_id, sum(quantity) as Total_Quantity from order_items
group by product_id;

--Q12: Display order_id, customer_name and order_date using a JOIN.
select o.order_id, c.customer_name, o.order_date from orders o 
join customers c
on c.customer_id=o.customer_id;

--Q13: Find total revenue for each product using quantity × unit_price. Ignore discounts for this question.
select p.product_name,sum(io.quantity * io.unit_price) as Total_Revenue
from order_items io
join products p
on io.product_id=p.product_id
group by product_name
order by Total_Revenue desc;

--Q14: Find customers who live in Bengaluru or Hyderabad.
select customer_name from customers where city in ('Bengaluru','Hydearabad');

--Q15: Find orders placed during 2025.
select * from orders where YEAR(order_date) = 2025; 

--Q16: Find the number of orders placed by each customer. Include customer_id and order count.
SELECT c.customer_id,
       c.customer_name,
       COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY order_count DESC;

--Q17: Calculate discounted revenue for Delivered orders using quantity × unit_price × (1 - discount_pct).
SELECT SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS discounted_revenue
FROM orders o
JOIN order_items oi
  ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered';

--Q18: Find the top 5 products by delivered revenue. Show product name and revenue.
SELECT TOP 5
       p.product_name,
       SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC;

--Q19: Calculate monthly delivered revenue, sorted by year and month.
SELECT YEAR(o.order_date)  AS order_year,
       MONTH(o.order_date) AS order_month,
       SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS monthly_revenue
FROM orders o
JOIN order_items oi
  ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY order_year, order_month;

--Q20: Find customers whose delivered order count is greater than 1 using GROUP BY and HAVING.
SELECT o.customer_id,
       c.customer_name,
       COUNT(o.order_id) AS delivered_order_count
FROM orders o
JOIN customers c
  ON o.customer_id = c.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY o.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 1
ORDER BY delivered_order_count DESC;

--Q21: Rank products by revenue within each category using DENSE_RANK().
WITH product_revenue AS (
    SELECT p.category,
           p.product_id,
           p.product_name,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o   ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.category, p.product_id, p.product_name
)
SELECT category,
       product_name,
       revenue,
       DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
FROM product_revenue
ORDER BY category, revenue_rank;

--Q22: Calculate a running total of monthly delivered revenue using a window function.
WITH monthly AS (
    SELECT YEAR(o.order_date)  AS order_year,
           MONTH(o.order_date) AS order_month,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS monthly_revenue
    FROM orders o
    JOIN order_items oi
      ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
)
SELECT order_year,
       order_month,
       monthly_revenue,
       SUM(monthly_revenue) OVER (
           ORDER BY order_year, order_month
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM monthly
ORDER BY order_year, order_month;

--Q23: Find products that have never appeared in a Delivered order.
SELECT
    p.product_id,
    p.product_name
FROM Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    INNER JOIN Orders o
        ON oi.order_id = o.order_id
    WHERE oi.product_id = p.product_id
      AND o.order_status = 'Delivered'
);

--Q24: Create a view named vw_DeliveredSales containing delivered order details and calculated line revenue.
CREATE VIEW vw_DeliveredSales AS
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_id,
    c.customer_name,
    p.product_id,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    oi.quantity * oi.unit_price * (1 - oi.discount_pct) AS line_revenue
FROM Orders o
INNER JOIN Customers c
    ON o.customer_id = c.customer_id
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
INNER JOIN Products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered';
GO

SELECT *
FROM vw_DeliveredSales;

SELECT TOP 10 *
FROM vw_DeliveredSales;