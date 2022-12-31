/* 

Housing Data For Data Cleansing

*/


Select * 
From PortfolioProject..NashvilleHousing


/*

Things we should change in order to have a clean Housing Data: (Steps walk-through)

-- Standardize Date Format
-- Populate Property Address data
-- Breaking out Address into Individual Columns (Address, City, State)
-- Change Y and N to Yes and No in "Sold as Vacant" field
-- Remove Duplicates
-- Delete Unused Columns

*/

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

Select SaleDate, CONVERT(date, SaleDate) 
From PortfolioProject..NashvilleHousing

Update PortfolioProject..NashvilleHousing
Set SaleDate = CONVERT(date, SaleDate)


-- If it doesn't Update properly

Alter Table PortfolioProject..NashvilleHousing
Add SaleDateConverted Date

Update PortfolioProject..NashvilleHousing
Set SaleDateConverted = CONVERT(date, SaleDate)

Select SaleDateConverted, CONVERT(date, SaleDate) 
From PortfolioProject..NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

-- In this part we should deal with missing data --> Property Data is something that can't be just NULL 
-- Populate Property Address data

Select *
From PortfolioProject..NashvilleHousing
Where PropertyAddress Is Null
order by ParcelID
-- 29 Rows with Missing Data


Select a.ParcelID, a.PropertyAddress, b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	On a.ParcelID = b.ParcelID
	And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress Is Null


Update a
Set a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	On a.ParcelID = b.ParcelID
	And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress Is Null


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

-- PropertyAddress split to Address and City using SUBSTRING and CHARINDEX

Select PropertyAddress, SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) City
From PortfolioProject..NashvilleHousing


Alter Table PortfolioProject..NashvilleHousing
Add PropertySplitAddress Nvarchar(225)

Update PortfolioProject..NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1)



Alter Table PortfolioProject..NashvilleHousing
Add PropertySplitCity Nvarchar(225)

Update PortfolioProject..NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

Select *
From PortfolioProject.dbo.NashvilleHousing


-- OwnerAddress split to Address, City and State using PARSENAME

Select OwnerAddress, PARSENAME(REPLACE(OwnerAddress,',','.'),3) Address,
PARSENAME(REPLACE(OwnerAddress,',','.'),2) City,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) State
From PortfolioProject..NashvilleHousing


Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitAddress Nvarchar(225)

Update PortfolioProject..NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)


Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitCity Nvarchar(225)

Update PortfolioProject..NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)


Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitState Nvarchar(225)

Update PortfolioProject..NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)


Select *
From PortfolioProject..NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct SoldAsVacant, COUNT(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group By SoldAsVacant
Order By 2


Select SoldAsVacant, Case When SoldAsVacant = 'Y' Then 'Yes'
			  When SoldAsVacant = 'N' Then 'No'
			  Else SoldAsVacant
			  End
From PortfolioProject..NashvilleHousing

Update PortfolioProject..NashvilleHousing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
			When SoldAsVacant = 'N' Then 'No'
			Else SoldAsVacant
			End


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

Select *
From PortfolioProject..NashvilleHousing

;With RowNumCTE As (
Select *, 
	ROW_NUMBER() Over (Partition By ParcelID,
					PropertyAddress,
					SaleDate,
					SalePrice,
					LegalReference
				Order By UniqueID
			     ) Row_Num
From PortfolioProject..NashvilleHousing
--Order By ParcelID
)

Select * 
From RowNumCTE
Where Row_Num > 1
Order By PropertyAddress


-- Another Way:

Select	 ParcelID,
	 PropertyAddress,
	 SaleDate,
	 SalePrice,
	 LegalReference, COUNT(*)
From PortfolioProject..NashvilleHousing
Group By  ParcelID,
	  PropertyAddress,
	  SaleDate,
	  SalePrice,
	  LegalReference   
Having COUNT(*) > 1



-- Before we delete dulicate row IT'S NECESSARY to insert them in a temp table FOR SAFETY

Select * Into PortfolioProject..DuplicatedColumns 
From (Select *, 
		ROW_NUMBER() Over (Partition By ParcelID,
						PropertyAddress,
						SaleDate,
						SalePrice,
						LegalReference
					Order By UniqueID
					) Row_Num
       From PortfolioProject..NashvilleHousing
	) As dup

Select * 
From PortfolioProject..DuplicatedColumns 
Where Row_Num > 1
Order By PropertyAddress


-- Now let's DELETE the duplicate columns

With RowNumCTE As (
Select *, 
	ROW_NUMBER() Over (Partition By ParcelID,
					PropertyAddress,
					SaleDate,
					SalePrice,
					LegalReference
			       Order By UniqueID
				) Row_Num
From PortfolioProject..NashvilleHousing
)

DELETE 
From RowNumCTE
Where Row_Num > 1
-- 104 Rows has been deleted

-- Now let's select again and see if there's any more duplicate columns there or not
With RowNumCTE As (
Select *, 
	ROW_NUMBER() Over (Partition By ParcelID,
					PropertyAddress,
					SaleDate,
					SalePrice,
					LegalReference
			       Order By UniqueID
				) Row_Num
From PortfolioProject..NashvilleHousing
--Order By ParcelID
)

Select * 
From RowNumCTE
Where Row_Num > 1
Order By PropertyAddress

-- NONE 


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From PortfolioProject..NashvilleHousing

Alter Table PortfolioProject..NashvilleHousing
Drop Column PropertyAddress, SaleDate, OwnerAddress, TaxDistrict


-- Clean Data For Housing Data
