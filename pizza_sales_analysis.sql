CREATE DATABASE pizza_sales;
USE pizza_sales;

CREATE TABLE pizza_types(
    pizza_type_id VARCHAR(30) NOT NULL PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    category VARCHAR(20) NOT NULL,
    ingredients VARCHAR(100) NOT NULL
);

CREATE TABLE pizzas(
     pizza_id VARCHAR(20) NOT NULL PRIMARY KEY,
     pizza_type_id VARCHAR(30) NOT NULL,
     size VARCHAR(5) NOT NULL,
     price DOUBLE NOT NULL,
     FOREIGN KEY (pizza_type_id) REFERENCES pizza_types(pizza_type_id)
);

CREATE TABLE orders(
order_id INT NOT NULL PRIMARY KEY,
order_date DATE NOT NULL,
order_time TIME NOT NULL
);


CREATE TABLE order_details(
   order_details_id INT NOT NULL PRIMARY KEY,
   order_id INT NOT NULL,
   pizza_id VARCHAR(50) NOT NULL,
   quantity INT NOT NULL,
   FOREIGN KEY (order_id) REFERENCES orders(order_id),
   FOREIGN KEY (pizza_id) REFERENCES pizzas(pizza_id)
);
SELECT * FROM order_details;
#Question set 1
#Retrieve the total number of orders placed.
SELECT COUNT(order_id) AS total_number_of_orders FROM orders;

#Calculate the total revenue generated from pizza sales.
SELECT ROUND(SUM(p.price*od.quantity),2) AS total_revenue
FROM pizzas p
JOIN order_details od ON od.pizza_id = p.pizza_id;

#Identify the highest-priced pizza.
SELECT pt.name, p.price AS highest_price 
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
ORDER BY highest_price DESC LIMIT 1;

#Identify the most common pizza size ordered.
SELECT p.size, COUNT(od.order_details_id) AS order_count
FROM pizzas p 
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.size ORDER BY order_count DESC LIMIT 1;

#List the top 5 most ordered pizza types along with their quantities.
SELECT pt.name, SUM(od.quantity) AS total_quantity
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY total_quantity DESC LIMIT 5;

#Question set 2
#Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT pt.category, SUM(od.quantity) AS total_quantity
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.category
ORDER BY total_quantity DESC ;

#Determine the distribution of orders by hour of the day.
SELECT HOUR(order_time) AS hour, COUNT(order_id) AS order_count
FROM orders GROUP BY HOUR;

#Join relevant tables to find the category-wise distribution of pizzas.
SELECT category, COUNT(name) AS num_of_pizzas FROM pizza_types
GROUP BY category;

#Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT ROUND(AVG(total_quantity),2) AS average_quantity FROM 
(SELECT o.order_date, SUM(od.quantity) AS total_quantity
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_date) AS order_quantity;

#Determine the top 3 most ordered pizza types based on revenue.
SELECT pt.name, ROUND(SUM(p.price*od.quantity),2) AS total_revenue
FROM pizzas p
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY total_revenue DESC LIMIT 3;

#Question set 3
#Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
  pt.category, ROUND(
    (SUM(p.price * od.quantity) / 
     (SELECT SUM(p2.price * od2.quantity)
      FROM pizzas p2
      JOIN order_details od2 ON od2.pizza_id = p2.pizza_id)
    ) * 100, 2) AS revenue_percentage
FROM pizzas p
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.category
ORDER BY revenue_percentage DESC;

#Analyze the cumulative revenue generated over time.
SELECT order_date, SUM(revenue) over(order by order_date) AS cum_revenue
FROM
(SELECT order_date, SUM(p.price * od.quantity) AS revenue
FROM pizzas p
JOIN order_details od ON od.pizza_id = p.pizza_id
JOIN orders o ON o.order_id = od.order_id
GROUP BY order_date) AS sales;

#Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT category, name, revenue
FROM (
    SELECT pt.category, pt.name, 
           ROUND(SUM(p.price * od.quantity), 2) AS revenue,
           RANK() OVER (PARTITION BY pt.category ORDER BY SUM(p.price * od.quantity) DESC) AS rn
    FROM pizzas p
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    JOIN order_details od ON od.pizza_id = p.pizza_id
    GROUP BY pt.category, pt.name
) AS ranked
WHERE rn <= 3
ORDER BY category, revenue DESC;
