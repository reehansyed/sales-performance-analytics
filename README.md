# sales-performance-analytics
Optimizing Sales &amp; Customer Retention using SQL, Power BI &amp; Excel
## 📌 Project Overview
"Sales Performance & Customer Retention Analytics" is a domain-specific data analysis project aimed at improving sales strategy and customer engagement using SQL, Power BI, and Excel. This project simulates a real-world B2B CRM system and helps uncover critical insights around deal performance, sales agent efficiency, customer churn risk, and revenue patterns.

Through analytical SQL queries and interactive dashboards, this project addresses business problems such as pipeline delays, conversion bottlenecks, retention risks, and revenue forecasting — making it highly applicable in Sales Analytics, CRM, and Revenue Operations roles.

## 🎯 Project Objectives

The primary goal of this project is to analyze sales pipeline data to improve business outcomes across revenue, performance, and retention. The following key objectives were defined:

- **🔍 Analyze Sales Performance**  
  Identify top-performing sales agents, average deal size, and high-value deals to reward and replicate successful behavior.

- **📈 Measure Deal Efficiency**  
  Calculate the average time taken to close deals across industries and deal stages to highlight bottlenecks and accelerate sales velocity.

- **❌ Understand Deal Loss & Churn Risk**  
  Detect at-risk accounts based on high lost-deal percentages and inactivity to support targeted retention strategies.

- **📊 Track Revenue Trends**  
  Monitor monthly and seasonal revenue fluctuations to inform forecasting and resource planning.

- **🧮 Calculate Conversion Rates**  
  Evaluate the efficiency of the sales funnel from prospecting to closure to optimize sales strategy.

- **📌 Deliver Business Insights**  
  Create interactive dashboards using Power BI to enable stakeholders to track KPIs and make data-driven decisions.

  ## 📂 Datasets Used

The project utilizes four key datasets that collectively simulate a real-world CRM and sales environment. These datasets are organized under the `Datasets/` folder and serve as the foundation for SQL analysis and dashboard reporting.

### 1. `Sales_Team.csv`
- Contains details about the company’s sales representatives.
- **Key Columns:**
  - `sales_agent`, `region`, `experience_level`, `team_lead`

### 2. `Sales_Pipeline.csv`
- Main dataset containing detailed information on deals in the pipeline.
- **Key Columns:**
  - `deal_id`, `account`, `sales_agent`, `deal_stage`, `engage_date`, `close_date`, `close_value`

### 3. `Accounts.csv`
- Metadata about business accounts or clients.
- **Key Columns:**
  - `account`, `sector`, `region`, `client_size`

### 4. `Products.csv`
- Information about products involved in deals.
- **Key Columns:**
  - `product_id`, `product_name`, `product_line`, `unit_price`, `category`

Each dataset was integrated and analyzed using SQL and visualized using Power BI to deliver actionable insights for sales strategy and customer retention.

- ## Business Problems and Solutions
### 1.classifies deals into high, mid, and low-value segments and identifies which sales agents close the most high-value deals.
~~~ sql
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
~~~

### 2. identify which accounts are moving faster or slower through different deal stages and can highlight bottlenecks.
~~~ sql
SELECT 
  account,
  sales_agent,
  DATEDIFF(day, engage_date, close_date) AS days_to_close
FROM sales_pipeline
WHERE engage_date IS NOT NULL 
  AND close_date IS NOT NULL
  AND deal_stage = 'Won'
ORDER BY days_to_close DESC;
~~~

### 3. Calculate the average number of days taken to close a deal for each industry.
~~~ sql
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
~~~
### 4.This query identifies accounts with a high risk of churn by calculating the lost deal percentage and the time gap since their last won deal.
~~~ sql
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
~~~
### 5. This query identifies seasonal trends in sales performance by analyzing revenue fluctuations across months and years.
~~~ sql
SELECT 
  YEAR(close_date) AS year,
  MONTH(close_date) AS month,
  SUM(close_value) AS monthly_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won' AND close_value IS NOT NULL
GROUP BY YEAR(close_date), MONTH(close_date)
ORDER BY year, month;
~~~
### 6. Calculate win rate per sales agent (Won deals vs Total deals)
~~~ sql
SELECT 
  sales_agent,
  COUNT(*) AS total_deals,
  SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals,
  ROUND(100.0 * SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) / COUNT(*), 2) AS win_rate_pct
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY win_rate_pct DESC;
~~~
### 7. Find average deal size by industry (from accounts table)
~~~ sql
SELECT 
  a.sector AS industry,
  AVG(sp.close_value) AS avg_deal_value
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.deal_stage = 'Won' AND sp.close_value IS NOT NULL
GROUP BY a.sector
ORDER BY avg_deal_value DESC;
~~~
### 8. Conversion rate from Prospecting to Won
~~~ sql
WITH stage_counts AS (
  SELECT 
    deal_stage, COUNT(*) AS stage_count
  FROM sales_pipeline
  GROUP BY deal_stage
)
SELECT 
  (SELECT stage_count FROM stage_counts WHERE deal_stage = 'Won') * 1.0 /
  (SELECT stage_count FROM stage_counts WHERE deal_stage = 'Prospecting') AS conversion_rate;
  ~~~
