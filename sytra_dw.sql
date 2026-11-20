
-- ODS 原始订单表
CREATE TABLE IF NOT EXISTS ods_order (
    id BIGINT AUTO_INCREMENT COMMENT '订单id' ,
    user_id BIGINT COMMENT '用户id',
    order_amount DECIMAL(10,2) COMMENT '订单金额',
    pay_time DATETIME COMMENT '支付时间',
    status VARCHAR(20) COMMENT '订单状态',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    dt VARCHAR(20) COMMENT '分区日期 yyyy-MM-dd',
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- DWD 订单明细层：清洗后有效订单
CREATE TABLE IF NOT EXISTS dwd_order_detail (
    order_id BIGINT COMMENT '订单id',
    user_id BIGINT COMMENT '用户id',
    order_amount DECIMAL(10,2) COMMENT '订单金额',
    pay_time DATETIME COMMENT '支付时间',
    pay_date DATE COMMENT '支付日期',
    dt VARCHAR(20) COMMENT '分区日期',
    PRIMARY KEY (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- DWS 用户日汇总层
CREATE TABLE IF NOT EXISTS dws_user_order_day (
    user_id BIGINT COMMENT '用户id',
    dt VARCHAR(20) COMMENT '统计日期',
    order_cnt INT COMMENT '有效订单数',
    total_amount DECIMAL(10,2) COMMENT '累计支付金额'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ADS 用户报表应用层
CREATE TABLE IF NOT EXISTS ads_user_report (
    user_id BIGINT COMMENT '用户id',
    dt VARCHAR(20) COMMENT '日期',
    order_cnt INT COMMENT '订单数量',
    total_amount DECIMAL(10,2) COMMENT '消费总额',
    user_level VARCHAR(20) COMMENT '消费等级',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;