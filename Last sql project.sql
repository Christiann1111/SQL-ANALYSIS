USE gdb023;
#1
SELECT * FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC"
;




#2
SELECT P1 AS product_count_2020 , P2 AS product_count_2021,  ((P2 - P1) / P1)*100 AS  percentage_chng FROM 
(
(SELECT COUNT(DISTINCT(product_code)) AS P1 FROM  fact_sales_monthly
WHERE fiscal_year = 2020) AS table1 ,
(SELECT COUNT(DISTINCT(product_code)) AS P2 FROM  fact_sales_monthly
WHERE fiscal_year = 2021)AS table2
);


#3

SELECT COUNT(product_code) AS product_count ,segment FROM dim_product
GROUP BY segment
;
#4
WITH table_segment1 AS
(SELECT segment,COUNT(DISTINCT(dp.product_code)) AS P1 FROM dim_product AS dp
JOIN fact_sales_monthly AS fsm
ON dp.product_code = fsm.product_code
WHERE fiscal_year = 2020
GROUP BY dp.segment
) 
, table_segment2 AS
(SELECT segment,COUNT(DISTINCT(dp.product_code)) AS P2 FROM dim_product AS dp
JOIN fact_sales_monthly AS fsm
ON dp.product_code = fsm.product_code
WHERE fiscal_year = 2021
GROUP BY dp.segment) 

SELECT tb1.segment, P1 AS product_count_2020, P2 AS product_count_2021, (P2-P1) AS difference FROM table_segment1 AS tb1

JOIN table_segment2 AS tb2
ON tb1.segment = tb2.segment
;


#5 

SELECT dm.product_code, product, manufacturing_cost FROM dim_product AS dm
JOIN fact_manufacturing_cost AS fmc
ON fmc.product_code = dm.product_code
WHERE manufacturing_cost IN (
	(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost),
    (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
    )
ORDER BY manufacturing_cost DESC
;


#6
SELECT dc.customer_code,customer,AVG(pre_invoice_discount_pct) AS average_invoice_discount  FROM dim_customer AS dc
JOIN fact_pre_invoice_deductions AS fp
ON dc.customer_code = fp.customer_code
WHERE  market = "India" AND fiscal_year = 2021
GROUP BY customer, dc.customer_code
ORDER BY average_invoice_discount DESC
LIMIT 5;




#7
SELECT SUM(sold_quantity * gross_price) AS Gross_Sales_Amount, YEAR(fs.date) AS Year, month(fs.date) AS Month FROM fact_sales_monthly AS fs
JOIN dim_customer AS dc
ON fs.customer_code = dc.customer_code
JOIN fact_gross_price AS fg
ON fs.product_code = fg.product_code
WHERE customer = "Atliq Exclusive"
GROUP BY customer, YEAR(fs.date) , month(fs.date)
;

#8 

SELECT CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 2
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 3
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 4
    END AS Quarters,SUM(sold_quantity) AS sold_quantity FROM fact_sales_monthly AS fs
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY sold_quantity Desc;

#9

SELECT channel, gross_sales_mln, CONCAT((ROUND(gross_sales_mln/(SUM(gross_sales_mln) OVER(PARTITION BY fiscal_year)),2))*100,"%") AS percentage FROM (

SELECT channel,SUM(sold_quantity * gross_price) AS gross_sales_mln, fs.fiscal_year FROM dim_customer AS dc
JOIN fact_sales_monthly  AS fs
ON dc.customer_code = fs.customer_code
JOIN fact_gross_price AS fg
ON fs.product_code = fg.product_code
WHERE fs.fiscal_year = 2021
GROUP BY channel) AS gross_sales_channel
GROUP BY channel;


#10
SELECT * FROM 
(SELECT division,sub.product_code,sub.product,sub.total_sold_quantity,
ROW_NUMBER() OVER(PARTITION BY division ORDER BY sub.total_sold_quantity DESC) rank_
FROM
(
SELECT dp.product_code,product,sum(sold_quantity)AS total_sold_quantity FROM dim_product AS dp
JOIN fact_sales_monthly AS fs
ON dp.product_code= fs.product_code
WHERE fiscal_year = 2021
group by dp.product_code,product
) sub

JOIN dim_product AS dp
ON sub.product_code = dp.product_code) AS sub2

WHERE rank_ <=3
;