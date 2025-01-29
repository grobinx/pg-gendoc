# Schemat "cron" - Wersja 1.1.14 - Pakiet ["core"]<small>&nbsp;	2025-01-29 23:13:39</small>

## Spis treści

1. [Funkcje i procedury](#Funkcje-i-procedury)
	1. [`active`](#active) Aktywacja zadania
	2. [`add`](#add) Dodaje nowe zadanie do crona.
	3. [`_catch_exception`](#_catch_exception)
	4. [`change`](#change) Zmiana polecenia
	5. [`clear_log`](#clear_log) Czyszczenie log-a
	6. [`_create_cron_line`](#_create_cron_line)
	7. [`frequence`](#frequence) Pozwala zmienić częstototliwość wykonywania zadania.
	8. [`_get_ctrl`](#_get_ctrl)
	9. [`_get_psql_opt`](#_get_psql_opt)
	10. [`_get_psql_opt`](#_get_psql_opt)
	11. [`isexists`](#isexists)
	12. [`_keylock`](#_keylock) Generate global lock key
	13. [`_list`](#_list)
	14. [`_parse_cron_line`](#_parse_cron_line)
	15. [`pg_list`](#pg_list)
	16. [`_prepare_command`](#_prepare_command)
	17. [`_r_cron_id_seq`](#_r_cron_id_seq) Get unique id
	18. [`remove`](#remove) Usuwa zadanie z CRON-a
	19. [`_run`](#_run) Run console command
	20. [`run`](#run) Pozwala natychmiast wykonać polecenie z zadania
	21. [`run`](#run) Dodaje nowe zadanie do crona. Wykonane zostanie natychmiast i zostanie usunięte z lity
	22. [`_start`](#_start)
	23. [`_stop`](#_stop)
	24. [`_sys_crontab`](#_sys_crontab) Set crontab content
	25. [`_sys_crontab_l`](#_sys_crontab_l) Get crontab content
	26. [`version`](#version) Funkcja zwraca wersję pakietu.
	27. [`_w_cron_id_seq`](#_w_cron_id_seq) Set unique id
2. [Tabele](#Tabele)
	1. [`ctrl`](#ctrl) Parametry konfiguracji
	2. [`log`](#log) Tabela z logiem
3. [Widoki](#Widoki)
	1. [`_crontab_l`](#_crontab_l) cron native line with id if exists
	2. [`pg_list`](#pg_list) Lista aktualnych zadań


## Funkcje i procedury

### active <small>(function)</small>

<code>active(ajobid, aactive)</code> → <code>integer</code>

Pozwala aktywować wybrane zadanie.

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ajobid|integer||in|Identyfikator zadania|
|2|aactive|character varying||in|Nowa wartość dla parametru active (Y/N)|

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Publiczne** true

#### Podsumowanie

Aktywacja zadania

#### Zwraca

> **Typ danych** `integer`

---

### add <small>(function)</small>

<code>add(acommand, aminute, ahour<sup>opc</sup>, adayofmonth<sup>opc</sup>, amonth<sup>opc</sup>, adayofweek<sup>opc</sup>, ajobid<sup>opc</sup>, aactive<sup>opc</sup>, aautoremove<sup>opc</sup>, arole<sup>opc</sup>)</code> → <code>integer</code>

Dodaje nowe zadanie do crona.

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|acommand|character varying||in|Komenda SQL która zostanie wykonana|
|2|aminute|character varying||in|Minuta wykonania (0-59)|
|3|ahour|character varying|NULL::character varying|in|Godzina wykonania (0-23)|
|4|adayofmonth|character varying|NULL::character varying|in|Dzień miesiąca wykonania (1-31)|
|5|amonth|character varying|NULL::character varying|in|Miesiąc wykonania (1-12) lub (JAN, FEB, MAR, etc.)|
|6|adayofweek|character varying|NULL::character varying|in|Dzień tygodnia wykonania (0-6) lub (MON, TUE, WED, etc.)|
|7|ajobid|integer|NULL::integer|in|(NULL) Identyfikator zadania, jeśli nowe to null|
|8|aactive|character varying|NULL::character varying|in|(NULL) Przyjmuje wartość „Y” lub „N”. Zadanie dodane jako broken nie zostanie wykonane. Do CRON’a zostanie dodano jako zakomentowane|
|9|aautoremove|boolean|false|in|(FALSE) Czy zadanie jednorazowe – ma być usunięte po wykonaniu|
|10|arole|character varying|NULL::character varying|in|(od 1.0.3) (NULL) Rola w ramach której zadanie ma zostać uruchomione|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 1.0.3
>
> **Dostępna od** 1.0
>
> **Pakiet** core
>
> **Publiczne** true

Przykład

````sql
-- Dodanie zadania do crona. Zadanie będzie się wykonywać co miesiąc 6 dnia miesiąca o godzinie 15:30.
select cron.add('perform public.test_function(''some_param'')', '30', '15', '6');
````

#### Zwraca

jobid

> **Typ danych** `integer`

---

### _catch_exception <small>(function)</small>

<code>_catch_exception(aerrm, ailog)</code> → <code>void</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aerrm|text||in||
|2|ailog|bigint||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

---

### change <small>(function)</small>

<code>change(ajobid, acommand)</code> → <code>integer</code>

Pozwala zmienić polecenie SQL w istniejącym zadaniu.

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ajobid|integer||in|Identyfikator zadania|
|2|acommand|text||in|Nowe polecenie SQL|

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Publiczne** true

#### Podsumowanie

Zmiana polecenia

#### Zwraca

> **Typ danych** `integer`

---

### clear_log <small>(function)</small>

<code>clear_log()</code> → <code>void</code>

Pozwala wyczyścić log zgodnie z opcją log.interval (domyślnie 1 miesiąc).



Można dodać wywołanie tej funkcji jako codzienne zadanie CRON by log-i nie przyrastały zbytnio.

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Publiczne** true

Przykład

````sql
-- Poniższy przykład demonstruje jak dodać zadanie z czyszczeniem log-a. Zadanie to będzie wykonywane codziennie o godzinie 0:15.
do $$
begin
  perform add('perform clear_log()', '15', '0');
end;
````

#### Podsumowanie

Czyszczenie log-a

---

### _create_cron_line <small>(function)</small>

<code>_create_cron_line(apgjobid, aactive, aminute, ahour, adayofmonth, amonth, adayofweek, acommand)</code> → <code>text</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|apgjobid|bigint||in||
|2|aactive|character varying||in||
|3|aminute|character varying||in||
|4|ahour|character varying||in||
|5|adayofmonth|character varying||in||
|6|amonth|character varying||in||
|7|adayofweek|character varying||in||
|8|acommand|text||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Zwraca

> **Typ danych** `text`

---

### frequence <small>(function)</small>

<code>frequence(ajobid, aminute, ahour<sup>opc</sup>, adayofmonth<sup>opc</sup>, amonth<sup>opc</sup>, adayofweek<sup>opc</sup>)</code> → <code>integer</code>

Pozwala zmienić częstototliwość wykonywania zadania.

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ajobid|integer||in|Identyfikator zadania|
|2|aminute|character varying||in|Minuta wykonania (0-59)|
|3|ahour|character varying|NULL::character varying|in|Godzina wykonania (0-23)|
|4|adayofmonth|character varying|NULL::character varying|in|Dzień miesiąca wykonania (1-31)|
|5|amonth|character varying|NULL::character varying|in|Miesiąc wykonania (1-12) lub (JAN, FEB, MAR, etc.)|
|6|adayofweek|character varying|NULL::character varying|in|Dzień tygodnia wykonania (0-6) lub (MON, TUE, WED, etc.)|

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Publiczne** true

#### Zwraca

> **Typ danych** `integer`

---

### _get_ctrl <small>(function)</small>

<code>_get_ctrl(aname, adefaultvalue<sup>opc</sup>)</code> → <code>text</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aname|name||in||
|2|adefaultvalue|text|NULL::text|in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Zwraca

> **Typ danych** `text`

---

### _get_psql_opt <small>(function)</small>

<code>_get_psql_opt(aopt, acommand)</code> → <code>text</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aopt|integer||in||
|2|acommand|text||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Zwraca

> **Typ danych** `text`

---

### _get_psql_opt <small>(function)</small>

<code>_get_psql_opt(aopt, acommand)</code> → <code>text</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aopt|text||in||
|2|acommand|text||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Zwraca

> **Typ danych** `text`

---

### isexists <small>(function)</small>

<code>isexists(ajobid)</code> → <code>integer</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ajobid|integer||in||


#### Zwraca

> **Typ danych** `integer`

---

### _keylock <small>(function)</small>

<code>_keylock()</code> → <code>bigint</code>

Generate global lock key

>
> **Autor** Andrzej Kałuża
>
> **Dostępna od** 1.0.10
>
> **Pakiet** core
>
> **Prywatne** true

#### Zwraca

> **Typ danych** `bigint`

---

### _list <small>(function)</small>

<code>_list()</code> → <code>record</code>

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Zwraca

> **Typ danych** `TABLE(pgjobid bigint, active character varying, minute character varying, hour character varying, dayofmonth character varying, month character varying, dayofweek character varying, command text)`

---

### _parse_cron_line <small>(function)</small>

<code>_parse_cron_line(aline)</code> → <code>character varying[]</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|aline|text||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Zwraca

> **Typ danych** `character varying[]`

---

### pg_list <small>(function)</small>

<code>pg_list()</code> → <code>record</code>


#### Zwraca

> **Typ danych** `TABLE(jobid bigint, database character varying, role character varying, minute character varying, hour character varying, dayofmonth character varying, month character varying, dayofweek character varying, last_start timestamp without time zone, this_start timestamp without time zone, total_time bigint, failures bigint, times bigint, command text, active character varying, autoremove character varying)`

---

### _prepare_command <small>(function)</small>

<code>_prepare_command(ajobid, acommand, aautoremove<sup>opc</sup>, arole<sup>opc</sup>)</code> → <code>text</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ajobid|bigint||in||
|2|acommand|text||in||
|3|aautoremove|boolean|false|in||
|4|arole|character varying|NULL::character varying|in||

>
> **Wersja** 1.1
>
> **Dostępna od** 1.0.0
>
> **Pakiet** core
>
> **Prywatne** true

#### Zmiany

>
> 1.1 - dodanie podmiany $(jobid) identyfikatorem zadania

#### Zwraca

> **Typ danych** `text`

---

### _r_cron_id_seq <small>(function)</small>

<code>_r_cron_id_seq()</code> → <code>character varying</code>

Get unique id for all PostgreSQL instances

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Podsumowanie

Get unique id

#### Zwraca

> **Typ danych** `character varying`

---

### remove <small>(function)</small>

<code>remove(ajobid)</code> → <code>integer</code>

Usuwa zadanie z CRON-a

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ajobid|integer||in|Identyfikator zadania|

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Publiczne** true

#### Zwraca

> **Typ danych** `integer`

---

### _run <small>(function)</small>

<code>_run(acommand)</code> → <code>character varying</code>

Function for run command on system console

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|acommand|text||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Podsumowanie

Run console command

#### Zwraca

> **Typ danych** `character varying`

---

### run <small>(function)</small>

<code>run(ajobid)</code> → <code>text</code>

Pozwala natychmiast wykonać polecenie z zadania

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ajobid|integer||in|Identyfikator zadania|

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Publiczne** true

#### Zwraca

> **Typ danych** `text`

---

### run <small>(function)</small>

<code>run(acommand, arole<sup>opc</sup>)</code> → <code>integer</code>

Dodaje nowe zadanie do crona. Wykonane zostanie natychmiast i zostanie usunięte z lity

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|acommand|character varying||in|Polecenie SQL która zostanie wykonana|
|2|arole|character varying|NULL::character varying|in|(NULL) Rola w ramach której zadanie ma zostać uruchomione|

>
> **Autor** Andrzej Kałuża
>
> **Wersja** 2.0
>
> **Dostępna od** 1.0.8
>
> **Pakiet** core
>
> **Publiczne** true

#### Zmiany

>
> 2024-12-05 Andrzej Kałuża - teraz wykona się na pewno zawsze

#### Zwraca

> **Typ danych** `integer`

---

### _start <small>(function)</small>

<code>_start(ajobid)</code> → <code>bigint</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ajobid|bigint||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Zwraca

> **Typ danych** `bigint`

---

### _stop <small>(function)</small>

<code>_stop(ailog)</code> → <code>void</code>

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|ailog|bigint||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

---

### _sys_crontab <small>(function)</small>

<code>_sys_crontab(adata)</code> → <code>void</code>

Core function to set system crontab content

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|adata|text||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Podsumowanie

Set crontab content

---

### _sys_crontab_l <small>(function)</small>

<code>_sys_crontab_l()</code> → <code>character varying</code>

Core function for get crontab content

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Podsumowanie

Get crontab content

#### Zwraca

> **Typ danych** `character varying`

---

### version <small>(function)</small>

<code>version()</code> → <code>text</code>

Funkcja zwraca wersję pakietu.

>
> **Autor** Andrzej Kałuża
>
> **Dostępna od** 1.0.5
>
> **Pakiet** core
>
> **Publiczne** true

#### Zmiany

>
> 1.0.10 - obsługa poleceń administracyjnych, które nie są poleceniami harmonogramu CRON, np. MAILTO=adres
>
> 1.0.11 - dodanie globalnego locka by dwie lub więcej funkcji nie mogły jednocześnie zmieniać cron-a systemowego
>
> 1.0.12 - dodana została możliwość wstawiania do crona zadań z identyfikatorem zadania <code>cron.add('funckja($(jobid), ...)')</code>, <code>$(jobid)</code> zostanie zastąpiony numerem zadania
>
> 1.1.14 - zmiana nazewnictwa funkcji, porządki z uprawnieniami

#### Zwraca

wersja pakietu w formacie 'major.minor.release'

> **Typ danych** `text`

---

### _w_cron_id_seq <small>(function)</small>

<code>_w_cron_id_seq(adata)</code> → <code>void</code>

Create/write unique id for all PostgreSQL instances

#### Argumenty

|Lp|Nazwa|Typ danych|Wartość domyślna|Tryb|Opis|
|---:|----|----|----|----|----|
|1|adata|text||in||

>
> **Autor** Andrzej Kałuża
>
> **Pakiet** core
>
> **Prywatne** true

#### Podsumowanie

Set unique id

## Tabele

### ctrl <small>(ordinary)</small>

Tablica ctrl zawiera wartości parametrów konfiguracji mechanizmu CRON po stronie bazy danych.

Takie jak użytkownik i hasło. Tabela ctrl jest dostępna tylko dla użytkownika CRON.

#### Kolumny tabeli

|Lp|Nazwa|Typ danych|Wartość domyślna|Null|PK|FK|Opis|
|---:|----|----|----|----|----|----|----|
|1|name|name||true|true|false|Nazwa parametru|
|2|value|text||false|false|false|Wartość parametru|<dl><dt>Pakiet</dt><dd>core</dd></dl><h4>Podsumowanie</h4><p>Parametry konfiguracji</p>

---

### log <small>(ordinary)</small>

Tablica logująca zawiera informacje o czasie wykonania, godzinie rozpoczęcia oraz godzinie zakończenia, informacje czy zadanie zakończyło się sukcesem oraz jeśli zadanie zakończyło się wyjątkiem – jego treść.

Rekord do tablicy dodawany jest w chwili rozpoczęcia zadania. Gdy zadanie się zakończy uaktualniana jest tylko informacja o czasie jego zakończenia.

#### Kolumny tabeli

|Lp|Nazwa|Typ danych|Wartość domyślna|Null|PK|FK|Opis|
|---:|----|----|----|----|----|----|----|
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
|12|exception|text||false|false|false|Treść wyjątku jeśli nastąpi|<dl><dt>Pakiet</dt><dd>core</dd></dl><h4>Podsumowanie</h4><p>Tabela z logiem</p>

## Widoki

### _crontab_l <small>(view)</small>

cron native line with id if exists

#### Kolumny widoku

|Lp|Nazwa|Typ danych|Opis|
|---:|----|----|----|
|1|pg_line|text||
|2|line|text||<dl><dt>Pakiet</dt><dd>core</dd></dl>

---

### pg_list <small>(view)</small>

Lista aktualnych zadań CRON dla aktualnej bazy danych.

Superuser widzi zadania z wszystkich baz danych.

#### Kolumny widoku

|Lp|Nazwa|Typ danych|Opis|
|---:|----|----|----|
|1|jobid|bigint|Id zadania z sekwencji lokalnej lub globalnej.|
|2|database|character varying|Baza danych dla której utworzono zadanie.|
|3|role|character varying|Rola/Użytkownik w ramach której zadanie będzie wykonane.|
|4|minute|character varying|Minuta w której zadanie będzie wykonane.|
|5|hour|character varying|Godzina w której zadanie będzie wykonane.|
|6|dayofmonth|character varying|Dzień miesiąca w którym zadanie zostanie wykonane.|
|7|month|character varying|Miesiąc wykonania zadania.|
|8|dayofweek|character varying|Dzień tygodnia w którym zadanie będzie wykonane.|
|9|last_start|timestamp without time zone|Ostatnia data i godzina wykonania zadania (z tabeli log)|
|10|this_start|timestamp without time zone|Data i godzina w której rozpoczęto wykonanie tego zadania (z tabeli log)|
|11|total_time|bigint|Całkowity czas wykonania zadania (z tabeli log)|
|12|failures|bigint|Informacja o ilości wykonań zadania, które zakończyły sie błędem (z tabeli log).|
|13|times|bigint|Ilość wykonań zadania (z tabeli log)|
|14|command|text|Polecenie PostgreSQL, które zostanie wykonane.|
|15|active|character varying|Czy zadanie jest aktywne.|
|16|autoremove|character varying|Czy zadanie jest jednorazowe, zostanie automatycznie usunięte po wykonaniu.|<dl><dt>Pakiet</dt><dd>core</dd></dl><h4>Podsumowanie</h4><p>Lista aktualnych zadań</p>

----
<small>GENDOC 2.0.0 - Andrzej Kałuża</small>