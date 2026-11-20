DELETE FROM dws_user_order_day;

INSERT INTO dws_user_order_day (user_id, dt, order_cnt, total_amount)
SELECT user_id, dt, COUNT(*), SUM(order_amount)
FROM dwd_order_detail
GROUP BY user_id, dt;
