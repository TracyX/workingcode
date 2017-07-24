
config="set hive.optimize.skewjoin = true;
set hive.cli.print.header=true;
set mapreduce.input.fileinputformat.split.maxsize=2147483648;
set mapreduce.input.fileinputformat.split.minsize=2147483648;
set mapreduce.job.reduce.slowstart.completedmaps=1;
set hive.auto.convert.join=true;
set mapred.output.compress=true;
set hive.exec.compress.output=true;
"

config1=" 
set mapreduce.input.fileinputformat.split.maxsize=2147483648;
set mapreduce.input.fileinputformat.split.minsize=2147483648;
set mapreduce.job.reduce.slowstart.completedmaps=1;
set mapred.output.compress=true;
set hive.exec.compress.output=true;
"



hive -e "
${config}
use app;
drop table  app_lookfor_similar_detail;   
create table  app_lookfor_similar_detail as
select a.*,c1.cid3,
if(c1.spu=c2.spu,1,0) as spu,
if(c2.shop_id=c1.shop_id,1,0) as shop_id,if(c1.brand_id=c2.brand_id,1,0) as brand_id  from
app_product_details_gbdt_1 a
left outer join 
app_item_basic_new c1 
on a.sku=c1.sku
left outer join 
app_item_basic_new c2 
on a.csku=c2.sku
where c1.cid3=c2.cid3
 ;
"


i=655
hive -e "
${config1}
use app;
drop table  app_lookfor_similar_sku_ext_attr_$i; 
create table app_lookfor_similar_sku_ext_attr_$i as 
select item_sku_id,  com_attr_cd,com_attr_value_cd  as attr from gdm.gdm_m03_item_sku_ext_attr_da  where dt='2017-06-27'  and cate_id=$i;



drop table  app_lookfor_similar_detail_$i;   
create table  app_lookfor_similar_detail_$i as
select a.*,b.com_attr_cd,concat_ws('_',b.com_attr_cd,b.attr) as com_attr_cd_value,  if(c.com_attr_cd is not null and b.attr=c.attr, 1,0) as match from
(select * from app_lookfor_similar_detail  where cid3=$i )a
join app_lookfor_similar_sku_ext_attr_$i b on a.sku=b.item_sku_id
join app_lookfor_similar_sku_ext_attr_$i c on a.csku=c.item_sku_id and b.com_attr_cd=c.com_attr_cd;"




hive -e " 
use app;
set mapreduce.job.reduce.slowstart.completedmaps=1;
drop table  app_lookfor_similar_feature_$i;   
create table  app_lookfor_similar_feature_$i as
select concat_ws(' ',  score,sku,   concat('spu_', spu),concat('shop_id_', shop_id),concat('brand_id_', brand_id),com_attr_cd,com_attr_cd_value) as instance from
(select sku, min(score) as score,min(spu) as spu,min(shop_id) as shop_id,min(brand_id) as brand_id,concat_ws(' ',collect_set(com_attr_cd)) as com_attr_cd,concat_ws(' ',collect_set(com_attr_cd_value)) as com_attr_cd_value from
(select concat_ws('_',sku,csku) as sku, score, spu,shop_id, brand_id,concat_ws('_',com_attr_cd, cast(match as string)) as com_attr_cd ,concat_ws('_',com_attr_cd_value, cast(match as string))   as com_attr_cd_value
from app_lookfor_similar_detail_$i)a group by sku)b;
"



"


hdfs_basename=app_lookfor_similar_feature_
basename=app_lookfor_similar_feature_
hadoop fs -getmerge /user/recsys/app.db/${hdfs_basename} ${basename}

awk '{printf("%f %s|x ",$1,$2); $1=$2=""; gsub(/^ +/, "", $0); print $0}' ${basename}  > ${basename}.vw

source ~/zhujianfeng/.bashrc
model=cross_655.vwmodel

/bin/rm temp.cache || true
quantile
vw -d ${basename}.vw  --passes 3  --cache_file temp.cache  --holdout_period 10 -C 0.5 --compressed  -f ${model}  --loss_function=squared    --ftrl --l1 1e-7 --l2 1e-7 -l 0.2 --power_t 0.5 
vw -t -i ${model} -d ${basename}.vw -p train_a18_pred.txt --loss_function=squared
awk '{print $1}' train_a18_pred.txt > y_pred_cross.txt
Rscript auc_pred_label.R y_pred_cross.txt 902008_ctr_data_samplenum_cid3_feature.vw.y | tee train_a18.auc

vw --ignore x -d 902008_ctr_data_samplenum_cid3_feature.vw  --passes 2 --holdout_period 5 --cache_file temp.cache -f nocross_cid3.vwmodel  --loss_function=logistic --ftrl --l1 1e-7 --l2 1e-7 --power_t 0.5 --save_resume
vw -t -i nocross_cid3.vwmodel 902008_ctr_data_samplenum_cid3_feature.vw -p train_a18_pred_nocross.txt --loss_function=logistic

awk '{print $1}' train_a18_pred_nocross.txt > y_pred_nocross.txt
Rscript auc_pred_label.R y_pred_nocross.txt 902008_ctr_data_samplenum_cid3_feature.vw.y | tee valid_a18_nocross.auc

vw -t -i ${model} -d app_ctr_107000_log_strict_time_feature_xgb_concat.sort.test_a18.vw -p test_a18_pred.txt --loss_function=logistic

 vw -b 25 -d 902008_ctr_data_samplenum_cid3_feature.vw -q xy --passes 2 --holdout_period 5 --cache_file temp.cache -f cross_cid3_final.vwmodel -q xy  --loss_function=logistic --l1 1e-8 --power_t 0.5 --save_resume

Rscript auc_pred_label.R test_a18_pred.txt app_ctr_107000_log_strict_time_feature_xgb_concat.sort.test_a18.vw.y | tee test_a18.auc



  ##好评和价格等级信息待补充




