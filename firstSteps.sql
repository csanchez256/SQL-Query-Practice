/* These queries were originally written by my co-worker Brian Robbins
	I am using this a basis to learn queries and annotating 
	as I go along with my own notes
*/

/* Change a table and add another field */
/* alter table <table name> add <new field> <data type> */
/* example: */

ALTER TABLE T_Code ADD Asset_Type TEXT;

/* Set the asset type based on existing information
based on t_code table and the template - BR
*/

/* t_code is a table */
/* update <table name> */

/* 
  SYNTAX: <alias 'or table name'> . < column name>
   the dot operator also called "membership operator" 

    explanation on the SELECT statement 
 	select <column1, column2, ... >
 	from <table_name>
 	where <condition>
*/

/*
	SYNTAX: for 'AS' keyword
	<table name> AS <alias>

	note: when I say "alias" i mean a 'nickname' that I bind to
	the table name
/*

With the UPDATE statement, you can change the value of one or more columns 
in each row that meets the search condition of the WHERE clause

*/
UPDATE T_CODE 
LEFT JOIN 
	(SELECT T_Family.Asset_Type AS assettype, 
	        gdmNonsense.gdm_tcode_id AS tcodeid 
	 FROM 
		(SELECT T_GDM_Code.T_Code_ID as gdm_tcode_id, 
		 T_GDM_Code.T_Group_ID as gdm_tgroup_id,
		 T_Group.T_Family_ID AS gdm_family_id 
		 FROM T_GDM_Code
		 LEFT JOIN T_Group 
		 ON T_GDM_Code.T_Group_ID = T_Group.T_Group_ID)
	 AS gdmNonsense 
	 LEFT JOIN T_Family 
	 ON gdmNonsense.gdm_family_id = T_Family.T_Family_ID)
	 AS Family
ON Family.tcodeid = T_Code.T_Code_ID
SET T_Code.Asset_Type = Family.assettype;

-- Make note of the counts of these results to check updates later.
SELECT  MLO.Code,
count( MLO.Code )
FROM MLO 
LEFT JOIN 
	(SELECT Code 
	 FROM T_Code 
	 WHERE Asset_Type = 'ML') AS tcode
ON MLO.Code = tcode.Code 
WHERE tcode.Code IS NULL 
group by MLO.code
ORDER BY MLO.Code;

-- Append existing observation text to the remarks to preserve existing data. First statement for where MLO Remarks are not null, 2nd statement for where MLO remarks are null
UPDATE MLO SET Remarks = (Observation_Text & ' ' & '(' & Remarks & ')') WHERE Remarks IS NOT NULL AND Remarks <> '';
UPDATE MLO SET Remarks = Observation_Text WHERE Remarks IS NULL OR Remarks = '';

-- Set the observation text to the code description from T_Code.
UPDATE MLO INNER JOIN T_Code ON T_Code.Code = MLO.Code SET Observation_Text = Code_Description;

