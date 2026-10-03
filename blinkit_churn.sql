CREATE TABLE customers (
    customer_id                 VARCHAR(20)     PRIMARY KEY,
    signup_datetime             TIMESTAMP,
    signup_city                 VARCHAR(50),
    current_city                VARCHAR(50),
    area                        VARCHAR(100),
    pincode                     VARCHAR(10),
    acquisition_channel         VARCHAR(50),
    acquisition_campaign        VARCHAR(100),
    first_order_datetime        TIMESTAMP,
    customer_status             VARCHAR(20),
    preferred_payment_method    VARCHAR(50),
    preferred_order_daypart     VARCHAR(20)
);

CREATE TABLE orders (
    order_id                    VARCHAR(30)     PRIMARY KEY,
    customer_id                 VARCHAR(20)     NOT NULL
                                REFERENCES customers(customer_id),
    order_datetime              TIMESTAMP,
    store_id                    VARCHAR(20),
    city                        VARCHAR(50),
    area                        VARCHAR(100),
    order_status                VARCHAR(30),
    gross_order_value           NUMERIC(12,2),
    product_discount            NUMERIC(10,2),
    coupon_discount             NUMERIC(10,2),
    delivery_fee                NUMERIC(8,2),
    handling_fee                NUMERIC(8,2),
    surge_fee                   NUMERIC(8,2),
    total_discount              NUMERIC(10,2),
    final_order_value           NUMERIC(12,2),
    payment_method              VARCHAR(50),
    coupon_code                 VARCHAR(50),
    item_count                  INTEGER,
    unique_skus                 INTEGER,
    delivery_distance_km        NUMERIC(8,2),
    promised_delivery_minutes   INTEGER,
    actual_delivery_minutes     NUMERIC(8,2),
    delivery_delay_minutes      NUMERIC(8,2),
    cancellation_reason         VARCHAR(100),
    refund_amount               NUMERIC(10,2),
    reorder_flag                VARCHAR(10),
    previous_order_id           VARCHAR(30)
                                REFERENCES orders(order_id),
    order_sequence              INTEGER
);

CREATE TABLE deliveries (
    order_id                    VARCHAR(30)     PRIMARY KEY
                                REFERENCES orders(order_id),
    store_id                    VARCHAR(20),
    delivery_partner_id         VARCHAR(20),
    assigned_datetime           TIMESTAMP,
    pickup_datetime             TIMESTAMP,
    delivered_datetime          TIMESTAMP,
    promised_datetime           TIMESTAMP,
    actual_distance_km          NUMERIC(8,2),
    delivery_minutes            NUMERIC(8,2),
    delay_minutes               NUMERIC(8,2),
    delivery_status             VARCHAR(30),
    failed_delivery_reason      VARCHAR(100),
    customer_unavailable_flag   VARCHAR(10),
    weather_flag                VARCHAR(10)
);

