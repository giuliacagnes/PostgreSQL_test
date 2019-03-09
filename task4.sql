-- Row Sequencing. Show the 5 largest top ups done per user. Aim to limit the result to just 5
-- rows per user but allow for more if the immediately following topups (6th, 7th etc…) still have the same
-- value (as in 5th).

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
