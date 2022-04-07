-- Nashville Housing Data Cleanup

Select *
From PortfolioProject..NashvilleHousing

--Start with the date

Select new_saledate
From PortfolioProject..NashvilleHousing 

ALTER TABLE NashvilleHousing
ADD new_saledate Date;

Update NashvilleHousing
SET new_saledate = CONVERT(Date, SaleDate)

-- Check to see Nulls in each row

--Unique ID
Select UniqueID
From PortfolioProject..NashvilleHousing
Where UniqueID is NULL

Select ParcelID
From PortfolioProject..NashvilleHousing
Where ParcelID is NULL

Select LandUse
From PortfolioProject..NashvilleHousing
Where LandUse is NULL

Select PropertyAddress
From PortfolioProject..NashvilleHousing
Where PropertyAddress is NULL

-- There are 29 Nulls for Property Address
-- Need to fill in. Notice that there are duplicates that have the same parcelID but different UniqueID's
-- Fill in Nulls

Select old.ParcelID, old.PropertyAddress, new.ParcelID, new.PropertyAddress, ISNULL(old.PropertyAddress,new.PropertyAddress)
From PortfolioProject..NashvilleHousing old
JOIN PortfolioProject..NashvilleHousing new
	on old.ParcelID = new.ParcelID
	and old.[UniqueID ] <> new.[UniqueID ]
WHERE old.PropertyAddress is NULL

--Need to update these new entries into old table

Update old
SET PropertyAddress = ISNULL(old.PropertyAddress,new.PropertyAddress)
From PortfolioProject..NashvilleHousing old
JOIN PortfolioProject..NashvilleHousing new
	on old.ParcelID = new.ParcelID
	and old.[UniqueID ] <> new.[UniqueID ]

Select PropertyAddress
From PortfolioProject..NashvilleHousing
Where PropertyAddress is NULL

------------------------------------------
Select *
From PortfolioProject..NashvilleHousing
Where PropertyAddress <> OwnerAddress

--These don't match because of the City at the end. Let's separate them.

Select PropertyAddress
From PortfolioProject..NashvilleHousing

--Make a Column for the Address and for the City. Delimiter is ','

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress)) as City
From PortfolioProject..NashvilleHousing


--Add this to the table

--For the new PropertyAddress
ALTER TABLE NashvilleHousing
ADD PropertyAddress_new nvarchar(255);

Update NashvilleHousing
SET PropertyAddress_new = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1)

--For the new PropertyCity

ALTER TABLE NashvilleHousing
ADD PropertyCity nvarchar(255);

Update NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress))

--Do the same for the OwnerAddress, again the delimiter is ','.

Select
SUBSTRING(OwnerAddress, 1, CHARINDEX(',' , OwnerAddress) -1) as Address,
	SUBSTRING(OwnerAddress, CHARINDEX(',' , OwnerAddress) + 1, LEN(OwnerAddress)) as City
From PortfolioProject..NashvilleHousing


--Add to the table

--For the OwnerAddress_new

ALTER TABLE NashvilleHousing
ADD OwnerAddress_new nvarchar(255);

Update NashvilleHousing
SET OwnerAddress_new = SUBSTRING(OwnerAddress, 1, CHARINDEX(',' , OwnerAddress) -1)

--For the OwnerCity
ALTER TABLE NashvilleHousing
ADD OwnerCity_new nvarchar(255);

Update NashvilleHousing
SET OwnerCity_new = SUBSTRING(OwnerAddress, CHARINDEX(',' , OwnerAddress) + 1, LEN(OwnerAddress))

--Split City and State

ALTER TABLE NashvilleHousing
ADD OwnerState_new nvarchar(255);

Update NashvilleHousing
SET OwnerState_new = SUBSTRING(OwnerCity_new, CHARINDEX(',' , OwnerCity_new) + 1, LEN(OwnerCity_new))

--See if it looks alright, it doesn't, is there an easier way to do this...






--PARSENAME, only works with periods. Therefore replace the ',' with a period.
Select
Parsename(Replace(OwnerAddress,',','.'),3),
	Parsename(Replace(OwnerAddress,',','.'),2),
	Parsename(Replace(OwnerAddress,',','.'),1)
From PortfolioProject..NashvilleHousing

--Make new columns and fill


ALTER TABLE NashvilleHousing
ADD OwnerAddress_v2 nvarchar(255);

Update NashvilleHousing
SET OwnerAddress_v2 = Parsename(Replace(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerCity_v2 nvarchar(255);

Update NashvilleHousing
SET OwnerCity_v2 = Parsename(Replace(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerState_v2 nvarchar(255);

Update NashvilleHousing
SET OwnerState_v2 = Parsename(Replace(OwnerAddress,',','.'),1)








Select *
From PortfolioProject..NashvilleHousing

--Set 'Y' and 'N' as Yes and No in SoldASVacant


Select Distinct (SoldASVacant), COUNT(SoldAsVacant)
From PortfolioProject..NashvilleHousing
group by SoldAsVacant

Select SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
From PortfolioProject..NashvilleHousing

Update NashvilleHousing
Set SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

--Remove duplicates 

Select *,
	ROW_NUMBER()
	OVER (
	Partition by ParcelID,
	PropertyAddress,
	SaleDate,
	SalePrice,
	LegalReference
	Order by
	UniqueID) row_num
From PortfolioProject..NashvilleHousing 



WITH dupliCTE as(
Select *,
	ROW_NUMBER()
	OVER (
	Partition by ParcelID,
	PropertyAddress,
	SaleDate,
	SalePrice,
	LegalReference
	Order by
	UniqueID) dupli
From PortfolioProject..NashvilleHousing 
)
DELETE
From dupliCTE
Where dupli > 1
--order by ParcelID



--Remove unwanted columns

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress,
			SaleDate,
			OwnerAddress,
			OwnerAddress_new,
			OwnerCity_new,
			OwnerState_new

Select BuildingValue
From PortfolioProject..NashvilleHousing
Where BuildingValue is NULL

Select *
From PortfolioProject..NashvilleHousing
Where BuildingValue = 0


--Potential Analysis

--Why is the Building Value $0? What does the OwnersName and LandUse have in common? Who owns the most property in Nashville? 

--Interesting question: What landuse is most popular when the OwnerName is NULL? 

--Do older houses cost more now or are they relatively cheaper? Is it possible to join a Longitude and Latitude with the ParcelID?

