# Zomato_advance_analysis
# Food Delivery Marketplace Operations Analytics (PostgreSQL)

## 📌 Project Overview
This project features an end-to-end relational database analytics suite designed for a multi-tier food delivery platform. Operating on transactional data, the system models marketplace health, tracks logistics bottlenecks, segments customers based on financial baselines, and evaluates rider efficiency.

The core engine handles complex real-world data anomalies, such as midnight-crossing logistics intervals and conditional cancellation metrics.

## 🗂️ Database Architecture
The relational schema comprises 5 interconnected tables built to enforce data integrity via primary and foreign key constraints:

- **Customers**: Baseline demographic and registration tracking.
- **Restaurants**: Localized outlet data and operational hours.
- **Riders**: Logistics personnel onboarding metrics.
- **Orders**: Core transactional ledger capturing itemization and revenue.
- **Deliveries**: Fulfillment tracking linked directly to logistics metrics.

## 🚀 Key Business Metrics Engineered
The analytics engine addresses 20 deep business questions, categorized into key operational domains:

### 1. Logistics & Rider Efficiency Tracking
- **Midnight-Crossing Interval Optimization (Q.10, Q.17):** Engineered an automated fallback system using `+ INTERVAL '24 HOURS'` and `COALESCE` to resolve negative interval anomalies caused by overnight deliveries.
- **Performance Tiering (Q.14, Q.17):** Implemented bidirectional window function framing (`RANK() OVER`) to instantly isolate highest and lowest performing logistics outliers.

### 2. Growth & Financial Analytics
- **Time-Series Trend Analysis (Q.19):** Applied chronological `LAG()` window tracking to compute Month-over-Month (MoM) revenue and order volume growth ratios per restaurant.
- **Customer Segmentation (Q.12):** Created a dynamic customer matrix classifying users into 'Gold' and 'Silver' tiers by comparing individual averages against the platform's overarching Average Order Value (AOV).

### 3. Risk & Quality Control
- **Year-over-Year Cancellation Comparison (Q.9):** Deployed precise conditional aggregation via `COUNT(CASE WHEN...)` to track and compare restaurant cancellation rates across fiscal years while avoiding null-space skewing.

## 🛠️ Tech Stack & Skills Demonstrated
- **Dialect:** PostgreSQL
- **Advanced SQL Constructs:** Chained Common Table Expressions (CTEs), Window Functions (`RANK`, `LAG`), Conditional Aggregations, Interval Data Manipulation, Defensive Error Handling (`NULLIF`).
