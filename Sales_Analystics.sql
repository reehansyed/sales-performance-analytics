create database LEARNBAYPROJECT;
use LEARNBAYPROJECT;
----------------------------------------------
-----1.classifies deals into high, mid, and low-value segments and identifies which sales agents close the most high-value deals.

-- Classify deals by percentile and count high-value deals per agent
WITH deal_segments AS (
  SELECT *,
         NTILE(3) OVER (ORDER BY close_value DESC) AS value_segment
  FROM sales_pipeline
  WHERE close_value IS NOT NULL AND deal_stage = 'Won'
),
classified_deals AS (
  SELECT *,
         CASE 
           WHEN value_segment = 1 THEN 'High'
           WHEN value_segment = 2 THEN 'Mid'
           ELSE 'Low'
         END AS deal_category
  FROM deal_segments
)
SELECT sales_agent, COUNT(*) AS high_value_deals
FROM classified_deals
WHERE deal_category = 'High'
GROUP BY sales_agent
ORDER BY high_value_deals DESC;


-----2. identify which accounts are moving faster or slower through different deal stages and can highlight bottlenecks.

SELECT 
  account,
  sales_agent,
  DATEDIFF(day, engage_date, close_date) AS days_to_close
FROM sales_pipeline
WHERE engage_date IS NOT NULL 
  AND close_date IS NOT NULL
  AND deal_stage = 'Won'
ORDER BY days_to_close DESC;


-------3. Calculate the average number of days taken to close a deal for each industry.

SELECT 
  a.sector AS industry,
  AVG(DATEDIFF(day, sp.engage_date, sp.close_date)) AS avg_closing_days
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.engage_date IS NOT NULL
  AND sp.close_date IS NOT NULL
  AND sp.deal_stage = 'Won'
GROUP BY a.sector
ORDER BY avg_closing_days DESC;


-------4. This query identifies accounts with a high risk of churn by calculating the lost deal percentage and the time gap since their last won deal.

WITH deal_summary AS (
  SELECT 
    account,
    COUNT(*) AS total_deals,
    SUM(CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0 END) AS lost_deals,
    MAX(CASE WHEN deal_stage = 'Won' THEN close_date END) AS last_won_date
  FROM sales_pipeline
  GROUP BY account
)
SELECT 
  account,
  ROUND(100.0 * lost_deals / total_deals, 2) AS lost_percentage,
  DATEDIFF(DAY, last_won_date, GETDATE()) AS days_since_last_win
FROM deal_summary
WHERE total_deals >= 3
ORDER BY lost_percentage DESC, days_since_last_win DESC;


--------5. This query identifies seasonal trends in sales performance by analyzing revenue fluctuations across months and years.

SELECT 
  YEAR(close_date) AS year,
  MONTH(close_date) AS month,
  SUM(close_value) AS monthly_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won' AND close_value IS NOT NULL
GROUP BY YEAR(close_date), MONTH(close_date)
ORDER BY year, month;


-- 6. Calculate win rate per sales agent (Won deals vs Total deals)
SELECT 
  sales_agent,
  COUNT(*) AS total_deals,
  SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals,
  ROUND(100.0 * SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) / COUNT(*), 2) AS win_rate_pct
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY win_rate_pct DESC;


-- 7. Find average deal size by industry (from accounts table)
SELECT 
  a.sector AS industry,
  AVG(sp.close_value) AS avg_deal_value
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.deal_stage = 'Won' AND sp.close_value IS NOT NULL
GROUP BY a.sector
ORDER BY avg_deal_value DESC;



-- 8. Conversion rate from Prospecting to Won
WITH stage_counts AS (
  SELECT 
    deal_stage, COUNT(*) AS stage_count
  FROM sales_pipeline
  GROUP BY deal_stage
)
SELECT 
  (SELECT stage_count FROM stage_counts WHERE deal_stage = 'Won') * 1.0 /
  (SELECT stage_count FROM stage_counts WHERE deal_stage = 'Prospecting') AS conversion_rate;


-- 9. Monthly churn rate: % of accounts with more lost than won deals
WITH monthly_deals AS (
  SELECT 
    account,
    YEAR(close_date) AS year,
    MONTH(close_date) AS month,
    SUM(CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0 END) AS lost,
    SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won
  FROM sales_pipeline
  GROUP BY account, YEAR(close_date), MONTH(close_date)
)
SELECT 
  year, month,
  COUNT(*) AS total_accounts,
  SUM(CASE WHEN lost > won THEN 1 ELSE 0 END) AS churned_accounts,
  ROUND(100.0 * SUM(CASE WHEN lost > won THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM monthly_deals
GROUP BY year, month
ORDER BY year, month;


-- 10. Average time to close per deal stage
SELECT 
  deal_stage,
  AVG(DATEDIFF(DAY, engage_date, close_date)) AS avg_days_to_close
FROM sales_pipeline
WHERE engage_date IS NOT NULL AND close_date IS NOT NULL
GROUP BY deal_stage
ORDER BY avg_days_to_close;


-- 11. Top 5 clients by total deal value (won deals only)
SELECT TOP 5 
  account,
  SUM(close_value) AS total_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY account
ORDER BY total_value DESC;






