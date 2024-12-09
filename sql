-- Step 1: Create staging table (if not already done)
CREATE TABLE IF NOT EXISTS world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

-- Step 2: Insert data into staging table
INSERT INTO world_layoffs.layoffs_staging
SELECT * FROM world_layoffs.layoffs;

-- Step 3: Use CTE to identify duplicates and delete them
WITH DELETE_CTE AS (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, 
           date, stage, country, funds_raised_millions, 
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, 
                            percentage_laid_off, date, stage, country, funds_raised_millions
               ORDER BY date -- This ensures we keep the earliest row
           ) AS row_num
    FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, 
       date, stage, country, funds_raised_millions) IN (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, 
           date, stage, country, funds_raised_millions
    FROM DELETE_CTE
) AND row_num > 1; -- Delete only duplicates (row_num > 1)


-- Step 4: Standardize Data

-- Fix industry column (empty or null rows should be set to NULL)
UPDATE world_layoffs.layoffs_staging
SET industry = NULL
WHERE industry = '';

-- Populate missing industry data from matching company
UPDATE world_layoffs.layoffs_staging t1
JOIN world_layoffs.layoffs_staging t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Standardize variations in "Crypto" industry
UPDATE world_layoffs.layoffs_staging
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Standardize country values (strip trailing periods)
UPDATE world_layoffs.layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

-- Convert date column to correct format
UPDATE world_layoffs.layoffs_staging
SET date = STR_TO_DATE(date, '%m/%d/%Y');

-- Modify column type to DATE after conversion
ALTER TABLE world_layoffs.layoffs_staging
MODIFY COLUMN date DATE;


-- Step 5: Handle NULL Values

-- Check for and ignore null values in total_laid_off, percentage_laid_off, funds_raised_millions
SELECT * FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL;

-- Clean rows where both total_laid_off and percentage_laid_off are null (if necessary)
DELETE FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;


-- Step 6: Remove unnecessary columns and rows

-- Remove rows where all values are NULL (if needed)
DELETE FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Remove column used for row number (if it was added for deletion logic)
ALTER TABLE world_layoffs.layoffs_staging
DROP COLUMN row_num;

-- Final check on the staging table after cleaning
SELECT * FROM world_layoffs.layoffs_staging;
