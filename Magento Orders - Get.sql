/**********************
Program Name: Magento Orders - Get SQL Aget job
Program Description: Get the Magento orders data to SQL.
Requestor: Kyle MacKenzie
Developer: Kyle MacKenzie
**********************/

-----Code to create a table to hold required fields from the landing table which is IT.dbo.orders_bludot_enterprise

CREATE TABLE IT.dbo.MAGENTO_ORDERS (
    code varchar(100),
	name varchar(100),
	entity_id varchar(100),
	state varchar(100),
	status varchar(100),
	coupon_code varchar(100),
	grand_total varchar(50),
	customer_group_id varchar(50),
	increment_id varchar(50) NOT NULL,
	customer_email varchar(200),
	customer_firstname varchar(200),
	customer_lastname varchar(200),
	discount_description varchar(100),
	remote_ip varchar(100),
	customer_note varchar(5000),
	created_at varchar(50),
	coupon_rule_name varchar(100),
	billing_address_customer_id varchar(50),
	billing_address_firstname varchar(250),
	billing_address_lastname varchar(250),
	billing_address_street varchar(250),
	billing_address_city varchar(250),
	billing_address_region varchar(250),
	billing_address_postcode varchar(50),
	billing_address_country_id varchar(50),
	billing_address_telephone varchar(100),
	billing_address_company varchar(500),
	shipping_address_customer_id varchar(50),
	shipping_address_firstname varchar(250),
	shipping_address_lastname varchar(250),
	shipping_address_street varchar(250),
	shipping_address_city varchar(250),
	shipping_address_region varchar(250),
	shipping_address_postcode varchar(50),
	shipping_address_country_id varchar(50),
	shipping_address_telephone varchar(100),
	shipping_address_company varchar(500)
    PRIMARY KEY (increment_id)
)

----Steps for SQL agent job:

--STEP 1: Delete file from yesterday off E drive

del E:\GPCentral\Scribe\Collaborations\Magento\Inputs\orders_bludot_enterprise.csv

--STEP 2: Get Daily FTP orders data file from Magento

"C:\Program Files (x86)\WinSCP\WinSCP.com" /log="E:\GPCentral\winscp\winscpget.log" /loglevel=2 
/script="E:\GPCentral\Scribe\Collaborations\Magento\Code\Magento_FTP_get_orders.txt"

--STEP 3: Drop Landing table to load the data again in next step

drop table [IT].[dbo].[orders_bludot_enterprise]

--STEP 4: Move Magento Ordres csv file to Landing table using SSIS Package (this can be painful to update)
\\bludot-sql1\GPCentral\Scribe\Collaborations\Magento\Code\Magento_Orders.dtsx

--STEP 5: Updating Magento_orders table to extract the new required fileds daily

Insert Into IT.dbo.MAGENTO_ORDERS
(
code,
name,
entity_id,
state,
status,
coupon_code,
grand_total,
customer_group_id,
increment_id,
customer_email,
customer_firstname,
customer_lastname,
discount_description,
remote_ip,
customer_note,
created_at,
coupon_rule_name,
billing_address_customer_id,
billing_address_firstname,
billing_address_lastname,
billing_address_street,
billing_address_city,
billing_address_region,
billing_address_postcode,
billing_address_country_id,
billing_address_telephone,
billing_address_company,
shipping_address_customer_id,
shipping_address_firstname,
shipping_address_lastname,
shipping_address_street,
shipping_address_city,
shipping_address_region,
shipping_address_postcode,
shipping_address_country_id,
shipping_address_telephone,
shipping_address_company
)
select 
code,
name,
entity_id,
state,
status,
coupon_code,
grand_total,
customer_group_id,
increment_id,
customer_email,
customer_firstname,
customer_lastname,
discount_description,
remote_ip,
customer_note,
cast(created_at as date) as created_at,
coupon_rule_name,
billing_address_customer_id,
billing_address_firstname,
billing_address_lastname,
billing_address_street,
billing_address_city,
billing_address_region,
billing_address_postcode,
billing_address_country_id,
billing_address_telephone,
billing_address_company,
shipping_address_customer_id,
shipping_address_firstname,
shipping_address_lastname,
shipping_address_street,
shipping_address_city,
shipping_address_region,
shipping_address_postcode,
shipping_address_country_id,
shipping_address_telephone,
shipping_address_company
from 
	IT.dbo.orders_bludot_enterprise
where 
	increment_id NOT IN (select increment_id from IT.dbo.MAGENTO_ORDERS)
  



