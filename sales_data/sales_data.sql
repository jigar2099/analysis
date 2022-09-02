-- data inspection
select * from sales_data_sample

--Checking unique values
select distinct status from sales_data_sample  --plot
select distinct year_id from sales_data_sample
select distinct PRODUCTLINE from sales_data_sample --plot
select distinct COUNTRY from sales_data_sample --plot
select distinct DEALSIZE from sales_data_sample --plot
select distinct TERRITORY from sales_data_sample --plot


--- Analysis
-- Different product and revenue
select PRODUCTLINE, sum(SALES) Revenue from sales_data_sample group by PRODUCTLINE order by Revenue desc

-- In which year the company made most sales?
select YEAR_ID, sum(SALES) Revenue from sales_data_sample group by YEAR_ID order by Revenue desc

-- Check how many months they were in operation
select distinct MONTH_ID from sales_data_sample where YEAR_ID=2005
-- in 2k5 company was in operation for fewer months, therefore it's sale was low compare to other years

-- which deal is generating more revenue
select distinct DEALSIZE from sales_data_sample
select DEALSIZE, sum(SALES) Revenue from sales_data_sample group by DEALSIZE order by Revenue desc

-- What was the best month for sales in a specific year(based on revenue only)?
select distinct MONTH_ID from sales_data_sample where YEAR_ID=2005
select distinct MONTH_ID, sum(SALES) Revenue from sales_data_sample where YEAR_ID=2005 group by MONTH_ID 
select distinct MONTH_ID, sum(SALES) Revenue from sales_data_sample where YEAR_ID=2004 group by MONTH_ID
select distinct MONTH_ID, sum(SALES) Revenue from sales_data_sample where YEAR_ID=2003 group by MONTH_ID 

-- What was the best month for sales in a specific year(based on revenue and orders)?
select MONTH_ID, sum(SALES) Revenue, count(ORDERNUMBER) Frequency from sales_data_sample where YEAR_ID=2003 group by MONTH_ID order by Revenue
select MONTH_ID, sum(SALES) Revenue, count(ORDERNUMBER) Frequency from sales_data_sample where YEAR_ID=2004 group by MONTH_ID order by Revenue
-- November is the bese month

-- Now in November month which product do they sell most?
select MONTH_ID, PRODUCTLINE, sum(SALES) Revenue, count(ORDERNUMBER) Frequency from sales_data_sample where YEAR_ID=2004 and MONTH_ID=11
group by MONTH_ID, PRODUCTLINE order by Frequency desc
-- Classic Cars

-- Who is our best customer( best answer with RFM analysis)
-- RFM(Recency-Frequency-Monetary) Analysis
-- 3 metrics
--1.) how long ago their last purchase was
--2.) how often hey purchase
--3.) how much they spent
DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from sales_data_sample) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm


-- What products are most often sold togather?
--select * from sales_data_sample where ORDERNUMBER=10411
select distinct ORDERNUMBER, stuff(
(select ','+ PRODUCTCODE from sales_data_sample  p where ORDERNUMBER in (
	select ORDERNUMBER from(
	select ORDERNUMBER, count(*) rn from sales_data_sample where STATUS='Shipped' group by ORDERNUMBER
	)m where rn=2
) and p.ORDERNUMBER = s.ORDERNUMBER
for xml path ('')),1,1,'') ProductCodes

from sales_data_sample s
order by 2 desc