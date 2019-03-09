
# SQL Test <strong>Report</strong>
## Introduction on PostgreSQL Window Functions

Window functions provide a "window" into your data, letting you perform aggregations against a set of data rows according to specified criteria that match the current row. While they are similar to standard aggregations, there are also additional functions that can only be used through window functions (such as the RANK() function I'll use below).

In some situations, window functions can minimize the complexity of your query or even speed up the performance.

Window functions always use the OVER() clause.
Depending on the purpose and complexity of the window function you want to run, you can use OVER() all by itself or with a handful of conditional clauses.
If the aggregation you want to run is to be performed across all the rows returned by the query and you don't need to specify any other conditions, then you can use the OVER() clause by itself.
Please refer to the official documentation if you want know more about it: [PostgreSQL window function](https://www.postgresql.org/docs/current/tutorial-window.html).

## TASK 1: Load Dataset into PostgreSQL
##### We have a small data set of a mobile company available for download here. This extract contains the history of top-up dates and the amounts. Load this dataset into the topups table. Would you able to load this input file as-is (without any manual modifications to it) using the Foreign Table PostgreSQL feature rather than COPY command?
Output: DDL/DML script for table/data

### Solution:
The first step is to create a Foreign Table where I can load the dataset. I used the file_fdw module that provides the foreign-data wrapper file_fdw, which can be used to access data files in the server's file system. First, install file_fdw as an extension:

```SQL
CREATE EXTENSION file_fdw;
```


Then I create a foreign server:

```SQL
CREATE SERVER pglog FOREIGN DATA WRAPPER file_fdw;
```
Now I'm ready to create the foreign data table. Using the `CREATE FOREIGN TABLE` command that I found here [Documentation PostgreSQL file_fdw ](https://www.postgresql.org/docs/9.5/file-fdw.html), I need to define the columns for the table, in this case I use the TSV file name, and the format:

```SQL
CREATE FOREIGN TABLE topups (
    seq                integer,
    id_user            integer NOT NULL,
    topup_date         date NOT NULL,
    topup_val          integer  NOT NULL
) SERVER topups_server
OPTIONS ( filename '/home/giulia/postgres_test/topups.tsv', format 'csv' , delimiter E'\t', header 'true');

```

Please note: I have to add the parameter called delimiter because the file provided is tsv file.


 *The goal of task 1 has been achieved. I have obtained through the above instructions a - DDL / DML - Data Definition Language and Data Manipulation Language script for table / data.*

---
## TASK 2: Simple Aggregations.
##### Print out the list of user IDs and the total of all top-ups done by them but ONLY for the users that had at least one topup ever done by the amount of €15 exactly. Can this be solved in a single SELECT statement, without Window Aggregates or subqueries (nested SELECTs)?
Output: The SQL query

### Solution:

Since for this task, I was asked to do not use window aggregates or subqueries, I used the following approach :

+ `GROUP BY` the data are grouped by `id_user`;
+ `HAVING` count that in each group there is at least  one `topup_val` exactly equal to 15;
+ Once excluded the groups without `topup_val` equal to 15, the sum of `topup_val` for each group is applied.

```SQL
SELECT
 id_user,
 SUM(topup_val)
FROM
 topups
GROUP BY
 id_user
HAVING
 COUNT(CASE WHEN topup_val=15 THEN 1 END) >= 1
;
```
*The goal of task 2 has been achieved. I have obtained through the above instructions a SQL query.*

---
## TASK 3:  Row Sequencing.
##### Show the 5 (but not more) rows containing most recent top-ups per user.In case of more top-ups done within a day, print those with higher amounts first.

Output: The SQL query


### Solution:
In the first `SELECT` I used the following approach:
+ I used a window function `ROW_NUMBER` to count the `id_user` thanks to `PARTITION BY`;
+ I ordered by at first `topup_date` second `topup_val` `DESC`;
+ I used second `select` to find the five most recent topup per user.

```SQL
SELECT
  id_user,
  topup_val,
  topup_date
FROM (
  SELECT
   id_user,
   topup_val,
   topup_date,
   ROW_NUMBER () OVER ( PARTITION BY id_user ORDER BY topup_date, topup_val DESC )
  FROM
   topups) AS foo
WHERE
  (row_number <= 5)
 ;

```
*The goal of task 3 has been achieved. I have obtained through the above instructions a SQL query.*

---

## TASK 4:  Row Sequencing.
##### Show the 5 largest top ups done per user. Aim to limit the result to just 5 rows per user but allow for more if the immediately following topups (6th, 7th etc...) still have the same value (as in 5th).

Output: The SQL query


### Solution:
As in the last task, I follow the same approach but I used a different window function :

+ The first `SELECT` counts the` topup_val`, in descending order, with the `RANK` function for each` id_user`;
+ Unlike `ROW_NUMBER` the` RANK` function, if the values ​​of the two lines are equal, it assigns the same rank. This is necessary for the specifications "includes the following topups (6th, 7th etc ...) that still have the same value (as in 5th)";
+ I used the second `SELECT` to find 5 largest topups made for each user.

```SQL
SELECT
  id_user,
  topup_val,
  topup_date
FROM (
SELECT
 id_user,
 topup_val,
 topup_date,
 RANK () OVER ( PARTITION BY id_user ORDER BY topup_val DESC )
FROM
 topups) AS foo
WHERE
  rank <= 5
 ;

```
*The goal of task 4 has been achieved. I have obtained through the above instructions a SQL query.*

---
## TASK 5: Inter-row calculations
##### Task 5: Using the window functions enrich the original set (create new, derived table) to include extra columns as per description below:
1. **prv_topup_dt** - previous topup date of the  same user;
2. **days_since** - number of days since previous topup by user;
3. **promo_ind** - Y/N flag. Put Y for top-ups of €20 or more, otherwise N;
4. **previous_qual_topup_dt** - the date of previous topup of €20 or more done by the same user;
5. **to_1st_ratio** - (bonus) Y/X fraction value where Y is the current topup value and X is theamount of the first ever topup done by the user.

Output: The SQL query


### Solution:
The first thing I did was to add extra columns as described by using the following approach:

1. To find `prv_topup_dt`, I followed the following steps:

    + I `SELECT` `id_user`,`topup_val` and `topup_date`
    + I used the window function `LAG` to access from the previous row in the `topup_date`.
    + The partition by `id_user` and sort by `topup_date` in ascending order each group.


2. To find `days_since`, I followed the following steps:

    + I used the same previous reasoning but with some variation.
    + At the current date I subtract the value that is returned to me by the `LAG` function on the `topup_date` partitioned by `id_user` and sorted by `topup_date`.
    + I convert them date.


3. To find `promo_ind`, I followed the following step:

    + I used a case with the condition when `topup_val` >= 20 insert 'Y' otherwise 'N'.


4. To find `previous_qual_topup_dt`, I followed the following steps:

    + I used the same previous reasoning in step 1(to find `prv_topup_dt`).
    + NOTE: I can not look at the line above with the `LAG`. This is why I use a filter that allows me to put a condition through the use of aggregate functions and NOT window functions.
    + Partition by user and sort by date.
    I use the `MAX` function on `topup_date` and filter where `topup_val` >= 20.
    + Change the range and do it (above - current value line).To do this I used `ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING`.
    NOTE: `MAX` combined with the fact that you place orders and evaluate the line above up to the top works exactly like the `LAG` because you order in an increasing order.


5. To find `to_1st_ratio`, I followed the following steps:

    + Group by `id_user`, I sort by ascending `topup_date` and I used the window function `FIRST_VALUE` to return the first value from the first row of the ordered set.
    + I divide `topup_val` and the result of the window function convert both to numeric and get the fraction.
    + I used `ROUND` to keep two decimal places and no more.
    + At the end the ordering is to make the windows function work correctly and at the end of all I do a total sort order.


The result of the select will be the one that will be inserted in the new derived table.




```SQL
CREATE TABLE topups_derivated AS
  SELECT
     id_user,
     topup_val,
     topup_date,
     LAG (topup_date) OVER ( PARTITION BY id_user ORDER BY topup_date) AS prv_topup_dt,
     MAX(topup_date) FILTER (WHERE topup_val>=20) OVER (
       PARTITION BY id_user
       ORDER BY topup_date
       ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
     ) AS previous_qual_topup_dt,
     CASE WHEN topup_val>=20 THEN 'Y' ELSE 'N' END AS promo_ind,
     topup_date::date - LAG (topup_date) OVER ( PARTITION BY id_user ORDER BY topup_date)::date AS days_since,
     ROUND(topup_val::numeric / (FIRST_VALUE (topup_val) OVER ( PARTITION BY id_user ORDER BY topup_date ))::numeric, 2) AS to_1st_ratio
    FROM
     topups
  ORDER BY
    id_user, topup_date DESC
   ;

```
*The goal of task 5 has been achieved. I have obtained through the above instructions a SQL query.*

---
## TASK 6:  Row Sequencing.
##### The mobile operator runs a promotion. If you top up by at least €20 you get a free credit for 28 calendar days immediately following the day of that top up. Print out the list of consolidated periods when users were eligible to make free calls. Include initial eligibility date and the date when the free credit effectively ends.

Output: The SQL Query. If you use any subselects please stick them with a comment explaining logic.


### Solution:
The approach used to perform this task is inspired by the following example: [PostgreSQL Range aggregation](https://wiki.postgresql.org/wiki/Range_aggregation). This example provided me the basis for then extending the reasoning to my exercise.
Understanding the example provided by the previous link, the steps taken are these:

+ First, I selected `id_user`, `topup_date`, `previous_qual_topup_dt` and with the case when `promo_ind` != 'Y' or `topup_date` - `INTERVAL '28 day'` is <= of `MAX` function of `previous_qual_topup_dt`then NULL. Partitioned for `id_user` and ordered for `topup_date`, `previous_qual_topup_dt` and sorted by ascending order. Otherwise it returns me `topup_date`.This section is called `start_promotion`.

+ I selected as in the previous select but with the addition of `start promotion` and the maximum of the `start_promotion` grouped by `id_user` and ordered by `topup_date` and `previous_qual_topup_dt`. This section is called `left_edge`.

+ I selected `id_user`, the `MIN` of `topup_date` as `start_promotion` and the `MAX` of `previous_qual_topup_dt` + 28 as `end_promotion`. Where `praevious_qual_topup_dt` is not NULL grouped by `id_user` and `left_edge` and ordered by `id_user` and `start_promotion`.



```SQL

SELECT
  id_user,
  MIN(topup_date) as start_promotion,
  MAX(previous_qual_topup_dt) + 28 as end_promotion
FROM
  (SELECT
    id_user,
    topup_date,
    previous_qual_topup_dt,
    start_promotion,
    MAX(start_promotion) OVER (PARTITION BY id_user ORDER BY topup_date,previous_qual_topup_dt) AS left_edge
  FROM
    (SELECT
      id_user,
      topup_date,
      previous_qual_topup_dt,
      CASE WHEN
          promo_ind != 'Y' OR
          topup_date - INTERVAL '28 day' <= MAX(previous_qual_topup_dt)
        OVER (
          PARTITION BY id_user
          ORDER BY topup_date, previous_qual_topup_dt)
        THEN NULL
        ELSE topup_date
      END AS start_promotion
    FROM
      topups_derivated) AS foo) as foo2
WHERE previous_qual_topup_dt IS NOT NUll
GROUP BY
  id_user,
  left_edge
ORDER BY
  id_user,
  start_promotion
;

```

*The goal of task 6 has been achieved. I have obtained through the above instructions a SQL query.*

---
## Conclusion
In my analysis, I used some window functions like `row_number`, `rank`, `first_value` and `lag`.
A window function performs a calculation across a set of table rows that are somehow related to the current row. This is comparable to the type of calculation that can be done with an aggregate function. But unlike regular aggregate functions, use of a window function does not cause rows to become grouped into a single output row: the rows retain their separate identities. In my elaborate I also used aggregation functions like `max()` and `min()`. In the case of aggregation functions, it is possible to insert a condition/constraint, which can not be done with the window functions.


