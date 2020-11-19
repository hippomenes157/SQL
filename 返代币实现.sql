#
#
#按照个人理解增加几个条件
#1.一张优惠券对应一个订单，一个订单可以用用多种优惠券
#2.优惠券只能对应商品订单时间晚于优惠券购买订单时间的订单
#3.一个订单可以有多种商品类型，但只根据玩家订单流水，在每个订单用一个优惠券的情况下做最多返还的结果
#4.考虑一个订单同时购买普通商品和优惠券的情况
#5.优惠券先进先出
DROP TABLE IF EXISTS used_coupon;
DROP TABLE IF EXISTS unused_order;
DROP TABLE IF EXISTS unused_coupon;

#已用优惠券 账号 类型 数量
Create Table used_coupon as 
select acc_name ,discountid ,count(distinct orderid ) num
from token_coupon_tt
group by acc_name ,discountid;

#可补偿优惠的商品订单 +类型
Create Table unused_order as 
select a.record_date ,a.orderid ,a.acc_name ,c.`type`,sum(a.price) total_price ,
case when c.`type` ='宠物' then sum(a.price)*0.5 when c.`type` ='发型' then 30 when c.`type` ='礼盒' then 50 else 0 end preferential_amount,
'N' used_flag,
row_number () over(partition  by  a.acc_name ,c.`type` order by case when c.`type` ='宠物' then sum(a.price)*0.5 when c.`type` ='发型' then 30 when c.`type` ='礼盒' then 50 else 0 end  desc) preferential_rn
from db_demo.token_order_tt a
join token_item_dt c on a.itemid =c.itemid 
where a.itemid not in (4001,4002,4003)
and not exists (select distinct i.orderid , j.`type` from token_coupon_tt i join token_item_dt j where i.orderid =a.orderid  and j.`type` =c.`type` )
group by a.record_date ,a.orderid ,a.acc_name ,c.`type`
having c.`type` ='宠物' or (c.`type` ='发型' and sum(a.price )>=200) or (c.`type` ='礼盒' and sum(a.price )>=500);

#可补偿的优惠券的优惠券购买订单(数量大于1的拆为amount为1的多行) 先进先出原则
Create Table unused_coupon as 
select a.record_date,a.orderid,a.acc_name,a.itemid,1 amount,a.price,a.`type`,'N' used_flag
from
(select t.* ,c.`type` ,
row_number () over(partition by t.acc_name ,t.itemid order by t.record_date asc) rn,
j.num
from db_demo.token_order_tt t
JOIN generator_64k i   ON i.n between 1 and t.amount 
left join used_coupon j on t.acc_name =j.acc_name and right(t.itemid,1) =j.discountid 
join token_item_dt c on t.itemid =c.itemid 
where t.itemid in (4001,4002,4003)) a
where a.rn>a.num or a.num is null;


DROP procedure IF EXISTS used;

create procedure used()
BEGIN 
DECLARE record_date_s datetime;
DECLARE orderid_s int;
DECLARE acc_name_s char(10);
DECLARE type_s char(10);
DECLARE s int DEFAULT 0;
DECLARE a int DEFAULT null;
DECLARE coupon CURSOR FOR SELECT a.record_date ,a.orderid ,a.acc_name ,a.`type` FROM unused_coupon a order by a.acc_name asc ,a.`type` asc,a.record_date desc;
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET s=1;
  OPEN coupon;
    FETCH coupon into record_date_s,orderid_s,acc_name_s,type_s;
    while s <> 1 DO
	set a = (select max(a.preferential_amount ) from unused_order a where a.acc_name = acc_name_s and a.`type` =left(type_s,2) and a.used_flag ='N' and a.record_date >record_date_s);   
	if a is not null then
		UPDATE unused_order a set a.used_flag='Y' where a.acc_name =acc_name_s and a.`type` =left(type_s,2) and a.used_flag ='N' and a.record_date >record_date_s order by a.preferential_amount limit 1 ;
		UPDATE unused_coupon a set a.used_flag='Y' where a.record_date =record_date_s and a.orderid=orderid_s and a.acc_name =acc_name_s and a.`type` =type_s;
		#UPDATE unused_coupon a set a.used_flag='Y';
	end if;
	set a = null;
    FETCH coupon INTO record_date_s,orderid_s,acc_name_s,type_s;
    end WHILE;
  CLOSE coupon;
end;

call used();
select * from unused_order;
select * from unused_coupon;

select a.acc_name ,sum(a.preferential_amount )
from unused_order a
where a.used_flag ='Y'
group by a.acc_name ;

select a.acc_name,a.`type` ,count(1)
from unused_coupon a
where a.used_flag ='Y'
group by a.acc_name,a.`type`;




