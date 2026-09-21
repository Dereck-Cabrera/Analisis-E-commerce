/* 
   PROYECTO 1 · ELECTRONIC ROXX SHOPPING
   Universidad Rafael Landívar · Ciencia de Datos
   Jairo Omar Salazar Chávez 
   DDL - Data Warehouse - v3
   Dereck Alexander Cabrera NG - 1177223
   Mario Miguel Arevalo Perez  - 1072123
   */

--  ESQUEMA

DROP SCHEMA IF EXISTS dw_roxx CASCADE;
CREATE SCHEMA dw_roxx;
SET search_path TO dw_roxx;


-- DIM_DATE
-- Dimensión de calendario y fiscal, generada con dimdates.com y
-- transformada en Tableau Prep (recipe "DIM_DATE"). DateId se genera
-- como ROW_NUMBER() secuencial (no como YYYYMMDD).

CREATE TABLE dim_date (
    date_id                      INT             NOT NULL,          -- llave (ROW_NUMBER secuencial)
    day_name                     VARCHAR(20)     NOT NULL,
    month_name                   VARCHAR(20)     NOT NULL,
    calendar_full_date           DATE            NOT NULL,
    calendar_day                 SMALLINT        NOT NULL,
    calendar_day_in_week         SMALLINT        NOT NULL,
    calendar_day_in_month        SMALLINT        NOT NULL,
    calendar_day_in_quarter      SMALLINT        NOT NULL,
    calendar_day_in_year         SMALLINT        NOT NULL,
    calendar_week                SMALLINT        NOT NULL,
    calendar_month               SMALLINT        NOT NULL,
    calendar_quarter             SMALLINT        NOT NULL,
    calendar_year                SMALLINT        NOT NULL,
    fiscal_full_date             DATE            NOT NULL,
    fiscal_day                   SMALLINT        NOT NULL,
    fiscal_day_in_week           SMALLINT        NOT NULL,
    fiscal_day_in_month          SMALLINT        NOT NULL,
    fiscal_day_in_quarter        SMALLINT        NOT NULL,
    fiscal_day_in_year           SMALLINT        NOT NULL,
    fiscal_week                  SMALLINT        NOT NULL,
    fiscal_month                 SMALLINT        NOT NULL,
    fiscal_quarter                SMALLINT        NOT NULL,
    fiscal_year                  SMALLINT        NOT NULL,
    first_or_last_day_in_week    VARCHAR(20)     NOT NULL,
    first_or_last_day_in_month   VARCHAR(20)     NOT NULL,
    first_or_last_day_in_year    VARCHAR(20)     NOT NULL,
    weekend_or_weekday           VARCHAR(20)     NOT NULL,
    leap_year                    VARCHAR(20)     NOT NULL,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_id),
    CONSTRAINT uq_dim_date_full_date UNIQUE (calendar_full_date),
    CONSTRAINT ck_dim_date_calendar_month CHECK (calendar_month BETWEEN 1 AND 12),
    CONSTRAINT ck_dim_date_calendar_quarter CHECK (calendar_quarter BETWEEN 1 AND 4),
    CONSTRAINT ck_dim_date_weekend CHECK (weekend_or_weekday IN ('WEEKEND', 'WEEKDAY')),
    CONSTRAINT ck_dim_date_leap_year CHECK (leap_year IN ('LEAP YEAR', 'NOT LEAP YEAR'))
);

-- DIM_GEOGRAPHY
CREATE TABLE dim_geography (
    geography_id        SERIAL          NOT NULL,
    city                VARCHAR(80)     NOT NULL,
    state               VARCHAR(80)     NOT NULL,
    country             VARCHAR(80)     NOT NULL,
    region              VARCHAR(80)     NOT NULL DEFAULT 'DESCONOCIDO',
    CONSTRAINT pk_dim_geography PRIMARY KEY (geography_id),
    CONSTRAINT ck_dim_geography_region CHECK (
        region IN (
            'AFRICA', 'CANADA', 'CARIBBEAN', 'CENTRAL', 'CENTRAL ASIA', 'EAST',
            'EMEA', 'NORTH', 'NORTH ASIA', 'OCEANIA', 'SOUTH', 'SOUTHEAST ASIA',
            'DESCONOCIDO'
        )
    )
    -- Nota v3: se eliminó el UNIQUE (city, state, country, region) porque el
    -- propio perfilamiento del ETL detectó combinaciones de ciudad/región
    -- duplicadas que el equipo decidió conservar a propósito ("Existen datos
    -- duplicados, pero se decidió dejarlos ya que de lo contrario se
    -- perderían datos" - ver recipe Clean 3 de DIM_GEOGRAPHY).
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
    CONSTRAINT ck_dim_customer_gender CHECK (gender IN ('MALE', 'FEMALE')),
    CONSTRAINT ck_dim_customer_segment CHECK (segment IN ('CONSUMER', 'CORPORATE', 'HOME OFFICE')),
    CONSTRAINT ck_dim_customer_marital CHECK (marital_status IN ('SINGLE', 'MARRIED')),
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
        product_category IN ('AUTO & ACCESSORIES', 'ELECTRONIC', 'HOME & FURNITURE', 'FASHION')
    )
);



