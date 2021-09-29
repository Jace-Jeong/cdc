create database inventory;
\c inventory
CREATE TABLE dumb_table(id SERIAL PRIMARY KEY, name VARCHAR);
insert into dumb_table (select 1,1);
