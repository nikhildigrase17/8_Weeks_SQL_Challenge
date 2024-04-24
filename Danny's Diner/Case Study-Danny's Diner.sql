/*
Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

sales
menu
members
*/

USE DEMODATABASE;

CREATE OR REPLACE TABLE SALES(
CUSTOMER_ID VARCHAR(1),
ORDER_DATE DATE,
PRODUCT_ID INT
);

INSERT INTO SALES
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

CREATE OR REPLACE TABLE MENU(
PRODUCT_ID INT,
PRODUCT_NAME VARCHAR(5),
PRICE INT
);

INSERT INTO MENU
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

CREATE OR REPLACE TABLE MEMBERS(
CUSTOMER_ID VARCHAR(1),
JOIN_DATE DATE
);

INSERT INTO MEMBERS
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

---- Case Study Questions ----

-- 1.What is the total amount each customer spent at the restaurant?

SELECT S.CUSTOMER_ID,
SUM(M.PRICE) AS TOTAL_AMOUNT
FROM SALES AS S
JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY 1;

-- 2.How many days has each customer visited the restaurant?

SELECT CUSTOMER_ID,
COUNT(DISTINCT ORDER_DATE) AS DAYS_VISITED
FROM SALES
GROUP BY 1;

-- 3.What was the first item from the menu purchased by each customer?

SELECT S.CUSTOMER_ID,
 M.PRODUCT_NAME,
 FIRST_VALUE(M.PRODUCT_NAME) OVER(PARTITION BY S.CUSTOMER_ID ORDER BY MIN(S.ORDER_DATE)) AS A
 FROM SALES S
 JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
 GROUP BY 1,2
 ORDER BY 1;

 -- ANOTHER WAY
 
 SELECT S.CUSTOMER_ID,
 M.PRODUCT_NAME
 FROM SALES S
 JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
 WHERE S.ORDER_DATE IN (SELECT MIN(ORDER_DATE)
 FROM SALES
 GROUP BY CUSTOMER_ID);

 -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT S.CUSTOMER_ID,
M.PRODUCT_NAME,
COUNT(S.PRODUCT_ID) AS MOST_PURCHASED
FROM SALES S
JOIN MENU M USING(PRODUCT_ID)
GROUP BY 1,2
ORDER BY MOST_PURCHASED DESC
LIMIT 1;

 -- 5.Which item was the most popular for each customer?

WITH MOST_POPULAR AS(
    SELECT
    S.CUSTOMER_ID,
    M.PRODUCT_NAME,
    COUNT(S.ORDER_DATE) AS ORDERS,
    DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDERS DESC) AS RNK,
    ROW_NUMBER() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDERS DESC) AS RO,
    FROM SALES S
    JOIN MENU M USING(PRODUCT_ID)
    GROUP BY 1,2)

SELECT CUSTOMER_ID,
PRODUCT_NAME
FROM MOST_POPULAR
WHERE RNK =1;

-- 6.Which item was purchased first by the customer after they became a member?

WITH AFTER_JOIN AS(
SELECT S.*,
M.PRODUCT_NAME,
DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE) AS FIRST
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MM USING(CUSTOMER_ID)
WHERE S.ORDER_DATE >= MM.JOIN_DATE)

SELECT CUSTOMER_ID,
PRODUCT_NAME
FROM AFTER_JOIN
WHERE FIRST = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH BEFORE_JOIN AS(
SELECT S.*,
M.PRODUCT_NAME,
DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE) AS FIRST
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MM USING(CUSTOMER_ID)
WHERE S.ORDER_DATE < MM.JOIN_DATE)

SELECT CUSTOMER_ID,
PRODUCT_NAME
FROM BEFORE_JOIN
WHERE FIRST = 1;

-- 8.What is the total items and amount spent for each member before they became a member?

SELECT S.CUSTOMER_ID,
COUNT(S.PRODUCT_ID) AS TOTAL_ITEMS,
SUM(M.PRICE) AS AMOUNT_SPENT
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MM ON S.CUSTOMER_ID = MM.CUSTOMER_ID
WHERE S.ORDER_DATE < MM.JOIN_DATE
GROUP BY 1;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT CUSTOMER_ID,
SUM(CASE 
WHEN PRODUCT_NAME = 'sushi' THEN PRICE * 10 * 2
ELSE PRICE * 10
END) AS POINTS
FROM MENU M
JOIN SALES S ON M.PRODUCT_ID = S.PRODUCT_ID
GROUP BY 1;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT S.CUSTOMER_ID,
SUM(CASE WHEN ORDER_DATE BETWEEN MM.JOIN_DATE AND DATEADD("DAY",6,MM.JOIN_DATE)
    THEN PRICE * 10 * 2 ELSE PRICE * 10 END) AS POINTS
FROM MENU M
JOIN SALES S ON M.PRODUCT_ID = S.PRODUCT_ID
JOIN MEMBERS MM ON MM.CUSTOMER_ID = S.CUSTOMER_ID
WHERE DATE_TRUNC('MONTH',ORDER_DATE) = '2021-01-01'
GROUP BY 1;
