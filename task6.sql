-- The mobile operator runs a promotion. If you top up by at least €20 you get a free credit for 28
-- calendar days immediately following the day of that top up. Print out the list of consolidated periods
-- when users were eligible to make free calls. Include initial eligibility date and the date when the free
-- credit effectively ends.
-- Consider that with regular top-ups the free credit period may be effectively prolonged multiple times.
-- For instance for id_user=4 the first promotion period started on 2016-12-20 and with the four qualifying
-- topups being done on time it was effectively extended up until 2017-04-12:

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



