## Spis treści

1. ### [Funkcje i procedury](#routines)
	1. [`_catch_exception`](#_catch_exception)
	2. [`_create_cron_line`](#_create_cron_line)
	3. [`_get_ctrl`](#_get_ctrl)
	4. [`_get_psql_opt`](#_get_psql_opt)
	5. [`_get_psql_opt`](#_get_psql_opt)
	6. [`_keylock`](#_keylock)
	7. [`_list`](#_list)
	8. [`_parse_cron_line`](#_parse_cron_line)
	9. [`_prepare_command`](#_prepare_command)
	10. [`_r_cron_id_seq`](#_r_cron_id_seq) Get unique id
	11. [`_run`](#_run) Run console command
	12. [`_start`](#_start)
	13. [`_stop`](#_stop)
	14. [`_sys_crontab`](#_sys_crontab) Set crontab content
	15. [`_sys_crontab_l`](#_sys_crontab_l) Get crontab content
	16. [`_w_cron_id_seq`](#_w_cron_id_seq) Set unique id
	17. [`active`](#active)
	18. [`add`](#add)
	19. [`change`](#change)
	20. [`clear_log`](#clear_log)
	21. [`frequence`](#frequence)
	22. [`isexists`](#isexists)
	23. [`pg_list`](#pg_list)
	24. [`remove`](#remove)
	25. [`run`](#run)
	26. [`run`](#run)
	27. [`version`](#version)
2. ### [Tabele](#tables)
	1. [`ctrl`](#ctrl) Wartości parametrów konfiguracji
	2. [`log`](#log) Tabela z logiem
3. ### [Widoki](#views)
	1. [`_crontab_l`](#_crontab_l)
	2. [`pg_list`](#pg_list) Lista aktualnych zadań

<a name="tables"></a>

## Tabele

<a name="ctrl"></a>

### ctrl

Tablica ctrl zawiera wartości parametrów konfiguracji mechanizmu CRON po stronie bazy danych.
Takie jak użytkownik i hasło. Tabela ctrl jest dostępna tylko dla użytkownika CRON.
@summary Wartości parametrów konfiguracji

Kolumny tabeli

|Lp|Nazwa|Typ danych|Wartość domyślna|Null|PK|FK|Opis|
|---:|----|----|----|:--:|:--:|:--:|----|
|1|name|name||true|true|false|Nazwa parametru|
|2|value|text||false|false|false|Wartość parametru|

<a name="log"></a>

### log

Tablica logująca zawiera informacje o czasie wykonania, godzinie rozpoczęcia oraz godzinie zakończenia, informacje czy zadanie zakończyło się sukcesem oraz jeśli zadanie zakończyło się wyjątkiem – jego treść.
Rekord do tablicy dodawany jest w chwili rozpoczęcia zadania. Gdy zadanie się zakończy uaktualniana jest tylko informacja o czasie jego zakończenia. 
@summary Tabela z logiem

Kolumny tabeli

|Lp|Nazwa|Typ danych|Wartość domyślna|Null|PK|FK|Opis|
|---:|----|----|----|:--:|:--:|:--:|----|
|1|ilog|bigserial|nextval('cron.log_ilog_seq'::regclass)|true|true|false|Identyfikator rekordu|
|2|start|timestamp without time zone||false|false|false|Data i godzina rozpoczęcia zadania|
|3|stop|timestamp without time zone||false|false|false|Data i godzina zakończenia zadania|
|4|minute|character varying||false|false|false|Wartość kolumny minute z crona|
|5|hour|character varying||false|false|false|Wartość kolumny hour z crona|
|6|dayofmonth|character varying||false|false|false|Wartość kolumny dayofmonth z crona|
|7|month|character varying||false|false|false|Wartość kolumny month z crona|
|8|dayofweek|character varying||false|false|false|Wartość kolumny dayofweek z crona|
|9|command|text||false|false|false|Wykonywana komenda SQL|
|10|jobid|numeric||false|false|false|Wartość parametru abrokenflag|
|11|success|boolean|true|false|false|false|Czy zadanie zakończyło się sukcesem|
|12|exception|text||false|false|false|Treść wyjątku jeśli nastąpi|

