DELETE FROM ads_user_report;

INSERT INTO ads_user_report (user_id, dt, order_cnt, total_amount, user_level)
SELECT user_id, dt, order_cnt, total_amount,
       CASE
           WHEN total_amount >= 1000 THEN 'HIGH'
           WHEN total_amount >= 100 THEN 'MEDIUM'
           ELSE 'LOW'
       END
FROM dws_user_order_day;
