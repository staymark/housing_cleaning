-- FORMAT DATE

-- format saledate to yyyy-mm-dd
update nashville_housing
set saledate = cast(saledate as date);

-- change saledate columntype to date
alter table nashville_housing
alter column saledate type date
using to_date(saledate, 'YYYY-MM-DD');


-- FILL EMPTY PROPERTY ADDRESS DATA

-- Note: whenever there are duplicate parcelids, the propertyaddress is the same;
-- however, the uniqueids are not
select *
from nashville_housing
order by parcelid;

-- check null values
select nh1.parcelid, 
	nh1.propertyaddress, 
	nh2.parcelid, 
	nh2.propertyaddress,
	coalesce(nh1.propertyaddress, nh2.propertyaddress)
from nashville_housing nh1
inner join nashville_housing nh2
	on nh1.parcelid = nh2.parcelid
	and nh1.uniqueid != nh2.uniqueid
where nh1.propertyaddress is null;

-- fill null values
update nashville_housing nh1
set propertyaddress = nh2.propertyaddress
from nashville_housing nh2
where nh1.parcelid = nh2.parcelid
	and nh1.uniqueid != nh2.uniqueid
	and nh1.propertyaddress is null;


-- RENAME COLUMNS propertyaddress AND owneraddress

-- rename propertyaddress
alter table nashville_housing
rename propertyaddress to fullpropertyaddress

-- rename owneraddress
alter table nashville_housing
rename owneraddress to fullowneraddress


-- SEPARATE propertyaddress INTO COLUMNS (address, city)

-- create address and city columns for fullpropertyaddress
alter table nashville_housing 
add column propertyaddress varchar(50),
add column propertycity varchar(50)

-- separate fullpropertyaddress into address and city
update nashville_housing 
set propertyaddress = split_part(fullpropertyaddress, ',', 1),
	propertycity = split_part(fullpropertyaddress, ',', 2)

	
-- SEPARATE owneraddress INTO COLUMNS (address, city, state)

-- create address, city, state columns for fullowneraddress
alter table nashville_housing 
add column owneraddress varchar(50),
add column ownercity varchar(50),
add column ownerstate varchar(50)

-- separate fullowneraddress into address, city, and state
update nashville_housing 
set	owneraddress = split_part(fullowneraddress, ',', 1),
	ownercity = split_part(fullowneraddress, ',', 2),
	ownerstate = split_part(fullowneraddress, ',', 3)

	
-- REMOVE WHITESPACE FROM ADDED COLUMNS
update nashville_housing
set propertycity = trim(propertycity),
	ownercity = trim(ownercity),
	ownerstate = trim(ownerstate)

	
-- CONVERT Y AND N TO YES AND NO IN soldasvacant COLUMN
	
-- soldasvacant has Yes, Y, N, and No as possible entrys
select distinct(soldasvacant),
count(soldasvacant)
from nashville_housing
group by soldasvacant ;

-- change Y to Yes and N to No
update nashville_housing
set soldasvacant = 
	case
		when soldasvacant = 'Y' then 'Yes'
		when soldasvacant = 'N' then 'No'
		else soldasvacant
	end

	
-- IDENTIFY DUPLICATE ROWS

-- looking for duplicate rows (not accounting for uniqueid)
-- cte to identify unique and duplicate rows	
with row_num_cte as (
	select *,
		row_number() over (
			partition by parcelid,
				landuse,
				fullpropertyaddress,
				saledate,
				saleprice,
				legalreference,
				soldasvacant,
				ownername,
				fullowneraddress,
				acreage,
				taxdistrict,
				landvalue,
				buildingvalue,
				totalvalue,
				yearbuilt,
				bedrooms,
				fullbath,
				halfbath
			order by parcelid
		) as row_num
from nashville_housing
)

-- select rows that are duplicates
select *
from row_num_cte
where row_num > 1
order by parcelid
