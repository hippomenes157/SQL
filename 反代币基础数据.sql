CREATE VIEW generator_16
AS SELECT 0 n UNION ALL SELECT 1  UNION ALL SELECT 2  UNION ALL 
   SELECT 3   UNION ALL SELECT 4  UNION ALL SELECT 5  UNION ALL
   SELECT 6   UNION ALL SELECT 7  UNION ALL SELECT 8  UNION ALL
   SELECT 9   UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL
   SELECT 12  UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL 
   SELECT 15;

CREATE VIEW generator_256
AS SELECT ( ( hi.n * 16 ) + lo.n ) AS n
     FROM generator_16 lo, generator_16 hi;

CREATE VIEW generator_4k
AS SELECT ( ( hi.n * 256 ) + lo.n ) AS n
     FROM generator_256 lo, generator_16 hi;

CREATE VIEW generator_64k
AS SELECT ( ( hi.n * 256 ) + lo.n ) AS n
     FROM generator_256 lo, generator_256 hi;

CREATE VIEW generator_1m
AS SELECT ( ( hi.n * 65536 ) + lo.n ) AS n
     FROM generator_64k lo, generator_16 hi;

DROP TABLE IF EXISTS token_order_tt;
DROP TABLE IF EXISTS token_coupon_tt;
DROP TABLE IF EXISTS token_item_dt;
DROP TABLE IF EXISTS token_coupon_ct;

CREATE TABLE token_order_tt(
	record_date DATETIME,
	orderid VARCHAR(10),
	acc_name varchar(10),
	itemid int(10),
	amount int(10),
	price float(10)
)ENGINE = INNODB DEFAULT CHARSET = utf8;

CREATE TABLE token_coupon_tt(
	record_date DATETIME,
	orderid VARCHAR(10),
	acc_name varchar(10),
	discountid varchar(1),
	itemid int(10)
)ENGINE = INNODB DEFAULT CHARSET = utf8;

CREATE TABLE token_item_dt(
	type VARCHAR(10),
	itemid int(10),
	price float(10)
)ENGINE = INNODB DEFAULT CHARSET = utf8;

CREATE TABLE token_coupon_ct(
	discountid int(10),
	itemid int(10)
)ENGINE = INNODB DEFAULT CHARSET = utf8;

insert into token_order_tt 
(record_date, orderid , acc_name, itemid,amount,price )
values
('2020/7/1 19:29:01',10000 , 'A' , 4001,1,50),
('2020/7/1 19:20:06',10001 , 'A' , 2301,1,300),
('2020/7/2 12:36:24',10002 , 'B' , 4001,1,50),
('2020/7/2 12:40:05',10003 , 'B' , 4002,1,10),
('2020/7/2 14:05:23',10004 , 'B' , 4003,2,20),
('2020/7/3 15:24:42',10005 , 'B' , 2305,1,100),
('2020/7/3 15:24:42',10005 , 'B' , 2306,1,120),
('2020/7/3 16:18:59',10006 , 'B' , 2310,1,480),
('2020/7/3 16:20:14',10007 , 'B' , 2311,1,688),
('2020/7/3 20:05:01',10008 , 'B' , 2312,1,520);

insert into token_coupon_tt 
(record_date, orderid , acc_name, discountid,itemid )
values
('2020/7/3 15:24:42',10005,'B',2,2305),
('2020/7/3 15:24:42',10005,'B',2,2306),
('2020/7/3 16:18:59',10008,'B',3,2312);

insert into token_item_dt 
(type,itemid,price )
values
('宠物','2301',300),
('宠物','2302',250),
('宠物','2303',360),
('宠物','2304',400),
('发型','2305',100),
('发型','2306',120),
('发型','2307',200),
('发型','2308',200),
('发型','2309',300),
('礼盒','2310',400),
('礼盒','2311',688),
('礼盒','2312',5200),
('宠物五折券','4001',50),
('发型满减券','4002',10),
('礼盒满减券','4003',20);

insert into token_coupon_ct 
(discountid,itemid )
values
(1,4001),
(2,4002),
(3,4003);