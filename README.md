# transaction_intelligence_revenue_leakage_detection
End-to-end analytics project built to detect revenue leakage, monitor merchant health, and surface settlement risks on a B2B FinTech payment platform. This project analyses 30,000+ datasets, 813 transactions, 650 merchants, and ₹30.89M in GMV using MS Excel, MySQL, and Power BI.

## Project Background

Zorvyn is a B2B FinTech platform operating in the Indian digital payments space, facilitating payment processing and settlements for merchants across Logistics, Retail, EdTech, FMCG, Insurance, Travel, SaaS, HealthTech, Media & Entertainment, and E-Commerce. The platform earns revenue through a fee-on-GMV model and manages merchant onboarding, payment routing, and settlement payouts.

As a data analyst working within Zorvyn's operations team, the objective was to identify where revenue was leaking, which payment methods were underperforming, which merchants were churning silently, and why ₹46.37M in settlements remained pending against only ₹6.20M in platform fee collected.

Insights and recommendations are provided on the following key areas:

- **Transaction Health & Payment Method Performance:** Analysing success rates, failure reasons, and recoverability across all payment channels.
- **Revenue Leakage & Settlement Analysis:** Quantifying lost revenue from failed transactions, delayed settlements, and unresolved chargebacks.
- **Merchant Health & Churn Classification:** Segmenting merchants by activity recency to identify At Risk and Churned cohorts before they disengage permanently.
- **Business Category & GMV Benchmarking:** Comparing average ticket size, total GMV, and transaction volume across all business categories to identify high-value growth segments.

