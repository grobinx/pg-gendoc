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
	10. [`_r_cron_id_seq`](#_r_cron_id_seq)
	11. [`_run`](#_run)
	12. [`_start`](#_start)
	13. [`_stop`](#_stop)
	14. [`_sys_crontab`](#_sys_crontab)
	15. [`_sys_crontab_l`](#_sys_crontab_l)
	16. [`_w_cron_id_seq`](#_w_cron_id_seq)
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
	28. [`web_active`](#web_active)
	29. [`web_add`](#web_add)
	30. [`web_change`](#web_change)
	31. [`web_frequence`](#web_frequence)
	32. [`web_json_list`](#web_json_list)
	33. [`web_json_list_get`](#web_json_list_get)
	34. [`web_json_log_list`](#web_json_log_list)
	35. [`web_json_log_list_get`](#web_json_log_list_get)
	36. [`web_list`](#web_list)
	37. [`web_log_list`](#web_log_list)
	38. [`web_remove`](#web_remove)
2. ### [Tabele](#tables)
	1. [`ctrl`](#ctrl) <p>Tablica ctrl zawiera wartości parametrów konfiguracji mechanizmu CRON po stronie bazy danych. Takie jak użytkownik i hasło. Tabela ctrl jest dostępna tylko dla użytkownika CRON.</p>
	2. [`log`](#log) <p>Tablica logująca zawiera informacje o czasie wykonania, godzinie rozpoczęcia oraz godzinie zakończenia, informacje czy zadanie zakończyło się sukcesem oraz jeśli zadanie zakończyło się wyjątkiem – jego treść. Rekord do tablicy dodawany jest w chwili rozpoczęcia zadania. Gdy zadanie się zakończy uaktualniana jest tylko informacja o czasie jego zakończenia. </p>
3. ### [Widoki](#views)
	1. [`_crontab_l`](#_crontab_l)
	2. [`pg_list`](#pg_list) <p>Lista aktualnych zadań CRON dla aktualnej bazy danych.
Superuser widzi zadania z wszystkich baz danych.</p>

<a name="tables"></a>

## Tabele

<a name="ctrl"></a>

### ctrl

Tablica ctrl zawiera wartości parametrów konfiguracji mechanizmu CRON po stronie bazy danych. Takie jak użytkownik i hasło. Tabela ctrl jest dostępna tylko dla użytkownika CRON.

Table columns
| No |Name|Type|Default value|Null| PK | FK |Description|
|---:|----|----|-------------|:--:|:--:|:--:|-----------|
|1|name|name||false|true|false|Nazwa parametru|
|2|value|text||true|false|false|Wartość parametru|

<a name="log"></a>

### log

Tablica logująca zawiera informacje o czasie wykonania, godzinie rozpoczęcia oraz godzinie zakończenia, informacje czy zadanie zakończyło się sukcesem oraz jeśli zadanie zakończyło się wyjątkiem – jego treść. Rekord do tablicy dodawany jest w chwili rozpoczęcia zadania. Gdy zadanie się zakończy uaktualniana jest tylko informacja o czasie jego zakończenia. 

Table columns
| No |Name|Type|Default value|Null| PK | FK |Description|
|---:|----|----|-------------|:--:|:--:|:--:|-----------|
|1|ilog|bigserial|nextval('cron.log_ilog_seq'::regclass)|false|true|false|Identyfikator rekordu|
|2|start|timestamp without time zone||true|false|false|Data i godzina rozpoczęcia zadania|
|3|stop|timestamp without time zone||true|false|false|Data i godzina zakończenia zadania|
|4|minute|character varying||true|false|false|Wartość kolumny minute z crona|
|5|hour|character varying||true|false|false|Wartość kolumny hour z crona|
|6|dayofmonth|character varying||true|false|false|Wartość kolumny dayofmonth z crona|
|7|month|character varying||true|false|false|Wartość kolumny month z crona|
|8|dayofweek|character varying||true|false|false|Wartość kolumny dayofweek z crona|
|9|command|text||true|false|false|Wykonywana komenda SQL|
|10|jobid|numeric||true|false|false|Wartość parametru abrokenflag|
|11|success|boolean|true|true|false|false|Czy zadanie zakończyło się sukcesem|
|12|exception|text||true|false|false|Treść wyjątku jeśli nastąpi|

