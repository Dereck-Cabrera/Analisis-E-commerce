/* 
   PROYECTO 1 · ELECTRONIC ROXX SHOPPING
   Universidad Rafael Landívar · Ciencia de Datos
   Jairo Omar Salazar Chávez 
   DDL - Data Warehouse 
   Dereck Alexander Cabrera NG - 1177223
   Mario Miguel Arevalo Perez  - 1072123
   */

--  ESQUEMA

DROP SCHEMA IF EXISTS dw_roxx CASCADE;
CREATE SCHEMA dw_roxx;
SET search_path TO dw_roxx;


-- DIM_DATE

CREATE TABLE dim_date (
    date_id             INT             NOT NULL,          -- llave (YYYYMMDD)
    full_date           DATE            NOT NULL,
    day                 SMALLINT        NOT NULL,
    month               SMALLINT        NOT NULL,
    month_name          VARCHAR(20)     NOT NULL,
    quarter             SMALLINT        NOT NULL,
    year                SMALLINT        NOT NULL,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_id),
    CONSTRAINT uq_dim_date_full_date UNIQUE (full_date),
    CONSTRAINT ck_dim_date_day CHECK (day BETWEEN 1 AND 31),
    CONSTRAINT ck_dim_date_month CHECK (month BETWEEN 1 AND 12),
    CONSTRAINT ck_dim_date_quarter CHECK (quarter BETWEEN 1 AND 4)
);

-- DIM_GEOGRAPHY
CREATE TABLE dim_geography (
    geography_id        SERIAL          NOT NULL,
    city                VARCHAR(80)     NOT NULL,
    state               VARCHAR(80)     NOT NULL,
    country             VARCHAR(80)     NOT NULL,
    region              VARCHAR(80)     NOT NULL DEFAULT 'Desconocido',
    CONSTRAINT pk_dim_geography PRIMARY KEY (geography_id),
    CONSTRAINT uq_dim_geography_natural UNIQUE (city, state, country, region)
);

CREATE INDEX ix_dim_geography_country ON dim_geography (country);
CREATE INDEX ix_dim_geography_region  ON dim_geography (region);


-- DIM_CUSTOMER
CREATE TABLE dim_customer (
    customer_id_pk       SERIAL            NOT NULL,          -- llave
    customer_id           VARCHAR(80)      NOT NULL,          -- llave principal
    customer_name         VARCHAR(150)     NOT NULL,
    segment                VARCHAR(80)     NOT NULL,
    gender                 VARCHAR(20)     NOT NULL,
    age                    SMALLINT        NOT NULL,
    education              VARCHAR(80)     NOT NULL,
    marital_status         VARCHAR(30)     NOT NULL,
    CONSTRAINT pk_dim_customer PRIMARY KEY (customer_id_pk),
    CONSTRAINT uq_dim_customer_natural UNIQUE (customer_id),
    CONSTRAINT ck_dim_customer_gender CHECK (gender IN ('Male', 'Female')),
    CONSTRAINT ck_dim_customer_segment CHECK (segment IN ('Consumer', 'Corporate', 'Home Office')),
    CONSTRAINT ck_dim_customer_marital CHECK (marital_status IN ('Single', 'Married')),
    CONSTRAINT ck_dim_customer_age CHECK (age BETWEEN 0 AND 120)
);



-- DIM_PRODUCT
CREATE TABLE dim_product (
    product_id            SERIAL          NOT NULL,
    product_name          VARCHAR(150)    NOT NULL,
    product_category      VARCHAR(80)     NOT NULL,
    CONSTRAINT pk_dim_product PRIMARY KEY (product_id),
    CONSTRAINT uq_dim_product_natural UNIQUE (product_name, product_category),
    CONSTRAINT ck_dim_product_category CHECK (
        product_category IN ('Auto & Accessories', 'Electronic', 'Home & Furniture', 'Fashion')
    )
);