The SQL queries used to inspect, clean, and analyse the data for this project can be found here: [SQL Queries](https://github.com/vivek1dv/transaction_intelligence_revenue_leakage_detection/blob/main/transaction_intelligence_%26_revenue_leakage_sql.sql)

An interactive Power BI dashboard used to report and explore platform trends can be found here: [Power BI Dashboard](https://github.com/vivek1dv/transaction_intelligence_revenue_leakage_detection/blob/main/transaction_intelligence_%26_revenue_leakage_bi.pbix)


## Data Structure & Initial Checks

The Zorvyn analytics database consists of five tables with 30,000+ datasets, 813 transaction records and 650 merchant records. A description of each table is as follows:

- **fact_transactions:** Core transaction log containing transaction ID, merchant ID, payment method ID, failure reason ID, timestamp, amount, status (SUCCESS / FAILED / PENDING / FLAGGED / REVERSED), and transaction type.
- **fact_chargebacks:** Chargeback records linked to merchants, including dispute amount, chargeback ID, and resolution status.
- **dim_merchants:** Merchant master data including merchant name, business category, merchant tier (Platinum / Gold / Silver / Bronze), onboard date, and active status.
- **dim_payment_method:** Payment method reference table with method name and category (Card-Based, Real-time, Banking, Credit, Prepaid).
- **dim_failure_reason:** Failure reason reference table with reason label, reason category, and a recoverability flag indicating whether the failed transaction can be retried.

![alt text](https://github.com/vivek1dv/transaction_intelligence_revenue_leakage_detection/blob/main/schema%20bi.png)


## Executive Summary

### Overview of Findings

Zorvyn is facing a compounding revenue problem: ₹1.57M is leaking through delayed settlements and unresolved chargebacks, no payment method on the platform meets the minimum 95% success threshold, and 100% of tracked merchants are classified as Churned with over 1,000 days of inactivity. The platform's strongest GMV segment, Logistics, averages ₹60,633 per transaction but receives no targeted growth or retention effort, while ₹8.71L+ in failed GMV sits recoverable through a simple retry mechanism that does not yet exist.

![alt text](https://github.com/vivek1dv/transaction_intelligence_revenue_leakage_detection/blob/main/Executive%20Summary.png)


## Insights Deep Dive

### Transaction Health & Payment Method Performance

- **No payment method is operationally healthy.** The platform-wide success threshold is 95%. The best-performing method, Wallet, sits at 92.11% and is classified as Needs Attention. Every other method, including UPI (84.58%), Credit Card (85.89%), NACH (82.50%), Net Banking (82.93%), Debit Card (89.29%), and BNPL (78.67%), falls in the Critical band.

- **BNPL is the most commercially damaging failure point.** It has the lowest success rate at 78.67% while also carrying one of the highest average ticket sizes at ₹49,441. A method that fails 1 in 5 times on high-value orders creates disproportionate GMV loss compared to high-volume, low-value failures.

- **₹8.71L+ in failed GMV is recoverable today.** User Abandoned (8 failures, ₹5.07L) and Invalid OTP (8 failures, ₹3.63L) are both flagged as recoverable in the failure reason dimension. These failures do not require any payment infrastructure fix — a retry prompt or OTP resend flow within the session is sufficient to win them back.

- **Fraud Block and Bank Declined failures are non-recoverable and need fraud model review.** Fraud Block accounts for 8 failures and ₹1.13L in lost GMV. Since these cannot be retried, they require upstream fraud model tuning rather than session-level recovery.

![alt text](https://github.com/vivek1dv/transaction_intelligence_revenue_leakage_detection/blob/main/Transaction%20Health.png)


### Revenue Leakage & Settlement Analysis

- **₹46.37M in settlements is pending against ₹6.20M in platform fee collected.** This 7.5x mismatch between obligations and earnings is a direct treasury risk. The settlement lag analysis surfaces which merchants are experiencing the longest delays and at what tier.

- **Total revenue leakage stands at ₹1.57M.** This figure aggregates losses from delayed settlements, failed transactions with recoverable GMV sitting unclaimed, and unresolved chargeback disputes. Without a unified leakage metric, this number was invisible to the finance team.

- **Average settlement lag is 1.79 days platform-wide, but select merchants face 3 to 5 day delays.** The delayed settlements table in the dashboard identifies AgroLink Farms and ByteCart Technologies as the most affected, giving the finance team a merchant-specific escalation list rather than a platform average to act on.

- **299 chargebacks have been raised with no tier-based correlation.** ByteCart Technologies826 (Gold tier) carries the highest disputed amount at ₹2,23,375 across just 3 chargebacks, showing that chargeback severity cannot be managed by tier alone.

![alt text](https://github.com/vivek1dv/transaction_intelligence_revenue_leakage_detection/blob/main/Revenue%20%26%20Settlement.png)


### Merchant Health & Churn Classification

- **Every merchant in the tracked dataset is classified as Churned.** Using last transaction date and DATEDIFF logic, merchants were classified as Active (last transaction within 30 days), At Risk (within 60 days), or Churned (beyond 60 days). All merchants fall in the Churned category with inactivity ranging from 1,000 to 1,200 days.

- **The earliest churned merchants last transacted in January 2023.** StreamZone OTT659 and JetTravel Pvt Ltd466 show 1,189 days of inactivity. With no early-warning system in place, the window for re-engagement on these merchants closed over three years ago.

- **Merchant churn is spread across all tiers including Platinum.** CloudSuite SaaS2282 and QuickMart Retail909 show 726 and 1,009 days inactive respectively, meaning even high-value merchants churned without a retention response.

- **The churn classification query is production-ready for weekly scheduling.** The SQL logic using MAX(txn_timestamp) and DATEDIFF requires no modification to run as a weekly monitoring job, giving the merchant success team a live churn risk view rather than a static historical snapshot.

![alt text](https://github.com/vivek1dv/transaction_intelligence_revenue_leakage_detection/blob/main/Merchant%20Health.png)



## Recommendations

Based on the insights and findings above, the Operations, Finance, and Merchant Success teams should consider the following:

- BNPL fails nearly 1 in 5 transactions at the highest average ticket size on the platform. **Conduct a failure audit specific to BNPL to determine if failures are concentrated in certain merchants, time windows, or transaction value bands, and implement method-level retry logic as an immediate stopgap.**

- ₹8.71L+ in GMV from User Abandoned and Invalid OTP failures is sitting unclaimed and recoverable. **Build a session-level retry prompt and OTP resend flow to recover this revenue without any payment infrastructure changes.**

- ₹46.37M in pending settlements creates a 7.5x mismatch against platform earnings and a direct cash flow risk. **Enforce settlement SLAs with escalation triggers for merchants exceeding 3-day lag, starting with the merchants already identified in the delayed settlements table.**

- All tracked merchants are Churned with no active re-engagement mechanism in place. **Schedule the churn classification query as a weekly job and assign the At Risk cohort to the merchant success team for proactive outreach before full disengagement.**

- Logistics generates 3.3x higher average transaction value than E-Commerce but receives no differentiated growth investment. **Prioritize merchant acquisition in Logistics and Media & Entertainment where fewer transactions yield significantly higher GMV, improving platform unit economics without proportional volume growth.**


## Assumptions and Caveats

- All transaction analysis is filtered to txn_status = 'SUCCESS' and txn_type = 'PAYMENT' unless the query specifically targets failed or other transaction states. Refunds, reversals, and pending transactions are excluded from GMV calculations.

- The churn classification uses DATEDIFF(CURDATE(), MAX(txn_timestamp)) to calculate inactivity. Because the dataset appears to be a historical extract ending in mid-2023, all merchants show inactivity well beyond 60 days. Results should be interpreted relative to the dataset period rather than today's date.

- Revenue leakage of ₹1.57M is a combined figure aggregating delayed settlements, unresolved chargebacks, and failed GMV. Individual leakage components are not separately reconciled in the SQL layer.

- The recoverability flag in dim_failure_reason assumes that User Abandoned and Invalid OTP failures can be retried within the same session, which depends on payment gateway support for mid-session retries.
