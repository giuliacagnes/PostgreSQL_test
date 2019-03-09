-- Row Sequencing. Show the 5 (but not more) rows containing most recent top-ups per user.
-- In case of more top-ups done within a day, print those with higher amounts first.
-- Output: The SQL query

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
