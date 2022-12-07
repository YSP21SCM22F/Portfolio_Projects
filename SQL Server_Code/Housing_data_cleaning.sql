/*
Cleaning Data in SQL Queries
*/

SELECT *
FROM Portfolio_Project..NashvilleHousing


--Standardize Date Format

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM Portfolio_Project..NashvilleHousing

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)


--Populate Property Address data

SELECT *
FROM Portfolio_Project..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.[UniqueID ], a.ParcelID, a.PropertyAddress, b.[UniqueID ], b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_Project..NashvilleHousing AS a
JOIN Portfolio_Project..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_Project..NashvilleHousing AS a
JOIN Portfolio_Project..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM Portfolio_Project..NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM Portfolio_Project..NashvilleHousing

ALTER TABLE Portfolio_Project..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

UPDATE Portfolio_Project..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE Portfolio_Project..NashvilleHousing
Add PropertySplitCity Nvarchar(255);

UPDATE Portfolio_Project..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

----------------------------------------
SELECT OwnerAddress
FROM Portfolio_Project..NashvilleHousing

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Portfolio_Project..NashvilleHousing

ALTER TABLE Portfolio_Project..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255),
	OwnerSplitCity Nvarchar(255),
	OwnerSplitState Nvarchar(255);

UPDATE Portfolio_Project..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant)
FROM Portfolio_Project..NashvilleHousing

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM Portfolio_Project..NashvilleHousing

UPDATE Portfolio_Project..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID,
									PropertyAddress,
									SalePrice,
									SaleDate,
									LegalReference
									ORDER BY UniqueID) AS row_num
FROM Portfolio_Project..NashvilleHousing
--ORDER BY ParcelID
)
SELECT row_num
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress


-- Delete Unused Colums
SELECT *
FROM Portfolio_Project..NashvilleHousing

ALTER TABLE Portfolio_Project..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


/*
Analyzing Data in SQL Queries
*/

SELECT *
FROM Portfolio_Project..NashvilleHousing

SELECT DISTINCT LandUse, COUNT(LandUse) AS NumOfLandUse
FROM Portfolio_Project..NashvilleHousing
GROUP BY LandUse
ORDER BY NumOfLandUse DESC

SELECT DISTINCT LandUse 
FROM Portfolio_Project..NashvilleHousing
WHERE LandUse LIKE '%VACANT RES%'

-- fix misspellings and abbreviations in 'LandUse' field
UPDATE Portfolio_Project..NashvilleHousing
SET LandUse = CASE WHEN LandUse = 'VACANT RES LAND' THEN 'VACANT RESIDENTIAL LAND'
						WHEN LandUse = 'VACANT RESIENTIAL LAND' THEN 'VACANT RESIDENTIAL LAND'
						ELSE LandUse
						END

SELECT LandUse, PropertySplitCity, YearBuilt, SalePrice, TotalValue, (SalePrice - TotalValue) AS Profit
FROM Portfolio_Project..NashvilleHousing

--Average profit of vacant Land sale
SELECT PropertySplitCity, LandUse, ROUND(AVG(Acreage), 2) AS Avg_Acr, ROUND(AVG(TotalValue), 2) AS Avg_TotalValue
, ROUND(AVG(SalePrice), 2) AS Avg_SalePrice, ROUND(AVG(SalePrice - TotalValue), 2) AS Avg_Profit
FROM Portfolio_Project..NashvilleHousing
WHERE LandUse LIKE '%VACANT%' AND Acreage IS NOT NULL AND LandValue IS NOT NULL
GROUP BY LandUse, PropertySplitCity
ORDER BY 1, 2, 3, 4

--Average profit of single family sale
SELECT PropertySplitCity, LandUse, ROUND(AVG(Acreage), 2) AS Avg_Acr, ROUND(AVG(TotalValue), 2) AS Avg_TotalValue
, ROUND(AVG(SalePrice), 2) AS Avg_SalePrice, ROUND(AVG(SalePrice - TotalValue), 2) AS Avg_Profit
FROM Portfolio_Project..NashvilleHousing
WHERE LandUse = 'Single Family' AND Acreage IS NOT NULL AND LandValue IS NOT NULL
GROUP BY LandUse, PropertySplitCity
ORDER BY 1, 2, 3, 4


