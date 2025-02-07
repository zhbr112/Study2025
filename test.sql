DO $$
begin


begin

-- Звания
create table military_ranks
(
  id integer primary key not null,
  description character varying(255)
);
create sequence military_ranks_seq;
alter table military_ranks alter column id set default nextval('public.military_ranks_seq');
insert into military_ranks(description)
values('Рядовой'),('Лейтенант');

-- Пользователи
create table employees
(
  id integer primary key not null,
  name text,
  birthday timestamp ,
  military_rank_id integer REFERENCES military_ranks(id)
);
create sequence employees_seq;
alter table employees alter column id set default nextval('public.employees_seq');
insert into employees(name, birthday, military_rank_id )  
values('Воловиков Александр Сергеевич', '1978-06-24', 2);

-- Устройства для измерения
create table measurment_types
(
   id integer primary key not null,
   short_name  character varying(50),
   description text 
);
create sequence measurment_types_seq;
alter table measurment_types alter column id set default nextval('measurment_types_seq');
insert into measurment_types(short_name, description)
values('ДМК', 'Десантный метео комплекс'), ('ВР', 'Ветровое ружье');

-- Таблица с параметрами
create table measurment_input_params
(
  id integer primary key not null,
  measurment_type_id integer not null REFERENCES measurment_types(id),
  height numeric(8,2) default 0,
  temperature numeric(8,2) default 0,
  pressure numeric(8,2) default 0,
  wind_direction numeric(8,2) default 0,
  wind_speed numeric(8,2) default 0
);
create sequence measurment_input_params_seq;
alter table measurment_input_params alter column id set default nextval('measurment_input_params_seq');
insert into measurment_input_params(measurment_type_id, height, temperature, pressure, wind_direction,wind_speed )
values(1, 100,12,34,0.2,45);

-- Таблица с историей
create table measurment_baths
(
  id integer primary key not null,
  employee_id integer not null REFERENCES employees(id),
  measurment_input_param_id integer not null REFERENCES measurment_input_params(id),
  started timestamp default now()
);
create sequence measurment_baths_seq;
alter table measurment_baths alter column id set default nextval('measurment_baths_seq');
insert into measurment_baths(employee_id, measurment_input_param_id)
values(1, 1);

commit;
END;


BEGIN

CREATE TABLE temperature_corrections
(
  id integer PRIMARY key not null,
  temperature numeric,
  correction numeric
);
CREATE SEQUENCE temperature_correction_seq;
alter table temperature_corrections alter COLUMN id set default nextval('temperature_correction_seq');
INSERT into temperature_corrections(temperature, correction)
values(0, 0),(5,0.5),(10, 1),(15, 1),(20, 1.5),(25, 2),(30, 3.5),(40, 4.5);

CREATE TYPE interpolation as (t1 numeric, t2 numeric, c1 numeric, c2 numeric, temperature numeric);

CREATE FUNCTION get_interpolation(temp1 numeric) 
RETURNS interpolation 
LANGUAGE plpgsql as $func$ 
DECLARE 
	interpolat interpolation;
BEGIN
	Select t1,t2,c1,c2,temp1 as interpolation into interpolat from 
	(SELECT temperature as t1, correction as c1  from temperature_corrections where temperature<=temp1 order by temperature DESC limit 1)
	full join
	(SELECT temperature as t2, correction as c2 from temperature_corrections where temperature>=temp1 order by temperature limit 1)
	on true limit 1;

	RETURN interpolat;
END;
$func$;

CREATE FUNCTION interpolation2corrections(interpol interpolation) 
RETURNS NUMERIC
LANGUAGE plpgsql as $func$
DECLARE 
	correction NUMERIC;
BEGIN
	Select interpol.c1+((interpol.temperature-interpol.t1)/(interpol.t2-interpol.t1))*(interpol.c2-interpol.c1)
	INTO correction;

	RETURN correction;
END;
$func$;

commit;
END;


end$$;


--select interpolation2corrections(get_interpolation(22));