CREATE TABLE order_items (
    order_id                    VARCHAR(30)     NOT NULL
                                REFERENCES orders(order_id),
    product_id                  VARCHAR(30)     NOT NULL,
    quantity                    INTEGER,
    unit_mrp                    NUMERIC(10,2),
    unit_selling_price          NUMERIC(10,2),
    discount_amount             NUMERIC(10,2),
    item_revenue                NUMERIC(10,2),
    category_id                 VARCHAR(20),
    category_name               VARCHAR(100),
    subcategory                 VARCHAR(100),
    brand                       VARCHAR(100),
    pack_size                   VARCHAR(50),
    margin_percent              NUMERIC(8,2),
    stockout_flag               VARCHAR(10),
    substituted_flag            VARCHAR(10),
    substitution_product_id     VARCHAR(30),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE promotions (
    order_id                    VARCHAR(30)     PRIMARY KEY
                                REFERENCES orders(order_id),
    customer_id                 VARCHAR(20)     NOT NULL
                                REFERENCES customers(customer_id),
    campaign_id                 VARCHAR(30),
    coupon_code                 VARCHAR(50),
    promotion_type              VARCHAR(50),
    discount_amount             NUMERIC(10,2),
    minimum_cart_value          NUMERIC(10,2),
    acquisition_or_retention    VARCHAR(20)
);

CREATE TABLE customer_feedback (
    feedback_id                 VARCHAR(20)     PRIMARY KEY,
    order_id                    VARCHAR(30)     NOT NULL
                                REFERENCES orders(order_id),
    customer_id                 VARCHAR(20)     NOT NULL
                                REFERENCES customers(customer_id),
    feedback_datetime           TIMESTAMP,
    rating                      INTEGER,
    feedback_category           VARCHAR(50),
    feedback_text               TEXT,
    sentiment                   VARCHAR(20),
    issue_resolved_flag         VARCHAR(10),
    resolution_time_minutes     INTEGER,
    refund_received_flag        VARCHAR(10)
);

CREATE TABLE customer_support (
    ticket_id                   VARCHAR(20)     PRIMARY KEY,
    customer_id                 VARCHAR(20)     NOT NULL
                                REFERENCES customers(customer_id),
    order_id                    VARCHAR(30)
                                REFERENCES orders(order_id),
    ticket_datetime             TIMESTAMP,
    issue_type                  VARCHAR(50),
    resolution_status           VARCHAR(30),
    resolution_time_minutes     INTEGER,
    compensation_amount         NUMERIC(10,2),
    repeat_issue_flag           VARCHAR(10)
);

CREATE TABLE customer_features (
    customer_id                 VARCHAR(20)     PRIMARY KEY
                                REFERENCES customers(customer_id),
    signup_date                 DATE,
    first_order_date            DATE,
    last_order_date             DATE,
    customer_age_days           INTEGER,
    total_orders                INTEGER,
    orders_last_30d             INTEGER,
    orders_last_60d             INTEGER,
    orders_last_90d             INTEGER,
    average_order_value         NUMERIC(12,2),
    median_order_value          NUMERIC(12,2),
    average_order_interval_days NUMERIC(10,2),
    median_order_interval_days  NUMERIC(10,2),
    max_gap_between_orders_days NUMERIC(10,2),
    days_since_last_order       NUMERIC(10,2),
    inactivity_ratio            NUMERIC(10,4),
    total_revenue               NUMERIC(14,2),
    last_90d_revenue            NUMERIC(12,2),
    coupon_usage_rate           NUMERIC(8,4),
    discount_dependency         NUMERIC(8,4),
    average_delivery_time       NUMERIC(8,2),
    late_delivery_rate          NUMERIC(8,4),
    cancellation_rate           NUMERIC(8,4),
    refund_rate                 NUMERIC(8,4),
    average_rating              NUMERIC(4,2),
    negative_feedback_rate      NUMERIC(8,4),
    support_ticket_count        INTEGER,
    repeat_complaint_count      INTEGER,
    category_count              INTEGER,
    essential_category_share    NUMERIC(8,4),
    primary_store_id            VARCHAR(20),
    city                        VARCHAR(50),
    acquisition_channel         VARCHAR(50),
    cohort_month                VARCHAR(10),
    lifecycle_stage             VARCHAR(30),
    churn_flag                  VARCHAR(10),
    churn_date                  DATE,
    reactivated_flag            VARCHAR(10)
);

select distinct cancellation_reason from orders where order_status = 'Cancelled';
select * from deliveries
where delivery_status = 'Completed'
order by delay_minutes desc;


-- Flagging churned customers
/* Churning Criteria:
	- customers didn't order anything in past 60 days
	- customers should be joined atleast 60 days ago */
	
with last_order as (	-- calculating last order date to use it as current date as dataset isn't live
	select max(order_datetime) as last_order from orders
	),
	order_pattern as (	-- formulating time difference b/w their orders from current last date
	select o.customer_id,
	lo.last_order - o.order_datetime as last_order_since
	from orders o, last_order lo
	group by o.customer_id, o.order_datetime, lo.last_order
	order by o.customer_id asc
	),
	joined_since as(	-- getting the joining date of customers
	select customer_id, signup_datetime from customers
	), 
	churned as (	-- final churned customers based upon criteria
	select op.customer_id, count(op.customer_id) filter(where op.last_order_since <= interval '60 days') as last_60day_order
	from order_pattern op join joined_since js on op.customer_id = js.customer_id , last_order lo
	where lo.last_order - js.signup_datetime >= interval '60 days'
	group by op.customer_id ) 

select customer_id as churned_customers 
from churned 
where last_60day_order = 0;


-- Do repeated service failure lead to churn?

with resolution_status as
	(select distinct cs.customer_id, 
	count(cs.customer_id) filter(where cs.resolution_status = 'Resolved') as resolved_tickets,
	count(cs.customer_id) filter(where cs.resolution_status != 'Resolved') as unresolved_tickets,
	cf.lifecycle_stage
	from customer_support cs join customer_features cf
	on cs.customer_id = cf.customer_id
	group by cs.customer_id, cf.lifecycle_stage
	order by cs.customer_id)

select distinct lifecycle_stage,
sum(resolved_tickets) as resolved_tickets,
sum(unresolved_tickets) as unresolved_tickets,
round(sum(unresolved_tickets)/sum(resolved_tickets), 3) as resolution_ratio
from resolution_status
group by lifecycle_stage;


-- Delivery status and correlation with churn

-- Delayed deliveries
select case when d.delay_minutes < -15 then 'Less than -15 mins'
	 		when d.delay_minutes > 60 then 'More than 60 mins'
	 		else concat(floor(d.delay_minutes/5.0)*5.0::int , ' to ' , floor((d.delay_minutes/5.0)+1.0)*5.0::int, ' mins')
	 		end as delay_bucket,
count(d.order_id) as delay_count,
round(count(o.customer_id) filter (where cf.lifecycle_stage = 'Churned')::numeric / nullif(count(*), 0)*100, 3) as churn_rate_percentage
from orders o join deliveries d
on o.order_id = d.order_id
join customer_features cf
on o.customer_id = cf.customer_id
where d.delay_minutes is not null
group by delay_bucket
order by min(d.delay_minutes);


-- Cancelled orders by our fault
with total_orders as (
    select count(*) as total_count
    from orders o join customer_features cf
    on o.customer_id = cf.customer_id)

select o.cancellation_reason,
count(o.order_id) as cancelled_order_count,
round(count(o.order_id) filter (where o.order_status = 'Cancelled')::numeric / nullif((select total_count from total_orders), 0)*100, 3) as cancellation_rate_percentage,
round(count(distinct o.customer_id) filter (where cf.lifecycle_stage = 'Churned')::numeric / nullif(count(*) filter (where o.order_status = 'Cancelled'), 0)*100, 3) as churn_rate_percentage
from orders o join customer_features cf
on o.customer_id = cf.customer_id
where order_status = 'Cancelled'
group by o.cancellation_reason
order by churn_rate_percentage desc;


-- rating vs churn
select cfeedback.rating as customer_rating, 
round(count(distinct cfeatures.customer_id) filter (where cfeatures.lifecycle_stage = 'Churned')::numeric / nullif(count(*), 0)*100, 3) as churn_rate_percentage
from customer_feedback cfeedback join customer_features cfeatures
on cfeedback.customer_id = cfeatures.customer_id
group by cfeedback.rating; 

-- sentiment vs churn
select cfeedback.sentiment as customer_sentiment, 
round(count(distinct cfeatures.customer_id) filter (where cfeatures.lifecycle_stage = 'Churned')::numeric / nullif(count(*), 0)*100, 3) as churn_rate_percentage
from customer_feedback cfeedback join customer_features cfeatures
on cfeedback.customer_id = cfeatures.customer_id
group by cfeedback.sentiment; 


-- Discount Analysis
select * from orders;

with discounts as 
	(select distinct cf.customer_id,
	count (o.customer_id) as order_count,
	count(o.product_discount) filter(where product_discount > 0) discount_count,
	cf.lifecycle_stage
	from orders o join customer_features cf
	on o.customer_id = cf.customer_id
	group by cf.customer_id, cf.lifecycle_stage
	order by discount_count desc)

select lifecycle_stage,
round(avg(order_count), 3) as avg_order_count, 
percentile_cont(0.5) within group (order by order_count) as median_order_count,
round(avg(discount_count), 3) as avg_discount_count,
percentile_cont(0.5) within group (order by discount_count) as median_discount_count,
round(sum(discount_count)::numeric/sum(order_count)*100, 3) as discount_rate_percentage
from discounts
group by lifecycle_stage;


-- cancellation pattern affecting churn
with order_history as
	(select row_number() over(partition by customer_id order by order_datetime) as row_num,
	customer_id,
	order_id,
	order_status,
	lead(order_id, 1) over(partition by customer_id order by order_datetime desc) as previous_order_id,
	lead(order_status, 1) over(partition by customer_id order by order_datetime desc) as previous_order_status,
	lead(order_id, 2) over(partition by customer_id order by order_datetime desc) as previous_2_order_id,
	lead(order_status, 2) over(partition by customer_id order by order_datetime desc) as previous_2_order_status
	from orders)
	
select case when oh.order_status = 'Delivered' and oh.previous_order_status = 'Delivered' and oh.previous_2_order_status = 'Delivered' then 'DDD'
			when oh.order_status = 'Delivered' and oh.previous_order_status = 'Cancelled' and oh.previous_2_order_status = 'Delivered' then 'DCD'
			when oh.order_status = 'Delivered' and oh.previous_order_status = 'Cancelled' and oh.previous_2_order_status = 'Cancelled' then 'DCC'
			when oh.order_status = 'Cancelled' and oh.previous_order_status = 'Delivered' and oh.previous_2_order_status = 'Delivered' then 'CDD'
			when oh.order_status = 'Cancelled' and oh.previous_order_status = 'Cancelled' and oh.previous_2_order_status = 'Delivered' then 'CCD'
			when oh.order_status = 'Cancelled' and oh.previous_order_status = 'Cancelled' and oh.previous_2_order_status = 'Cancelled' then 'CCC'
			when oh.order_status = 'Cancelled' and oh.previous_order_status = 'Delivered' and oh.previous_2_order_status = 'Cancelled' then 'CDC'
			when oh.order_status = 'Delivered' and oh.previous_order_status = 'Delivered' and oh.previous_2_order_status = 'Cancelled' then 'DDC'
			end as order_pattern_in_321,
count(distinct oh.customer_id) as total_customers,
count(distinct oh.customer_id) filter (where cf.lifecycle_stage = 'Churned') as churned_customers,
round(count(distinct oh.customer_id) filter (where cf.lifecycle_stage = 'Churned')::numeric / nullif(count(distinct oh.customer_id), 0)*100, 3) as churn_rate_percentage
from order_history oh join customer_features cf
on oh.customer_id = cf.customer_id
where oh.order_status in ('Delivered', 'Cancelled')
and oh.previous_order_status in ('Delivered', 'Cancelled')
and oh.previous_2_order_status in ('Delivered', 'Cancelled')
and row_num = 3
group by order_pattern_in_321
order by order_pattern_in_321, churn_rate_percentage desc;
			

-- Can quick customer resolution reduces churn?

-- Re-order and last order customer tickets
with cte as (select cs.ticket_id, cs.customer_id, cs.resolution_status, cs.resolution_time_minutes, o.reorder_flag
		from customer_support cs join orders o
		on cs.order_id = o.order_id
		order by customer_id)
select resolution_status,
round(avg(resolution_time_minutes) filter(where reorder_flag = '1'), 3) as avg_resolution_time_for_repeat_orders,
percentile_cont(0.5) within group (order by resolution_time_minutes) filter(where reorder_flag = '1') as median_resolution_time,
round(avg(resolution_time_minutes) filter(where reorder_flag = '0'), 3) as avg_resolution_time_for_non_repeat_orders,
percentile_cont(0.5) within group (order by resolution_time_minutes) filter(where reorder_flag = '0') as median_resolution_time
from cte
group by resolution_status;


-- Resolution timing and churn rate
with cte as (
select *, case when resolution_time_minutes < 60 then 'Less than 60 mins'
			   when resolution_time_minutes >= 2880 then '2880 mins or more'
			   else concat((floor(resolution_time_minutes / 60.0) * 60)::int, ' - ',
			   ((floor(resolution_time_minutes / 60.0) + 1) * 60)::int, ' mins')
			   end as intervals 
from customer_support
order by resolution_time_minutes asc)

select cte.intervals,
round(count(distinct cte.customer_id) filter (where cf.lifecycle_stage = 'Churned')::numeric / nullif(count(distinct cte.customer_id), 0)*100, 3) as churn_rate_percentage
from cte join customer_features cf
on cte.customer_id = cf.customer_id
where resolution_time_minutes is not null
group by cte.intervals
order by churn_rate_percentage desc;



-- New or Reactivated customers each month
select to_char(signup_date, 'MM-YYYY') as month_year,
count(distinct customer_id) as new_customers
from customer_features
where lifecycle_stage in ('New', 'Reactivated')
group by to_char(signup_date, 'MM-YYYY');


-- Churn vs Loyal customers by campaigns
select distinct p.campaign_id,
round(count(distinct p.customer_id) filter (where cf.lifecycle_stage = 'Churned')::numeric / nullif(count(distinct p.customer_id), 0)*100, 3) as churn_rate_percentage,
round(count(distinct p.customer_id) filter (where cf.lifecycle_stage = 'Loyal')::numeric / nullif(count(distinct p.customer_id), 0)*100, 3) as loyal_rate_percentage
from promotions p join customer_features cf
on p.customer_id = cf.customer_id
group by p.campaign_id;

-- Churn vs Loyal customers by acquistion channel
select distinct c.acquisition_channel,
round(count(distinct c.customer_id) filter (where cf.lifecycle_stage = 'Churned')::numeric / nullif(count(distinct c.customer_id), 0)*100, 3) as churn_rate_percentage,
round(count(distinct c.customer_id) filter (where cf.lifecycle_stage = 'Loyal')::numeric / nullif(count(distinct c.customer_id), 0)*100, 3) as loyal_rate_percentage
from customers c join customer_features cf
on c.customer_id = cf.customer_id
group by c.acquisition_channel;


-- Customer Lifetime value by median lifespan of 70% percentile
with cte as (select round(avg(customer_age_days)/30, 3) as ltv_span,
percentile_cont(0.7) within group (order by customer_age_days)/30 as median_ltv_span
from customer_features)

select cf.customer_id, cf.customer_age_days, cf.total_revenue, 
round(c.median_ltv_span::numeric*(30.0/cf.average_order_interval_days)*cf.average_order_value, 3) as projected_ltv
from customer_features cf, cte c;


-- Cohort analysis

with user_cohort as
	(  select customer_id, date_trunc('quarter', min(signup_date)) as cohort_date
	from customer_features
	group by customer_id order by signup_date ),
	user_orders as 
	(  select customer_id, date_trunc('quarter', order_datetime) as order_date
	from orders  ) ,
	cohort_index as 
	(  select uo.customer_id, uc.cohort_date, uo.order_date,
	extract(quarter from age(uo.order_date, uc.cohort_date)) as period_number
	from user_cohort uc join user_orders uo
	on uc.customer_id = uo.customer_id
	)

select to_char(cohort_date, '0Q-YYYY') as cohort_quarter, concat('Quarter ', period_number) as period_quarter,
count(distinct customer_id) as active_users
from cohort_index
group by cohort_date, period_number
order by cohort_date, period_number;