-- Strip out illegal characters
UPDATE MLO SET remarks = REPLACE(MLO.remarks, Chr(39), '');
UPDATE MLO SET remarks = REPLACE(MLO.remarks, Chr(34), '');
UPDATE MLO SET Remarks = REPLACE(Remarks, '''', ''); --Same as chr(39)
UPDATE MLO SET Remarks = REPLACE(Remarks, '"', '');--Same as chr(34)
UPDATE MLO SET Remarks = REPLACE(Remarks, '@', '');
UPDATE MLO SET Remarks = REPLACE(Remarks, '#', '');
UPDATE ML SET Street = REPLACE(Street, '@', '');
UPDATE ML SET Street = REPLACE(Street, '#', '');
UPDATE ML SET location = REPLACE(location, '@', '');
UPDATE ML SET location = REPLACE(location, '#', '');

-- Girtys Run Wincan
-- Update fields from t_field_combo_code based on t_field_combo_group_id
-- direction 
UPDATE MLI 
INNER JOIN T_FIELD_COMBO_CODE
ON t_field_combo_code.code = MLI.inspection_direction 
SET inspection_direction = combo_description
WHERE mli.inspection_direction = t_field_combo_code.code
AND T_Field_Combo_Code.T_Field_Combo_Group_id = 87;

-- pre-cleaning
UPDATE MLI 
INNER JOIN T_FIELD_COMBO_CODE
ON t_field_combo_code.code = MLI.Cleaned
SET Cleaned = combo_description
WHERE mli.Cleaned = t_field_combo_code.code
AND T_Field_Combo_Code.T_Field_Combo_Group_id = 10;

-- Location
UPDATE ML
INNER JOIN T_FIELD_COMBO_CODE
ON t_field_combo_code.code = ML.Location
SET ML.Location = T_Field_Combo_Code.combo_description
WHERE ML.Location = t_field_combo_code.code
AND T_Field_Combo_Code.T_Field_Combo_Group_id = 11;

--Unknown Locations
--Append location code from location field to remarks field
UPDATE ML
SET Remark = ('Location code ' &Location & ' ' & '(' & Remark & ')')
WHERE Remark IS NOT NULL
OR Remark <> ''
AND Location IS NOT NULL;

UPDATE ML
SET Remark = ('Location ' &Location)
WHERE (Remark IS NULL
OR Remark = '')
AND Location IS NOT NULL;

--Update ML with ITpipes location
UPDATE ML
INNER JOIN T_FIELD_COMBO_CODE
ON t_field_combo_code.code = ML.Location
SET ML.Location = T_Field_Combo_Code.combo_description
WHERE ML.Location = t_field_combo_code.code
AND T_Field_Combo_Code.T_Field_Combo_Group_id = 11
AND ML.Location <> ''
AND ML.Location is not null;

--Append material code from material field to remarks field
UPDATE ML
SET Remark = ('Material:' &ML.Material & ' (' &Remark &')')
where (Remark IS NOT NULL
OR Remark <> '')
AND Material IS NOT NULL;

UPDATE ML
SET Remark = ('Material:' &Material)
WHERE (Remark IS NULL
OR Remark = '')
AND Material IS NOT NULL;
-- Update Material
UPDATE ML
INNER JOIN T_FIELD_COMBO_CODE
ON t_field_combo_code.code = ML.Material
SET ML.Material = T_Field_Combo_Code.combo_description
WHERE ML.Material = t_field_combo_code.code
AND T_Field_Combo_Code.T_Field_Combo_Group_id = 9;
-- Unknown Materials
UPDATE ML
INNER JOIN T_FIELD_COMBO_CODE
ON t_field_combo_code.code = ML.Material
SET ML.Material = t_field_combo_code.combo_description
WHERE ML.Material <> t_field_combo_code.code
AND T_Field_Combo_Code.T_Field_Combo_Group_id = 9
AND T_Field_Combo_Code.code = 'ZZZ';

-- Pipe Shape
UPDATE ML
SET pipe_shape = ('Shape:' &ML.pipe_shape & ' (' &Remark &')')
where (Remark IS NOT NULL
OR Remark <> '')
AND pipe_shape IS NOT NULL;

UPDATE ML
SET Remark = ('Shape:' &pipe_shape)
WHERE (Remark IS NULL
OR Remark = '')
AND pipe_shape IS NOT NULL;

--Append shape to remarks field
UPDATE ML
SET Remark = ('Shape:' &ML.pipe_shape & ' (' &Remark &')')
where (Remark IS NOT NULL
OR Remark <> '')
AND pipe_shape IS NOT NULL;

UPDATE ML
SET Remark = ('Shape:' &pipe_shape)
WHERE (Remark IS NULL
OR Remark = '')
AND pipe_shape IS NOT NULL;

-- Update Shape field
UPDATE ML
INNER JOIN T_FIELD_COMBO_CODE
ON t_field_combo_code.code = right(ml.pipe_shape, 1)
SET ML.pipe_shape = T_Field_Combo_Code.combo_description
WHERE right(ml.pipe_shape, 1) = t_field_combo_code.code
AND T_Field_Combo_Code.T_Field_Combo_Group_id = 2
AND ML.Pipe_Shape is not null
AND ML.Pipe_Shape <> '';

-- Set capitalization uniformity in all fields.
UPDATE ML
SET City = StrConv(ML.City, 3)
where City IS NOT NULL;

UPDATE ML
SET Street = StrConv(ML.Street, 3)
where Street IS NOT NULL;










