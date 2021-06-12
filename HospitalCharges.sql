-- Select all
select *
from HospitalCharges

-- Check Column data type for SQL Server
exec sp_help HospitalCharges

-- Checking for NULL values
select count(*)
from HospitalCharges
where Average_Covered_Charges is NULL

-- add new columns as float and VarChar for zip code
alter table HospitalCharges
add AvgCoveredCost float,
	AvgTotalPayments float,
	AvgMedicarePayments float,
	newZipCode varchar(5)

-- Remove $ from String and update table
update HospitalCharges
	set AvgCoveredCost = SUBSTRING(Average_Covered_Charges, 2,100),
		AvgTotalPayments = SUBSTRING(Average_Total_Payments, 2, 100),
		AvgMedicarePayments = SUBSTRING(Average_Medicare_Payments, 2, 100),
		newZipCode = right('00000' + cast(Provider_Zip_Code as varchar(5)), 5)

-- 
--Rename Column to EventType
sp_rename 'hospitalcharges.DRG_Definition', 'EventType', 'COLUMN'
		  'hospitalcharges.newZipCode', 'zipCode','COLUMN';

-- Removes int in column 'EventType'
UPDATE HospitalCharges
SET EventType = RIGHT(EventType, LEN(EventType) - 5)

-- Drop Original int version of the ZipCodes
ALTER TABLE hospitalcharges
DROP column Provider_Zip_Code;

-- Check for duplicates
WITH duplicateCTE AS (
select *, 
		ROW_NUMBER() OVER (
		PARTITION BY EventType,
					 Provider_Id,
					 Total_Discharges,
					 AvgCoveredCost,
					 AvgTotalPayments
					 ORDER BY EventType) row_num
from HospitalCharges)
select *
from duplicateCTE
where row_num > 1;

-- Most expensive procedures
select EventType, round(AVG(AvgTotalPayments),2) as cost
	from HospitalCharges
		group by EventType
		order by 2 DESC;

-- Busiest Medical Network Provider
select Provider_Name, sum(total_discharges) as TotalPatients
	from HospitalCharges
		group by Provider_name
		order by 2 DESC;

-- Which State covers the most amount of the costs
select Provider_State, round(avg(AvgMedicarePayments/AvgCoveredCost),2)*100 as PercentCovered
		from HospitalCharges
			group by Provider_State
			order by PercentCovered DESC;

-- Coverage by procedure in Maryland
select EventType,Provider_state as State, round(avg(AvgMedicarePayments/AvgCoveredCost),2)*100 as PercentCovered
	from HospitalCharges
		where Provider_State = 'MD'
		group by EventType, Provider_state
		order by PercentCovered DESC;

-- Coverage by procedure
select EventType, round(avg(AvgMedicarePayments/AvgCoveredCost),2)*100 as PercentCovered
	from HospitalCharges
		group by EventType
		order by PercentCovered DESC;

--Which State has the most amount of Patients?
SELECT RIGHT(REPLICATE(0, 5) + Provider_Zip_Code, 5) as ZipCode
from HospitalCharges
	order by ZipCode asc

--Total Patients by ZipCode
select ZipCode, Provider_City, Provider_State, sum(Total_Discharges) as totalPatients
	from HospitalCharges
	group by ZipCode, Provider_City, Provider_State
	order by totalPatients desc;

-- Which ZipCodes have the greatest amount of network providers?
select provider_city, ZipCode, count(distinct Provider_Name) as amount
	from HospitalCharges
	group by provider_city, ZipCode
	order by amount desc;