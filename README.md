# SQL-Data-Cleaning

# Layoffs Data Cleanup Process

This repository contains the SQL code for cleaning and preparing layoffs data. The steps involve creating a staging table, removing duplicates, standardizing data, handling null values, and removing unnecessary rows and columns.

## Explanation of the Steps:

### 1. Creating the Staging Table:
- First, a staging table (`layoffs_staging`) is created to work on and clean the raw data.
- The `INSERT` statement copies the raw data from `world_layoffs.layoffs` into this staging table.

### 2. Duplicate Removal (CTE-based):
- A CTE (`DELETE_CTE`) is used to identify duplicate rows based on a set of columns.
- The `ROW_NUMBER()` function is used to assign a row number to each group of duplicates.
- The `DELETE` statement then removes the rows where the `row_num` is greater than 1 (duplicates).

### 3. Standardizing Data:
- The code updates empty industry values to `NULL` and fills missing industry values by matching company names.
- It also standardizes variations of the term "Crypto" and strips trailing periods from country names.
- The date format is converted to the `DATE` data type using `STR_TO_DATE`.

### 4. Handling NULL Values:
- NULL values in certain columns are inspected, and rows where critical fields (`total_laid_off` and `percentage_laid_off`) are both `NULL` are deleted.

### 5. Removing Unnecessary Columns and Rows:
- Any rows with NULL values in essential fields are removed.
- If a `row_num` column was used for duplicate identification, it's dropped from the table.
