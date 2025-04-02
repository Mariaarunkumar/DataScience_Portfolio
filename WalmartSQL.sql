-- Create database
CREATE DATABASE IF NOT EXISTS walmartSales;

-- Create table
DROP TABLE IF EXISTS sales;  -- Optional: Removes the table if it already exists

CREATE TABLE IF NOT EXISTS sales (
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT NOT NULL,
    total DECIMAL(12,4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT,
    gross_income DECIMAL(12,4),
    rating FLOAT
);

SELECT * FROM sales;

-- Generic Questions

-- How many unique cities does the data have?
SELECT DISTINCT city FROM sales;
-- 3 unique cities in this dataset

-- In which city is each branch?
SELECT DISTINCT branch, city FROM sales;

-- Product Analysis

-- How many unique product lines does the data have?
SELECT DISTINCT product_line FROM sales;
-- 6 unique product lines

-- What is the most common payment method?
SELECT payment, COUNT(payment) AS cnt_pay 
FROM sales 
GROUP BY payment 
ORDER BY cnt_pay DESC;
-- Cash is the most common method of payment

-- What is the most selling product line?
SELECT product_line, SUM(quantity) AS popularity
FROM sales
GROUP BY product_line
ORDER BY popularity DESC;
-- Electronic Accessories is the most popular product line

-- What is the total revenue by branch?
SELECT branch, SUM(quantity * unit_price) AS revenue
FROM sales
GROUP BY branch;

-- What is the most common product line by gender?
WITH ProductSales AS (
    SELECT gender, product_line, SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY gender, product_line
),
RankedSales AS (
    SELECT *, 
           RANK() OVER (PARTITION BY gender ORDER BY total_quantity DESC) AS rnk
    FROM ProductSales
)
SELECT gender, product_line, total_quantity
FROM RankedSales
WHERE rnk = 1;

-- What is the average rating of each product line?
SELECT product_line, AVG(rating) AS avg_rating
FROM sales
GROUP BY product_line;

-- Number of products sold each day
SELECT 
    DAYNAME(date) AS day_of_week, 
    SUM(quantity) AS total_quantity
FROM sales
GROUP BY day_of_week
ORDER BY CASE 
    WHEN day_of_week = 'Sunday' THEN 1  
    WHEN day_of_week = 'Monday' THEN 2  
    WHEN day_of_week = 'Tuesday' THEN 3  
    WHEN day_of_week = 'Wednesday' THEN 4  
    WHEN day_of_week = 'Thursday' THEN 5  
    WHEN day_of_week = 'Friday' THEN 6  
    WHEN day_of_week = 'Saturday' THEN 7  
END;

-- Which customer type brings the most revenue?
SELECT customer_type, SUM(total) AS revenue
FROM sales
GROUP BY customer_type
ORDER BY revenue DESC
LIMIT 1;

-- What is the most common customer type?
SELECT customer_type, COUNT(customer_type) AS cnt
FROM sales
GROUP BY customer_type
ORDER BY cnt DESC
LIMIT 1;

-- What is the gender distribution per branch?
SELECT branch, gender, COUNT(gender) AS gender_count
FROM sales
GROUP BY branch, gender
ORDER BY branch;

-- Ratings Analysis

-- Which time of the day do customers give the most ratings?
SELECT 
    SUM(rating) AS total_rating, 
    CASE 
        WHEN time >= '00:00:00' AND time < '12:00:00' THEN 'Morning'
        WHEN time >= '12:00:00' AND time < '17:00:00' THEN 'Afternoon'
        ELSE 'Evening' 
    END AS tod
FROM sales
GROUP BY tod
ORDER BY total_rating DESC
LIMIT 1;

-- Which time of the day do customers give the most ratings per branch?
SELECT * 
FROM (
    SELECT 
        branch,
        CASE 
            WHEN time >= '00:00:00' AND time < '12:00:00' THEN 'Morning'
            WHEN time >= '12:00:00' AND time < '17:00:00' THEN 'Afternoon'
            ELSE 'Evening' 
        END AS tod, 
        SUM(rating) AS total_rating, 
        RANK() OVER (PARTITION BY branch ORDER BY SUM(rating) DESC) AS rnk
    FROM sales
    GROUP BY branch, tod
) AS ranked_ratings
WHERE rnk = 1;

-- Which day of the week has the best average rating?
SELECT DAYNAME(date) AS day_of_week, AVG(rating) AS avg_rating
FROM sales
GROUP BY day_of_week
ORDER BY avg_rating DESC
LIMIT 1;

-- Which day of the week has the best average ratings per branch?
SELECT * 
FROM (
    SELECT 
        branch, 
        DAYNAME(date) AS day_of_week, 
        AVG(rating) AS avg_rating, 
        RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rnk
    FROM sales
    GROUP BY branch, day_of_week
) AS ranked_days
WHERE rnk = 1;
