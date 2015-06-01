-- Table: stat_compiled.journey_cities

DROP TABLE IF EXISTS stat_compiled.journey_cities CASCADE;

CREATE TABLE stat_compiled.journey_cities
(
  journey_id bigint NOT NULL,
  city_id text NOT NULL,
  city_insee text,
  city_name text,
  department_code text,
  request_date timestamp without time zone,
  is_start_city boolean,
  is_end_city boolean,
  CONSTRAINT journey_cities_pkey PRIMARY KEY (journey_id, city_id)
)
WITH (
  OIDS=FALSE
);

CREATE INDEX journey_cities_end_city
  ON stat_compiled.journey_cities
  USING btree
  (journey_id, is_end_city);

CREATE INDEX journey_cities_start_city
  ON stat_compiled.journey_cities
  USING btree
  (journey_id, is_start_city);


CREATE OR REPLACE FUNCTION journey_cities_insert_trigger()
RETURNS TRIGGER AS $$
DECLARE
  schema VARCHAR(100);
  partition VARCHAR(100);
BEGIN
  schema := 'stat_compiled';
  partition := 'journey_cities' || '_' || to_char(NEW.request_date, '"y"YYYY"m"MM');
  IF NOT EXISTS(SELECT 1 FROM pg_tables WHERE tablename=partition and schemaname=schema) THEN
    RAISE NOTICE 'A partition has been created %',partition;
    EXECUTE 'CREATE TABLE IF NOT EXISTS ' || schema || '.' || partition || 
            ' (check (request_date >= DATE ''' || to_char(NEW.request_date, 'YYYY-MM-01') || ''' 
                      AND request_date < DATE ''' || to_char(NEW.request_date + interval '1 month', 'YYYY-MM-01') || ''') ) ' || 
            'INHERITS (' || schema || '.journey_cities);';
  END IF;
  EXECUTE 'INSERT INTO ' || schema || '.' || partition || ' SELECT(' || schema || '.journey_cities' || ' ' || quote_literal(NEW) || ').*;';
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER insert_journey_cities_trigger
    BEFORE INSERT ON stat_compiled.journey_cities
    FOR EACH ROW EXECUTE PROCEDURE journey_cities_insert_trigger();

DROP TABLE IF EXISTS stat_compiled.journey_cities_y2014m05;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2014m06;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2014m07;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2014m08;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2014m09;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2014m10;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2014m11;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2014m12;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2015m01;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2015m02;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2015m03;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2015m04;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2015m05;
DROP TABLE IF EXISTS stat_compiled.journey_cities_y2015m06;

CREATE TABLE stat_compiled.journey_cities_y2014m05 ( CHECK (request_date >= DATE '2014-05-01' AND request_date < DATE '2014-06-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2014m06 ( CHECK (request_date >= DATE '2014-06-01' AND request_date < DATE '2014-07-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2014m07 ( CHECK (request_date >= DATE '2014-07-01' AND request_date < DATE '2014-08-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2014m08 ( CHECK (request_date >= DATE '2014-08-01' AND request_date < DATE '2014-09-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2014m09 ( CHECK (request_date >= DATE '2014-09-01' AND request_date < DATE '2014-10-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2014m10 ( CHECK (request_date >= DATE '2014-10-01' AND request_date < DATE '2014-11-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2014m11 ( CHECK (request_date >= DATE '2014-11-01' AND request_date < DATE '2014-12-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2014m12 ( CHECK (request_date >= DATE '2014-12-01' AND request_date < DATE '2015-01-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2015m01 ( CHECK (request_date >= DATE '2015-01-01' AND request_date < DATE '2015-02-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2015m02 ( CHECK (request_date >= DATE '2015-02-01' AND request_date < DATE '2015-03-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2015m03 ( CHECK (request_date >= DATE '2015-03-01' AND request_date < DATE '2015-04-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2015m04 ( CHECK (request_date >= DATE '2015-04-01' AND request_date < DATE '2015-05-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2015m05 ( CHECK (request_date >= DATE '2015-05-01' AND request_date < DATE '2015-06-01') ) INHERITS (stat_compiled.journey_cities);
CREATE TABLE stat_compiled.journey_cities_y2015m06 ( CHECK (request_date >= DATE '2015-06-01' AND request_date < DATE '2015-07-01') ) INHERITS (stat_compiled.journey_cities);

INSERT INTO stat_compiled.journey_cities
(
  journey_id,
  city_id,
  city_insee,
  city_name,
  department_code,
  request_date,
  is_start_city,
  is_end_city
)
SELECT DISTINCT
    A.journey_id,
    A.city_id,
    A.city_insee,
    A.city_name,
    A.department_code,
    A.request_date,
    CASE WHEN A.city_id=B.dep_city_id THEN TRUE ELSE FALSE END AS is_start_city,
    CASE WHEN A.city_id=B.arr_city_id THEN TRUE ELSE FALSE END AS is_end_city
FROM (
    SELECT
        journey_id,
        request_date,
        to_admin_id as city_id,
        to_admin_name as city_name,
        to_admin_insee as city_insee,
        substring(to_admin_insee, 1, 2) as department_code
    FROM
        stat.journey_sections js
        INNER JOIN stat.requests req ON req.id = js.request_id
    WHERE
        to_admin_id <> ''
    UNION ALL
    SELECT
        journey_id,
        request_date,
        from_admin_id as city_id,
        from_admin_name as city_name,
        from_admin_insee as city_insee,
        substring(from_admin_insee, 1, 2) as department_code
    FROM
        stat.journey_sections js
        INNER JOIN stat.requests req ON req.id = js.request_id
    WHERE
        from_admin_id <> ''
) A,
(
    SELECT DISTINCT dep.journey_id AS journey_id,
                    dep.from_admin_id AS dep_city_id,
                    arr.to_admin_id AS arr_city_id
    FROM stat.journey_sections dep
    INNER JOIN
      (SELECT js.journey_id,
              MIN(js.id) AS dep_id,
              MAX(js.id) AS arr_id
       FROM stat.journey_sections js
       WHERE js.type = 'public_transport'
       GROUP BY js.journey_id) od ON (dep.journey_id = od.journey_id
                                      AND dep.id = od.dep_id)
    INNER JOIN stat.journey_sections arr ON (od.journey_id = arr.journey_id
                                             AND od.arr_id = arr.id)
    INNER JOIN stat.journeys j ON (j.id = dep.journey_id)
) B
WHERE A.journey_id = B.journey_id
;