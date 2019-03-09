-- Using the window functions enrich the original set (create new, derived table) to include extra columns
-- as per description below:
--  prv_topup_dt - previous topup date of the same user
--  days_since - number of days since previous topup by user
--  promo_ind - Y/N flag. Put Y for top-ups of €20 or more, otherwise N.
--  previous_qual_topup_dt - the date of previous topup of €20 or more done by the same user
--  to_1st_ratio - (bonus) Y/X fraction value where Y is the current topup value and X is the
--    amount of the first ever topup done by the user.

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



