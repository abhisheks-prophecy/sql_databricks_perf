{% macro tpcds_macros_query_3(date_dim, store_sales, item, i_manufact_id=540) %}


 select  dt.d_year 
       ,item.i_brand_id brand_id 
       ,item.i_brand brand
       ,sum(ss_ext_discount_amt) sum_agg
 from  {{date_dim}} dt 
      ,{{store_sales}}
      ,{{item}}
 where dt.d_date_sk = {{store_sales}}.ss_sold_date_sk
   and {{store_sales}}.ss_item_sk = item.i_item_sk
   and item.i_manufact_id = {{i_manufact_id}}
   and dt.d_moy=12
 group by dt.d_year
      ,item.i_brand
      ,item.i_brand_id
 order by dt.d_year
         ,sum_agg desc
         ,brand_id
 limit 100
{% endmacro %}

 {% macro tpcds_macros_query_2(web_sales, catalog_sales, date_dim, day_name='Sunday', d_year=1999) %}


with wscs as
 (select sold_date_sk
        ,sales_price
  from  (select ws_sold_date_sk sold_date_sk
              ,ws_ext_sales_price sales_price
        from {{web_sales}} 
        UNION ALL
        select cs_sold_date_sk sold_date_sk
              ,cs_ext_sales_price sales_price
        from {{catalog_sales}}) x ),
 wswscs as 
 (select d_week_seq,
        sum(case when (d_day_name='{{day_name}}') then sales_price else null end) sun_sales,
        sum(case when (d_day_name='Monday') then sales_price else null end) mon_sales,
        sum(case when (d_day_name='Tuesday') then sales_price else  null end) tue_sales,
        sum(case when (d_day_name='Wednesday') then sales_price else null end) wed_sales,
        sum(case when (d_day_name='Thursday') then sales_price else null end) thu_sales,
        sum(case when (d_day_name='Friday') then sales_price else null end) fri_sales,
        sum(case when (d_day_name='Saturday') then sales_price else null end) sat_sales
 from wscs
     ,{{date_dim}}
 where d_date_sk = sold_date_sk
 group by d_week_seq)
 select d_week_seq1
       ,round(sun_sales1/sun_sales2,2)
       ,round(mon_sales1/mon_sales2,2)
       ,round(tue_sales1/tue_sales2,2)
       ,round(wed_sales1/wed_sales2,2)
       ,round(thu_sales1/thu_sales2,2)
       ,round(fri_sales1/fri_sales2,2)
       ,round(sat_sales1/sat_sales2,2)
 from
 (select wswscs.d_week_seq d_week_seq1
        ,sun_sales sun_sales1
        ,mon_sales mon_sales1
        ,tue_sales tue_sales1
        ,wed_sales wed_sales1
        ,thu_sales thu_sales1
        ,fri_sales fri_sales1
        ,sat_sales sat_sales1
  from wswscs,{{date_dim}} 
  where {{date_dim}}.d_week_seq = wswscs.d_week_seq and
        d_year = {{d_year}}) y,
 (select wswscs.d_week_seq d_week_seq2
        ,sun_sales sun_sales2
        ,mon_sales mon_sales2
        ,tue_sales tue_sales2
        ,wed_sales wed_sales2
        ,thu_sales thu_sales2
        ,fri_sales fri_sales2
        ,sat_sales sat_sales2
  from wswscs
      ,{{date_dim}} 
  where {{date_dim}}.d_week_seq = wswscs.d_week_seq and
        d_year = {{d_year}}+1) z
 where d_week_seq1=d_week_seq2-53
 order by d_week_seq1
{% endmacro %}

 {% macro tpcds_macros_query_1(store_returns, date_dim, d_year=1999, s_state='NM') %}


with customer_total_return as
(select sr_customer_sk as ctr_customer_sk
,sr_store_sk as ctr_store_sk
,sum(SR_RETURN_AMT_INC_TAX) as ctr_total_return
from {{store_returns}}
,{{date_dim}}
where sr_returned_date_sk = d_date_sk
and d_year = {{d_year}}
group by sr_customer_sk
,sr_store_sk)
 select  c_customer_id
from customer_total_return ctr1
,store
,customer
where ctr1.ctr_total_return > (select avg(ctr_total_return)*1.2
from customer_total_return ctr2
where ctr1.ctr_store_sk = ctr2.ctr_store_sk)
and s_store_sk = ctr1.ctr_store_sk
and s_state = '{{s_state}}'
and ctr1.ctr_customer_sk = c_customer_sk
order by c_customer_id
limit 100
{% endmacro %}

 