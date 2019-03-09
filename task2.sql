-- Simple Aggregations. Print out the list of user IDs and the total of all top-ups done by them
-- but ONLY for the users that had at least one topup ever done by the amount of €15 exactly. Can this
-- be solved in a single SELECT statement, without Window Aggregates or subqueries (nested
-- SELECTs)?

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


