-- Name-Add_Married.sql
/*
2012-11-24 Tom Holden ve3meo

-- 2020-01-21 Updated for RM8 Pat Jones

Inserts an Alternate Name of type "Married" for female "Wife" spouses
in a "Family" where no Alternate Surname matches the male "Husband's" and
a (family) Marriage fact exists. 

Prefixes with "Mrs.".
Suffixes the birth name in parentheses ().

Assigns the Marriage date and sortdate to the Alternate Name.

Sets the fact to Not Private and the fact sentence to ' ', assuming the user wishes to have 
the Married Name show on the Publish Online website Name Index but not in narrative reports. It will
show in other reports but alternate names do not come out in report Name Indexes.

Because the NameTable uses the RMNOCASE collation, the query first REINDEXes
the database against the fake RMNOCASE collation. Following the query,
it is essential to use RootsMagic's File > Database tools > Rebuild Indexes, i.e.,
do not use this procedure on databases prior to RootsMagic 5.
*/

-- Following deletes all Alternate Names of type Married
-- DELETE FROM NameTable WHERE NameType = 5 AND NOT +IsPrimary;

-- Name-Add_Married
REINDEX -- because following procedure does string matches on columns indexed using RMNOCASE
;

INSERT OR REPLACE INTO NameTable
(NameID,OwnerID,Surname,Given,Prefix,Suffix,Nickname,NameType,Date,SortDate,IsPrimary,IsPrivate,Proof,Sentence,Note,BirthYear,DeathYear) -- RM8 change (avoids having to fill all fields)
SELECT
 NULL AS NameID, 
 Wife.OwnerID AS OwnerID, 
 Husband.Surname AS Surname, 
 Husband.Given AS Given,
 'Mrs.' AS Prefix,
 '(' || Wife.Surname || ', ' || Wife.Given || ')' AS Suffix, 
 Wife.Nickname AS Nickname,
 5 AS NameType, 
 Event.Date AS Date, -- set to ',' for undated, Event.Date to match Marriage date.
 CASE Event.SortDate & 1023
  WHEN 1023 THEN Event.SortDate --
  ELSE Event.SortDate + 1
 END AS SortDate,
-- Event.SortDate +1 AS SortDate, -- set to 9223372036854775807 to sort with undated Alt Names, Event.SortDate to match Marriage
 0 AS IsPrimary,
 0 AS IsPrivate, -- set to 1 to make Private
 0 AS Proof,
-- RM8 change 0.0 AS EditDate,
-- 'After [person:hisher] marriage, [person] was also known as [Desc].' AS Sentence,
 ' ' AS Sentence, -- a blank space to prevent the default sentence from being outputted
 '' AS Note,
 Wife.BirthYear AS BirthYear,
 Wife.DeathYear AS DeathYear
FROM NameTable Wife  
INNER JOIN FamilyTable Family ON Wife.OwnerID=MotherID AND +Wife.IsPrimary
INNER JOIN NameTable Husband ON FatherID = Husband.OwnerID AND +Husband.IsPrimary
INNER JOIN EventTable Event ON Family.FamilyID = Event.OwnerID AND Event.EventType = 300
INNER JOIN PersonTable Person2 ON Wife.OwnerID = Person2.PersonID AND Person2.Sex=1
INNER JOIN PersonTable Person1 ON Husband.OwnerID = Person1.PersonID AND Person1.Sex=0
WHERE 
 Wife.Surname NOT LIKE Husband.Surname AND
 Wife.OwnerID NOT IN
(
-- Wives with Alternate Surnames matching Husband's Surname
SELECT Wife.OwnerID --, Wife.IsPrimary, Wife.Given, Wife.Surname, Husband.Surname 
FROM NameTable Wife  
INNER JOIN FamilyTable ON Wife.OwnerID=MotherID AND NOT +Wife.IsPrimary
INNER JOIN NameTable Husband ON FatherID = Husband.OwnerID AND +Husband.IsPrimary
WHERE Wife.Surname LIKE Husband.Surname
   OR Wife.Surname LIKE Wife.Surname || '-' || Husband.Surname
)
;

----- BE SURE TO REBUILD INDEXES IN ROOTSMAGIC ----