-- DIM_ORDER 
CREATE TABLE dim_order (
    order_id_pk             SERIAL          NOT NULL,          -- llave  
    order_id                VARCHAR(80)     NOT NULL,          -- llave natural del origen 
    order_priority          VARCHAR(20)     NOT NULL DEFAULT 'Desconocido',
    ship_mode               VARCHAR(80)     NOT NULL DEFAULT 'Desconocido',
    CONSTRAINT pk_dim_order PRIMARY KEY (order_id_pk),
    CONSTRAINT uq_dim_order_natural UNIQUE (order_id),
    CONSTRAINT ck_dim_order_priority CHECK (
        order_priority IN ('Low', 'Medium', 'High', 'Critical', 'Desconocido')
    ),
    CONSTRAINT ck_dim_order_ship_mode CHECK (
        ship_mode IN ('Standard Class', 'Second Class', 'First Class', 'Same Day', 'Desconocido')
    )
);



-- DIM_BEHAVIOR
CREATE TABLE dim_behavior (
    behavior_id             SERIAL          NOT NULL,
    browsing_time_min       DECIMAL(8,2)    NOT NULL,
    liked                   VARCHAR(20)     NOT NULL,
    shared                  VARCHAR(20)     NOT NULL,
    added_to_cart            VARCHAR(20)     NOT NULL,
    CONSTRAINT pk_dim_behavior PRIMARY KEY (behavior_id),
    CONSTRAINT uq_dim_behavior_natural UNIQUE (browsing_time_min, liked, shared, added_to_cart),
    CONSTRAINT ck_dim_behavior_liked   CHECK (liked IN ('0', '1')),
    CONSTRAINT ck_dim_behavior_shared  CHECK (shared IN ('0', '1')),
    CONSTRAINT ck_dim_behavior_cart    CHECK (added_to_cart IN ('0', '1')),
    CONSTRAINT ck_dim_behavior_time    CHECK (browsing_time_min >= 0)
);


-- FACT_SALES
CREATE TABLE fact_sales (
    sales_fact_key        BIGSERIAL       NOT NULL,
    customer_key          INT             NOT NULL,
    geography_key         INT             NOT NULL,
    date_key              INT             NOT NULL,
    product_key           INT             NOT NULL,
    order_key             INT             NOT NULL,
    behavior_key          INT             NOT NULL,

    sales_amount          DECIMAL(12,2)   NOT NULL,
    quantity              INT             NOT NULL,
    discount_rate         DECIMAL(6,4)    NOT NULL,
    profit_amount         DECIMAL(12,2)   NOT NULL,
    shipping_cost         DECIMAL(12,2)   NOT NULL,
    load_date              TIMESTAMP      NOT NULL DEFAULT now(),

    CONSTRAINT pk_fact_sales PRIMARY KEY (sales_fact_key),

    CONSTRAINT fk_fact_sales_customer
        FOREIGN KEY (customer_key) REFERENCES dim_customer (customer_id_pk),
    CONSTRAINT fk_fact_sales_geography
        FOREIGN KEY (geography_key) REFERENCES dim_geography (geography_id),
    CONSTRAINT fk_fact_sales_date
        FOREIGN KEY (date_key) REFERENCES dim_date (date_id),
    CONSTRAINT fk_fact_sales_product
        FOREIGN KEY (product_key) REFERENCES dim_product (product_id),
    CONSTRAINT fk_fact_sales_order
        FOREIGN KEY (order_key) REFERENCES dim_order (order_id_pk),
    CONSTRAINT fk_fact_sales_behavior
        FOREIGN KEY (behavior_key) REFERENCES dim_behavior (behavior_id),

    CONSTRAINT ck_fact_sales_amount        CHECK (sales_amount >= 0),
    CONSTRAINT ck_fact_sales_quantity      CHECK (quantity > 0),
    CONSTRAINT ck_fact_sales_discount      CHECK (discount_rate BETWEEN 0 AND 1),
    CONSTRAINT ck_fact_sales_shipping_cost CHECK (shipping_cost >= 0)
);

-- indices sobre FKs
CREATE INDEX ix_fact_sales_customer_key  ON fact_sales (customer_key);
CREATE INDEX ix_fact_sales_geography_key ON fact_sales (geography_key);
CREATE INDEX ix_fact_sales_date_key      ON fact_sales (date_key);
CREATE INDEX ix_fact_sales_product_key   ON fact_sales (product_key);
CREATE INDEX ix_fact_sales_order_key     ON fact_sales (order_key);
CREATE INDEX ix_fact_sales_behavior_key  ON fact_sales (behavior_key);

-- indice compuesto para el tablero del proceso de negocio
CREATE INDEX ix_fact_sales_date_product ON fact_sales (date_key, product_key);


