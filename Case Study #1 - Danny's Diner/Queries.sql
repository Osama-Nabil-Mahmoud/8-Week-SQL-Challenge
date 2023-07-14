/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id , concat(sum(m1.price),' $') as "Total Spent"
      from sales s , members m , menu m1
	  where s.customer_id = m.customer_id and s.product_id = m1.product_id
	  group by s.customer_id ;
-- 2. How many days has each customer visited the restaurant?
select s.customer_id , count(distinct s.order_date) as "Days customer visited the restaurant"
      from sales s
	  group by s.customer_id
-- 3. What was the first item from the menu purchased by each customer?
select s1.customer_id , s1.order_date , m.product_name
     from
		(select s.customer_id , s.order_date,s.product_id
         ,DENSE_RANK() OVER(PARTITION BY s.customer_id order by s.order_date) as r
			from sales s ) as s1 , menu m
	 where s1.product_id = m.product_id and r = 1
	 order by s1.order_date;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 m.product_name , count(s.order_date) as time_purchased
	from menu m , sales s
	where m.product_id = s.product_id
	group by m.product_name
	order by time_purchased desc;
-- 5. Which item was the most popular for each customer?
with m_p
as
(
	select s.customer_id , s.product_id 
		,RANK() over(partition by s.customer_id order by count(s.product_id)) as r
		from sales s
		group by s.customer_id , s.product_id
)

select m1.customer_id ,STRING_AGG(m.product_name,', ') as 'Most ordered'
     from m_p m1 ,menu m
	 where m1.product_id = m.product_id and r = 1 
	 group by m1.customer_id;


-- 6. Which item was purchased first by the customer after they became a member?
with m_p
as
(
	select s.customer_id ,s.order_date ,s.product_id 
		,RANK() over(partition by s.customer_id order by s.order_date) as r
		from sales s , members m
		where s.customer_id = m.customer_id and s.order_date >= m.join_date
		group by s.customer_id , s.product_id ,s.order_date
)

select m1.customer_id ,m1.order_date ,STRING_AGG(m2.product_name,', ') as 'Product name'
     from m_p m1 ,menu m2
	 where m1.product_id = m2.product_id and r = 1  
	 group by m1.customer_id,m1.order_date;

-- 7. Which item was purchased just before the customer became a member?
with m_p
as
(
	select s.customer_id ,s.order_date ,s.product_id 
		,RANK() over(partition by s.customer_id order by s.order_date) as r
		from sales s , members m
		where s.customer_id = m.customer_id and s.order_date <= m.join_date
		group by s.customer_id , s.product_id ,s.order_date
)

select m1.customer_id ,m1.order_date ,STRING_AGG(m2.product_name,', ') as 'Product name'
     from m_p m1 ,menu m2
	 where m1.product_id = m2.product_id and r = 1  
	 group by m1.customer_id,m1.order_date;

-- 8. What is the total items and amount spent for each member before they became a member?
select m.customer_id ,count(s.product_id) as 'Total item',concat(sum(m1.price),' $') as 'Amount spent'
      from members m, sales s , menu m1
	  where m.customer_id = s.customer_id and s.product_id = m1.product_id 
	        and s.order_date < m.join_date
	  group by m.customer_id ;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
--     how many points would each customer have?
select s.customer_id ,sum(
                           case 
						   when m1.product_name = 'sushi' then m1.price*10*2
						   else m1.price*10
						   end
							) as 'Total Points'
      from  sales s , menu m1
	  where s.product_id = m1.product_id 
	  group by s.customer_id ;

-- 10. In the first week after a customer joins the program (including their join date)
--   they earn 2x points on all items, not just sushi -
--   how many points do customer A and B have at the end of January?
select m.customer_id , sum(
                             case 
						     when m1.product_name = 'sushi' then m1.price*10*2
							 when s.order_date between m.join_date 
							 	  and DATEADD(week,1,m.join_date) then m1.price*10*2
							 else m1.price*10
							 end
							)as 'Total Points'
      from members m, sales s , menu m1
	  where m.customer_id = s.customer_id and s.product_id = m1.product_id 
	        and s.order_date <= '2021-1-31'
	  group by m.customer_id ;

/* ----------------
   Bonus Questions
   ----------------*/
--11-Join All The Things
--Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)
select s.customer_id, s.order_date, m1.product_name, m1.price,
       CASE
       WHEN m.join_date <= s.order_date THEN 'Y' 
	   ELSE 'N'
	   END
	   AS 'member_status'
      FROM   sales s LEFT JOIN members m 
				ON m.customer_id=s.customer_id 
	         INNER join menu m1
				ON s.product_id=m1.product_id;

--12- Rank All The Things
/*Danny also requires further information about the ranking of customer 
products, but he purposely does not need the ranking for non-member 
purchases so he expects null ranking values for the records when 
customers are not yet part of the loyalty program*/
select s.customer_id, s.order_date, m1.product_name, m1.price,
       CASE
       WHEN m.join_date <= s.order_date THEN 'Y' 
	   ELSE 'N'
	   END
	   AS 'member_status'
	   ,
	   CASE
	   WHEN s.order_date >= m.join_date THEN RANK() over(partition by s.customer_id,CASE
                                                                                    WHEN m.join_date <= s.order_date THEN 'Y' 
	                                                                                ELSE 'N'
																					END
	    order by s.order_date) 
	   ELSE Null 
	   end as 'Rank'
      FROM   sales s LEFT JOIN members m 
				ON m.customer_id=s.customer_id 
	         INNER join menu m1
				ON s.product_id=m1.product_id
	 -- Other answer
with m_s
AS
(
	select s.customer_id, s.order_date, m1.product_name, m1.price,
       CASE
       WHEN m.join_date <= s.order_date THEN 'Y' 
	   ELSE 'N'
	   END
	   AS 'member_status'
      FROM   sales s LEFT JOIN members m 
				ON m.customer_id=s.customer_id 
	         INNER join menu m1
				ON s.product_id=m1.product_id
)	  

select * , CASE
	       WHEN m.member_status = 'Y' THEN RANK() over(partition by m.customer_id,member_status order by m.order_date) 
	       ELSE NULL 
		   end AS 'Rank'
	from m_s m
