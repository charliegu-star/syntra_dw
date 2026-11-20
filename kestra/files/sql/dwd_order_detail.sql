DELETE FROM dwd_order_detail;

INSERT INTO dwd_order_detail (order_id, user_id, order_amount, pay_time, pay_date, dt)
SELECT id, user_id, order_amount, pay_time, DATE(pay_time),
       DATE_FORMAT(pay_time, '%Y-%m-%d')
FROM ods_order
WHERE status = 'PAID'
  AND user_id IS NOT NULL
  AND order_amount IS NOT NULL
  AND order_amount > 0
  AND pay_time IS NOT NULL;