### 9. Monthly churn rate: % of accounts with more lost than won deals
~~~ sql
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
~~~
### 10. Average time to close per deal stage
~~~ sql
SELECT 
  deal_stage,
  AVG(DATEDIFF(DAY, engage_date, close_date)) AS avg_days_to_close
FROM sales_pipeline
WHERE engage_date IS NOT NULL AND close_date IS NOT NULL
GROUP BY deal_stage
ORDER BY avg_days_to_close;
~~~
### 11. Top 5 clients by total deal value (won deals only)
~~~ sql
SELECT TOP 5 
  account,
  SUM(close_value) AS total_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY account
ORDER BY total_value DESC;
~~~
## 🧭 Steps Taken

The project was executed in a structured and iterative workflow to ensure clean data, meaningful insights, and business-ready visualizations. The steps are as follows:

### 1. Data Understanding
- Reviewed all datasets: `Sales_Team`, `Sales_Pipeline`, `Accounts`, and `Products`
- Identified relationships between deals, agents, clients, and product segments
- Noted missing values, inconsistent formats, and important columns

### 2. Data Cleaning & Preparation (Excel & SQL)
- Removed null or irrelevant records (e.g., deals with missing dates or values)
- Handled data types: ensured date formats and numeric fields were accurate
- Joined tables where necessary using keys like `account` and `sales_agent`

### 3. Business Question Framing
- Mapped stakeholder questions to measurable metrics (e.g., win rate, churn rate, time to close)
- Translated these into 11 SQL queries using window functions, aggregations, joins, and date functions

### 4. SQL Analysis
- Wrote and executed SQL queries to:
  - Segment deals
  - Rank agents
  - Analyze churn
  - Track revenue trends
  - Measure sales funnel efficiency

### 5. Visualization (Power BI)
- Imported cleaned data into Power BI
- Built interactive dashboards with:
  - KPIs (Total Revenue, Won Deals, Avg Deal Size)
  - Agent performance charts
  - Monthly revenue trends
  - Funnel drop-off & conversion analysis
  - Churn and win-loss visuals

### 6. Insights & Interpretation
- Interpreted query outputs and dashboard visuals
- Documented insights into performance drivers and improvement areas
- Highlighted high-risk accounts and seasonal growth opportunities

### 7. Final Presentation
- Created a structured presentation showcasing methodology, queries, and dashboard walkthrough
- Used business storytelling to explain findings to non-technical stakeholders

## 🛠 Technologies Used

The project leverages industry-standard tools for data analysis, business intelligence, and reporting:

| Technology       | Purpose                                                                 |
|------------------|-------------------------------------------------------------------------|
| **SQL Server**   | Writing analytical queries using joins, window functions, and aggregations |
| **Power BI**     | Building interactive dashboards, KPIs, and drill-through visualizations  |
| **Microsoft Excel** | Initial data exploration, cleaning, and basic summaries               |
| **GitHub**       | Hosting SQL scripts, documentation, and project files                   |

These tools were used in combination to simulate a complete sales analytics project workflow, from raw data to executive insights.

## 🔍 Key Insights

The following insights were derived from the SQL analysis and Power BI dashboard:

- 🔝 **Top-performing sales agents** were responsible for the majority of high-value deals, suggesting performance-based incentives can be optimized.

- 🐌 **Accounts in specific sectors** (e.g., manufacturing) showed longer deal closure times, indicating potential process bottlenecks or longer decision cycles.

- 📉 **Churn-prone accounts** were identified based on a high lost-deal percentage and long gaps since the last successful deal — an early signal for customer success teams.

- 📆 **Revenue seasonality** was observed, with certain months consistently driving higher deal closures — helpful for campaign and resource planning.

- 🎯 **Overall conversion rate** from Prospecting to Won deals highlighted drop-off stages that require better nurturing or qualification criteria.

- 📈 **Average deal size** varied significantly across industries, helping to prioritize sectors for future targeting.

- 🥇 **Top 5 clients** contributed disproportionately to total revenue, suggesting opportunities for account expansion or retention efforts.

These insights can directly support strategic decision-making across sales planning, team performance management, churn reduction, and revenue forecasting.

## 📁 Project Structure

```bash
sales-performance-analytics/
│
├── Datasets/                  
│   ├── Sales_Pipeline.csv
│   ├── Sales_Team.csv
│   ├── Accounts.csv
│   └── Products.csv
│
├── SQL/
│   └── Sales_Analytics.sql
│
├── PowerBI/
│   └── sales_dashboard.pbix
│
├── presentation/
│   └── Analytics_Project.pptx
│
└── README.md
## 📬 Contact
Syed Reehan
📧 reehansyed2110@gmail.com
🔗 www.linkedin.com/in/reehansyed | GitHub.com/reehansyed


