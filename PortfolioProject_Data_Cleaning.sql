
-- Cleaning data with SQL Queries


SELECT *
FROM NashvilleHousing


-----------------------------------------------------------------------------------------------------------------------------


-- Standardize Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing

--Did not work

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

--Second Method

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate

EXEC sp_rename 'NashvilleHousing.SaleDateConverted', 'SaleDate'

-----------------------------------------------------------------------------------------------------------------------------

--Populate Property Address data | if there is a same ParcelID with a Property Address replace NULL VALUES to same ParcelID of the ones that have an address

SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

--Find the null values and self join them with their corresponding address while produce a column that shows with what they will be replaced

SELECT NHA.ParcelID, NHA.PropertyAddress, NHB.ParcelID, NHB.PropertyAddress, ISNULL(NHA.PropertyAddress, NHB.PropertyAddress)
FROM NashvilleHousing NHA
JOIN NashvilleHousing NHB
	ON NHA.ParcelID = NHB.ParcelID
	AND NHA.[UniqueID ] <> NHB.[UniqueID ]
WHERE NHA.PropertyAddress IS NULL
ORDER BY NHA.ParcelID

--update table and change null values with correct address

UPDATE NHA
SET PropertyAddress = ISNULL(NHA.PropertyAddress, NHB.PropertyAddress)
FROM NashvilleHousing NHA
JOIN NashvilleHousing NHB
	ON NHA.ParcelID = NHB.ParcelID
	AND NHA.[UniqueID ] <> NHB.[UniqueID ]
WHERE NHA.PropertyAddress IS NULL


-----------------------------------------------------------------------------------------------------------------------------

--Breaking Address into individual columns (address, city, state) 2 ways
--1st way

SELECT PropertyAddress
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

--Use substring function to take a part of the string and charindex-1 to set the boundary of the string you want

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

--Add 2 columns drop 1 column

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


SELECT *
FROM NashvilleHousing

--2nd way

SELECT OwnerAddress
FROM NashvilleHousing

--using replace cause parsename function needs '.' in order to be used

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) ,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-----------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'N' THEN 'No'
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant
END
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SoldAsVacant1 nvarchar(255)

UPDATE NashvilleHousing
SET SoldAsVacant1 = CASE
	WHEN SoldAsVacant = 'N' THEN 'No'
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant
END


-----------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RownumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, 
									PropertyAddress, 
									SalePrice,
									SaleDate,
									LegalReference
						ORDER BY 
							UniqueID) AS row_num
FROM NashvilleHousing)

-- First use select statement to check the duplicates and then change the select statement to delete (normally done in view tables)

SELECT *
FROM RownumCTE
WHERE row_num >1


-----------------------------------------------------------------------------------------------------------------------------

-- Delete unused columns


ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SoldAsVacant