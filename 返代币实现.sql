#
#
#���ո���������Ӽ�������
#1.һ���Ż�ȯ��Ӧһ��������һ�������������ö����Ż�ȯ
#2.�Ż�ȯֻ�ܶ�Ӧ��Ʒ����ʱ�������Ż�ȯ���򶩵�ʱ��Ķ���
#3.һ�����������ж�����Ʒ���ͣ���ֻ������Ҷ�����ˮ����ÿ��������һ���Ż�ȯ�����������෵���Ľ��
#4.����һ������ͬʱ������ͨ��Ʒ���Ż�ȯ�����
#5.�Ż�ȯ�Ƚ��ȳ�
DROP TABLE IF EXISTS used_coupon;
DROP TABLE IF EXISTS unused_order;
DROP TABLE IF EXISTS unused_coupon;

#�����Ż�ȯ �˺� ���� ����
Create Table used_coupon as 
select acc_name ,discountid ,count(distinct orderid ) num
from token_coupon_tt
group by acc_name ,discountid;

#�ɲ����Żݵ���Ʒ���� +����
Create Table unused_order as 
select a.record_date ,a.orderid ,a.acc_name ,c.`type`,sum(a.price) total_price ,
case when c.`type` ='����' then sum(a.price)*0.5 when c.`type` ='����' then 30 when c.`type` ='���' then 50 else 0 end preferential_amount,
'N' used_flag,
row_number () over(partition  by  a.acc_name ,c.`type` order by case when c.`type` ='����' then sum(a.price)*0.5 when c.`type` ='����' then 30 when c.`type` ='���' then 50 else 0 end  desc) preferential_rn
from db_demo.token_order_tt a
join token_item_dt c on a.itemid =c.itemid 
where a.itemid not in (4001,4002,4003)
and not exists (select distinct i.orderid , j.`type` from token_coupon_tt i join token_item_dt j where i.orderid =a.orderid  and j.`type` =c.`type` )
group by a.record_date ,a.orderid ,a.acc_name ,c.`type`
having c.`type` ='����' or (c.`type` ='����' and sum(a.price )>=200) or (c.`type` ='���' and sum(a.price )>=500);

#�ɲ������Ż�ȯ���Ż�ȯ���򶩵�(��������1�Ĳ�ΪamountΪ1�Ķ���) �Ƚ��ȳ�ԭ��
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