-- DIM_ORDER 
CREATE TABLE dim_order (
    order_id_pk             SERIAL          NOT NULL,          -- llave  
    order_id                VARCHAR(80)     NOT NULL,          -- llave natural del origen 
    order_priority          VARCHAR(20)     NOT NULL DEFAULT 'DESCONOCIDO',
    ship_mode               VARCHAR(80)     NOT NULL DEFAULT 'DESCONOCIDO',
    CONSTRAINT pk_dim_order PRIMARY KEY (order_id_pk),
    CONSTRAINT uq_dim_order_natural UNIQUE (order_id),
    CONSTRAINT ck_dim_order_priority CHECK (
        order_priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'DESCONOCIDO')
    ),
    CONSTRAINT ck_dim_order_ship_mode CHECK (
        ship_mode IN ('STANDARD CLASS', 'SECOND CLASS', 'FIRST CLASS', 'SAME DAY', 'DESCONOCIDO')
    )
    -- Nota v3: se eliminó el filtro que excluía únicamente el código '45788'
    -- porque ahora el propio CHECK rechaza cualquier valor de ship_mode que
    -- no pertenezca al dominio válido, incluyendo ese caso.
);



-- DIM_BEHAVIOR
-- Nota v3: liked/shared/added_to_cart pasaron de '0'/'1' a texto
-- descriptivo, tal como se transformó en el recipe "Clean 2" de
-- DIM_BEHAVIOR (Tableau Prep).
CREATE TABLE dim_behavior (
    behavior_id             SERIAL          NOT NULL,
    browsing_time_min       DECIMAL(8,2)    NOT NULL,
    liked                   VARCHAR(20)     NOT NULL,
    shared                  VARCHAR(20)     NOT NULL,
    added_to_cart            VARCHAR(20)     NOT NULL,
    CONSTRAINT pk_dim_behavior PRIMARY KEY (behavior_id),
    CONSTRAINT uq_dim_behavior_natural UNIQUE (browsing_time_min, liked, shared, added_to_cart),
    CONSTRAINT ck_dim_behavior_liked   CHECK (liked IN ('LIKED', 'NOT LIKED')),
    CONSTRAINT ck_dim_behavior_shared  CHECK (shared IN ('SHARED', 'NOT SHARED')),
    CONSTRAINT ck_dim_behavior_cart    CHECK (added_to_cart IN ('ADDED TO CART', 'NOT ADDED TO CART')),
    CONSTRAINT ck_dim_behavior_time    CHECK (browsing_time_min >= 0)
);


-- FACT_SALES
-- Nota v3: se agregan category_key, shipping_key (sin FK; ver nota de
-- diseño en el manual técnico) y unit_price (calculado en el ETL como
-- ROUND(Sales / Quantity, 2)).
CREATE TABLE fact_sales (
    sales_fact_key        BIGSERIAL       NOT NULL,
    customer_key          INT             NOT NULL,
    geography_key         INT             NOT NULL,
    date_key              INT             NOT NULL,
    product_key           INT             NOT NULL,
    order_key             INT             NOT NULL,
    behavior_key          INT             NOT NULL,
    category_key          INT,                              -- sin dimensión propia (ver nota v3)
    shipping_key          INT,                              -- sin dimensión propia (ver nota v3)

    sales_amount          DECIMAL(12,2)   NOT NULL,
    quantity              INT             NOT NULL,
    discount_rate         DECIMAL(6,4)    NOT NULL,
    profit_amount         DECIMAL(12,2)   NOT NULL,
    shipping_cost         DECIMAL(12,2)   NOT NULL,
    unit_price             DECIMAL(12,2)  NOT NULL,          -- calculado: ROUND(sales_amount / quantity, 2)
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
    CONSTRAINT ck_fact_sales_shipping_cost CHECK (shipping_cost >= 0),
    CONSTRAINT ck_fact_sales_unit_price    CHECK (unit_price >= 0)
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