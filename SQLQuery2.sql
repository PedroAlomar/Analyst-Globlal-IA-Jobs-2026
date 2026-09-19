IF DB_ID('GlobalAIJobsDW') IS NULL
BEGIN
    CREATE DATABASE GlobalAIJobsDW;
END
GO

USE GlobalAIJobsDW;
GO


IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END
GO


IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dw'
)
BEGIN
    EXEC('CREATE SCHEMA dw');
END
GO



IF OBJECT_ID('stg.GlobalAIJobs', 'U') IS NOT NULL
    DROP TABLE stg.GlobalAIJobs;
GO


CREATE TABLE stg.GlobalAIJobs
(
    Job_ID NVARCHAR(20),
    Job_Title NVARCHAR(150),
    AI_Specialization NVARCHAR(100),
    Industry NVARCHAR(100),
    Company NVARCHAR(150),
    Company_Size NVARCHAR(100),
    Country NVARCHAR(100),
    Continent NVARCHAR(100),
    Education_Required NVARCHAR(100),
    Experience_Level NVARCHAR(100),
    Years_of_Experience DECIMAL(10,2),
    Salary_USD DECIMAL(18,2),
    Salary_Min DECIMAL(18,2),
    Salary_Max DECIMAL(18,2),
    Salary_Category NVARCHAR(50),
    Bonus_Percent DECIMAL(10,2),
    Equity_Offered NVARCHAR(10),
    Benefits_Value_USD DECIMAL(18,2),
    Skills_Required NVARCHAR(1000),
    Required_Certifications NVARCHAR(200),
    Job_Openings INT,
    Competition_Level_Applicants INT,
    Hiring_Difficulty_1_10 DECIMAL(5,2),
    Job_Type NVARCHAR(100),
    Remote_Work_Percent DECIMAL(10,2),
    Work_From_Home_Available NVARCHAR(10),
    Job_Satisfaction_1_10 DECIMAL(5,2),
    Work_Life_Balance_1_10 DECIMAL(5,2),
    AI_Investment_Company_Millions DECIMAL(18,2),
    Company_AI_Maturity_1_10 DECIMAL(5,2),
    Job_Growth_Projection_Percent DECIMAL(10,2),
    Automation_Risk_Percent DECIMAL(10,2),
    Gender_Diversity_Percent_Female DECIMAL(10,2),
    Posted_Date DATE,
    Application_Deadline DATE,
    Record_Created DATE,
    Data_Source NVARCHAR(200)
);
GO

BULK INSERT stg.GlobalAIJobs
FROM 'C:\Users\pedro\Desktop\Global AI Jobs Analytics – Data Warehouse & Power BI\global_ai_jobs_2026.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO



SELECT COUNT(*) AS Total_Registros
FROM stg.GlobalAIJobs;

--validaciones
/* Cantidad de Job_ID distintos */

SELECT COUNT(DISTINCT Job_ID) AS Job_ID_Distintos
FROM stg.GlobalAIJobs;


/* Buscar Job_ID duplicados */

SELECT
    Job_ID,
    COUNT(*) AS Cantidad
FROM stg.GlobalAIJobs
GROUP BY Job_ID
HAVING COUNT(*) > 1;


/* Buscar Job_ID NULL */

SELECT COUNT(*) AS Job_ID_Null
FROM stg.GlobalAIJobs
WHERE Job_ID IS NULL;


/* Validar rangos de porcentajes */

SELECT COUNT(*) AS Porcentajes_Fuera_De_Rango
FROM stg.GlobalAIJobs
WHERE
       Bonus_Percent NOT BETWEEN 0 AND 100
    OR Remote_Work_Percent NOT BETWEEN 0 AND 100
    OR Job_Growth_Projection_Percent NOT BETWEEN -100 AND 100
    OR Automation_Risk_Percent NOT BETWEEN 0 AND 100
    OR Gender_Diversity_Percent_Female NOT BETWEEN 0 AND 100;


/* Validar escalas 1-10 */

SELECT COUNT(*) AS Valores_Fuera_De_Rango
FROM stg.GlobalAIJobs
WHERE
       Hiring_Difficulty_1_10 NOT BETWEEN 1 AND 10
    OR Job_Satisfaction_1_10 NOT BETWEEN 1 AND 10
    OR Work_Life_Balance_1_10 NOT BETWEEN 1 AND 10
    OR Company_AI_Maturity_1_10 NOT BETWEEN 1 AND 10;


/* Validar salarios */

SELECT COUNT(*) AS Salarios_Invalidos
FROM stg.GlobalAIJobs
WHERE
       Salary_USD < 0
    OR Salary_Min < 0
    OR Salary_Max < 0
    OR Salary_Min > Salary_Max;


/* Validar fechas */

SELECT COUNT(*) AS Fechas_Invalidas
FROM stg.GlobalAIJobs
WHERE
    Application_Deadline < Posted_Date;


/* ============================================================
   6. DIMENSION COMPANY
   ============================================================ */

IF OBJECT_ID('dw.DimCompany', 'U') IS NOT NULL
    DROP TABLE dw.DimCompany;
GO


CREATE TABLE dw.DimCompany
(
    Company_Key INT IDENTITY(1,1) PRIMARY KEY,

    Company NVARCHAR(150) NOT NULL,

    Company_Size NVARCHAR(100),

    AI_Investment_Company_Millions DECIMAL(18,2),

    Company_AI_Maturity_1_10 DECIMAL(5,2),

    Gender_Diversity_Percent_Female DECIMAL(10,2)
);
GO


INSERT INTO dw.DimCompany
(
    Company,
    Company_Size,
    AI_Investment_Company_Millions,
    Company_AI_Maturity_1_10,
    Gender_Diversity_Percent_Female
)
SELECT DISTINCT

    Company,

    Company_Size,

    AI_Investment_Company_Millions,

    Company_AI_Maturity_1_10,

    Gender_Diversity_Percent_Female

FROM stg.GlobalAIJobs;
GO


/* ============================================================
   7. DIMENSION LOCATION
   ============================================================ */

IF OBJECT_ID('dw.DimLocation', 'U') IS NOT NULL
    DROP TABLE dw.DimLocation;
GO


CREATE TABLE dw.DimLocation
(
    Location_Key INT IDENTITY(1,1) PRIMARY KEY,

    Country NVARCHAR(100) NOT NULL,

    Continent NVARCHAR(100)
);
GO


INSERT INTO dw.DimLocation
(
    Country,
    Continent
)
SELECT DISTINCT

    Country,
    Continent

FROM stg.GlobalAIJobs;
GO


/* ============================================================
   8. DIMENSION JOB
   ============================================================ */

IF OBJECT_ID('dw.DimJob', 'U') IS NOT NULL
    DROP TABLE dw.DimJob;
GO


CREATE TABLE dw.DimJob
(
    Job_Key INT IDENTITY(1,1) PRIMARY KEY,

    Job_ID NVARCHAR(20) NOT NULL UNIQUE,

    Job_Title NVARCHAR(150) NOT NULL,

    AI_Specialization NVARCHAR(100),

    Industry NVARCHAR(100),

    Education_Required NVARCHAR(100),

    Experience_Level NVARCHAR(100),

    Job_Type NVARCHAR(100),

    Salary_Category NVARCHAR(50),

    Required_Certifications NVARCHAR(200)
);
GO


INSERT INTO dw.DimJob
(
    Job_ID,
    Job_Title,
    AI_Specialization,
    Industry,
    Education_Required,
    Experience_Level,
    Job_Type,
    Salary_Category,
    Required_Certifications
)
SELECT

    Job_ID,

    Job_Title,

    AI_Specialization,

    Industry,

    Education_Required,

    Experience_Level,

    Job_Type,

    Salary_Category,

    Required_Certifications

FROM stg.GlobalAIJobs;
GO


/* ============================================================
   9. DIMENSION DATE
   ============================================================

   Se utilizan las fechas:
   - Posted_Date
   - Application_Deadline
   - Record_Created

   La dimensión contiene una fila por fecha distinta.
   ============================================================ */

IF OBJECT_ID('dw.DimDate', 'U') IS NOT NULL
    DROP TABLE dw.DimDate;
GO


CREATE TABLE dw.DimDate
(
    Date_Key INT PRIMARY KEY,

    Full_Date DATE NOT NULL UNIQUE,

    Year INT,

    Quarter INT,

    Month INT,

    Month_Name NVARCHAR(20),

    Year_Month NVARCHAR(7),

    Day INT,

    Day_of_Week INT,

    Day_Name NVARCHAR(20)
);
GO


INSERT INTO dw.DimDate
(
    Date_Key,
    Full_Date,
    Year,
    Quarter,
    Month,
    Month_Name,
    Year_Month,
    Day,
    Day_of_Week,
    Day_Name
)
SELECT DISTINCT

    CONVERT(INT, CONVERT(CHAR(8), Fecha, 112)) AS Date_Key,

    Fecha AS Full_Date,

    YEAR(Fecha) AS Year,

    DATEPART(QUARTER, Fecha) AS Quarter,

    MONTH(Fecha) AS Month,

    DATENAME(MONTH, Fecha) AS Month_Name,

    CONVERT(CHAR(7), Fecha, 120) AS Year_Month,

    DAY(Fecha) AS Day,

    DATEPART(WEEKDAY, Fecha) AS Day_of_Week,

    DATENAME(WEEKDAY, Fecha) AS Day_Name

FROM
(
    SELECT Posted_Date AS Fecha
    FROM stg.GlobalAIJobs
    WHERE Posted_Date IS NOT NULL

    UNION

    SELECT Application_Deadline
    FROM stg.GlobalAIJobs
    WHERE Application_Deadline IS NOT NULL

    UNION

    SELECT Record_Created
    FROM stg.GlobalAIJobs
    WHERE Record_Created IS NOT NULL
) AS Fechas;
GO


/* ============================================================
   10. DIMENSION SKILL
   ============================================================ */

IF OBJECT_ID('dw.DimSkill', 'U') IS NOT NULL
    DROP TABLE dw.DimSkill;
GO


CREATE TABLE dw.DimSkill
(
    Skill_Key INT IDENTITY(1,1) PRIMARY KEY,

    Skill_Name NVARCHAR(150) NOT NULL UNIQUE
);
GO


/* ============================================================
   11. CARGAR SKILLS CON STRING_SPLIT
   ============================================================ */

INSERT INTO dw.DimSkill
(
    Skill_Name
)
SELECT DISTINCT

    LTRIM(RTRIM(value)) AS Skill_Name

FROM stg.GlobalAIJobs
CROSS APPLY STRING_SPLIT(Skills_Required, ',')

WHERE
    LTRIM(RTRIM(value)) <> '';
GO


/* ============================================================
   12. TABLA PUENTE JOB - SKILL
   ============================================================ */

IF OBJECT_ID('dw.BridgeJobSkill', 'U') IS NOT NULL
    DROP TABLE dw.BridgeJobSkill;
GO


CREATE TABLE dw.BridgeJobSkill
(
    Job_Key INT NOT NULL,

    Skill_Key INT NOT NULL,

    CONSTRAINT PK_BridgeJobSkill
        PRIMARY KEY (Job_Key, Skill_Key),

    CONSTRAINT FK_BridgeJobSkill_Job
        FOREIGN KEY (Job_Key)
        REFERENCES dw.DimJob(Job_Key),

    CONSTRAINT FK_BridgeJobSkill_Skill
        FOREIGN KEY (Skill_Key)
        REFERENCES dw.DimSkill(Skill_Key)
);
GO


/* ============================================================
   13. CARGAR TABLA PUENTE
   ============================================================ */

INSERT INTO dw.BridgeJobSkill
(
    Job_Key,
    Skill_Key
)
SELECT DISTINCT

    J.Job_Key,

    S.Skill_Key

FROM stg.GlobalAIJobs AS STG

INNER JOIN dw.DimJob AS J
    ON STG.Job_ID = J.Job_ID

CROSS APPLY STRING_SPLIT(STG.Skills_Required, ',') AS SS

INNER JOIN dw.DimSkill AS S
    ON S.Skill_Name = LTRIM(RTRIM(SS.value));
GO


/* ============================================================
   14. TABLA DE HECHOS
   ============================================================ */

IF OBJECT_ID('dw.FactJob', 'U') IS NOT NULL
    DROP TABLE dw.FactJob;
GO


CREATE TABLE dw.FactJob
(
    FactJob_Key INT IDENTITY(1,1) PRIMARY KEY,

    Job_Key INT NOT NULL,

    Company_Key INT NOT NULL,

    Location_Key INT NOT NULL,

    Posted_Date_Key INT,

    Application_Deadline_Key INT,

    Record_Created_Date_Key INT,

    Years_of_Experience DECIMAL(10,2),

    Salary_USD DECIMAL(18,2),

    Salary_Min DECIMAL(18,2),

    Salary_Max DECIMAL(18,2),

    Bonus_Percent DECIMAL(10,2),

    Equity_Offered BIT,

    Benefits_Value_USD DECIMAL(18,2),

    Job_Openings INT,

    Competition_Level_Applicants INT,

    Hiring_Difficulty_1_10 DECIMAL(5,2),

    Remote_Work_Percent DECIMAL(10,2),

    Work_From_Home_Available BIT,

    Job_Satisfaction_1_10 DECIMAL(5,2),

    Work_Life_Balance_1_10 DECIMAL(5,2),

    AI_Investment_Company_Millions DECIMAL(18,2),

    Company_AI_Maturity_1_10 DECIMAL(5,2),

    Job_Growth_Projection_Percent DECIMAL(10,2),

    Automation_Risk_Percent DECIMAL(10,2),

    Gender_Diversity_Percent_Female DECIMAL(10,2),

    Data_Source NVARCHAR(200),


    CONSTRAINT FK_FactJob_Job
        FOREIGN KEY (Job_Key)
        REFERENCES dw.DimJob(Job_Key),


    CONSTRAINT FK_FactJob_Company
        FOREIGN KEY (Company_Key)
        REFERENCES dw.DimCompany(Company_Key),


    CONSTRAINT FK_FactJob_Location
        FOREIGN KEY (Location_Key)
        REFERENCES dw.DimLocation(Location_Key),


    CONSTRAINT FK_FactJob_PostedDate
        FOREIGN KEY (Posted_Date_Key)
        REFERENCES dw.DimDate(Date_Key),


    CONSTRAINT FK_FactJob_DeadlineDate
        FOREIGN KEY (Application_Deadline_Key)
        REFERENCES dw.DimDate(Date_Key),


    CONSTRAINT FK_FactJob_RecordCreatedDate
        FOREIGN KEY (Record_Created_Date_Key)
        REFERENCES dw.DimDate(Date_Key)
);
GO


/* ============================================================
   15. CARGAR FACTJOB
   ============================================================ */

INSERT INTO dw.FactJob
(
    Job_Key,

    Company_Key,

    Location_Key,

    Posted_Date_Key,

    Application_Deadline_Key,

    Record_Created_Date_Key,

    Years_of_Experience,

    Salary_USD,

    Salary_Min,

    Salary_Max,

    Bonus_Percent,

    Equity_Offered,

    Benefits_Value_USD,

    Job_Openings,

    Competition_Level_Applicants,

    Hiring_Difficulty_1_10,

    Remote_Work_Percent,

    Work_From_Home_Available,

    Job_Satisfaction_1_10,

    Work_Life_Balance_1_10,

    AI_Investment_Company_Millions,

    Company_AI_Maturity_1_10,

    Job_Growth_Projection_Percent,

    Automation_Risk_Percent,

    Gender_Diversity_Percent_Female,

    Data_Source
)
SELECT

    J.Job_Key,

    C.Company_Key,

    L.Location_Key,


    /* Posted Date */

    CASE
        WHEN STG.Posted_Date IS NOT NULL
        THEN CONVERT(INT, CONVERT(CHAR(8), STG.Posted_Date, 112))
    END,


    /* Application Deadline */

    CASE
        WHEN STG.Application_Deadline IS NOT NULL
        THEN CONVERT(INT, CONVERT(CHAR(8), STG.Application_Deadline, 112))
    END,


    /* Record Created */

    CASE
        WHEN STG.Record_Created IS NOT NULL
        THEN CONVERT(INT, CONVERT(CHAR(8), STG.Record_Created, 112))
    END,


    STG.Years_of_Experience,

    STG.Salary_USD,

    STG.Salary_Min,

    STG.Salary_Max,

    STG.Bonus_Percent,


    /* Yes / No → BIT */

    CASE
        WHEN UPPER(LTRIM(RTRIM(STG.Equity_Offered))) = 'YES'
            THEN 1
        WHEN UPPER(LTRIM(RTRIM(STG.Equity_Offered))) = 'NO'
            THEN 0
        ELSE NULL
    END,


    STG.Benefits_Value_USD,

    STG.Job_Openings,

    STG.Competition_Level_Applicants,

    STG.Hiring_Difficulty_1_10,

    STG.Remote_Work_Percent,


    CASE
        WHEN UPPER(LTRIM(RTRIM(STG.Work_From_Home_Available))) = 'YES'
            THEN 1
        WHEN UPPER(LTRIM(RTRIM(STG.Work_From_Home_Available))) = 'NO'
            THEN 0
        ELSE NULL
    END,


    STG.Job_Satisfaction_1_10,

    STG.Work_Life_Balance_1_10,

    STG.AI_Investment_Company_Millions,

    STG.Company_AI_Maturity_1_10,

    STG.Job_Growth_Projection_Percent,

    STG.Automation_Risk_Percent,

    STG.Gender_Diversity_Percent_Female,

    STG.Data_Source


FROM stg.GlobalAIJobs AS STG


INNER JOIN dw.DimJob AS J
    ON STG.Job_ID = J.Job_ID


INNER JOIN dw.DimCompany AS C
    ON STG.Company = C.Company
    AND STG.Company_Size = C.Company_Size
    AND ISNULL(STG.AI_Investment_Company_Millions, -1)
        = ISNULL(C.AI_Investment_Company_Millions, -1)
    AND ISNULL(STG.Company_AI_Maturity_1_10, -1)
        = ISNULL(C.Company_AI_Maturity_1_10, -1)
    AND ISNULL(STG.Gender_Diversity_Percent_Female, -1)
        = ISNULL(C.Gender_Diversity_Percent_Female, -1)


INNER JOIN dw.DimLocation AS L
    ON STG.Country = L.Country
    AND ISNULL(STG.Continent, '')
        = ISNULL(L.Continent, '');
GO


/* ============================================================
   16. VALIDACIONES DE DIMENSIONES
   ============================================================ */


/* DimCompany */

SELECT
    'DimCompany' AS Tabla,
    COUNT(*) AS Registros
FROM dw.DimCompany;


/* DimJob */

SELECT
    'DimJob' AS Tabla,
    COUNT(*) AS Registros
FROM dw.DimJob;


/* DimLocation */

SELECT
    'DimLocation' AS Tabla,
    COUNT(*) AS Registros
FROM dw.DimLocation;


/* DimDate */

SELECT
    'DimDate' AS Tabla,
    COUNT(*) AS Registros
FROM dw.DimDate;


/* DimSkill */

SELECT
    'DimSkill' AS Tabla,
    COUNT(*) AS Registros
FROM dw.DimSkill;


/* BridgeJobSkill */

SELECT
    'BridgeJobSkill' AS Tabla,
    COUNT(*) AS Registros
FROM dw.BridgeJobSkill;


/* FactJob */

SELECT
    'FactJob' AS Tabla,
    COUNT(*) AS Registros
FROM dw.FactJob;
GO


/* ============================================================
   17. VALIDAR QUE TODOS LOS JOBS LLEGARON A FACT
   ============================================================ */

SELECT
    COUNT(*) AS Jobs_STG
FROM stg.GlobalAIJobs;


SELECT
    COUNT(*) AS Jobs_DimJob
FROM dw.DimJob;


SELECT
    COUNT(*) AS Jobs_Fact
FROM dw.FactJob;
GO


/* ============================================================
   18. JOBS QUE NO LLEGARON A FACT
   ============================================================ */

SELECT

    STG.Job_ID

FROM stg.GlobalAIJobs AS STG

LEFT JOIN dw.FactJob AS F
    INNER JOIN dw.DimJob AS J
        ON F.Job_Key = J.Job_Key

    ON J.Job_ID = STG.Job_ID

WHERE F.FactJob_Key IS NULL;
GO


/* ============================================================
   19. VALIDAR FOREIGN KEYS
   ============================================================ */


/* Jobs sin Company */

SELECT COUNT(*) AS Jobs_Sin_Company
FROM dw.FactJob F
LEFT JOIN dw.DimCompany C
    ON F.Company_Key = C.Company_Key
WHERE C.Company_Key IS NULL;


/* Jobs sin Location */

SELECT COUNT(*) AS Jobs_Sin_Location
FROM dw.FactJob F
LEFT JOIN dw.DimLocation L
    ON F.Location_Key = L.Location_Key
WHERE L.Location_Key IS NULL;


/* Jobs sin Posted Date */

SELECT COUNT(*) AS Jobs_Sin_Posted_Date
FROM dw.FactJob F
LEFT JOIN dw.DimDate D
    ON F.Posted_Date_Key = D.Date_Key
WHERE D.Date_Key IS NULL
  AND F.Posted_Date_Key IS NOT NULL;
GO


/* ============================================================
   20. VALIDAR RELACIÓN JOB - SKILL
   ============================================================ */


/* Cantidad de skills por Job */

SELECT TOP 20

    J.Job_ID,

    J.Job_Title,

    COUNT(B.Skill_Key) AS Cantidad_Skills

FROM dw.DimJob J

LEFT JOIN dw.BridgeJobSkill B
    ON J.Job_Key = B.Job_Key

GROUP BY

    J.Job_ID,
    J.Job_Title

ORDER BY
    Cantidad_Skills DESC;
GO


/* ============================================================
   21. SKILLS MÁS SOLICITADAS
   ============================================================ */

SELECT TOP 20

    S.Skill_Name,

    COUNT(*) AS Cantidad_Ofertas

FROM dw.BridgeJobSkill B

INNER JOIN dw.DimSkill S
    ON B.Skill_Key = S.Skill_Key

GROUP BY
    S.Skill_Name

ORDER BY
    Cantidad_Ofertas DESC;
GO


/* ============================================================
   22. EMPRESAS CON MÁS OFERTAS
   ============================================================ */

SELECT TOP 20

    C.Company,

    COUNT(*) AS Cantidad_Ofertas

FROM dw.FactJob F

INNER JOIN dw.DimCompany C
    ON F.Company_Key = C.Company_Key

GROUP BY
    C.Company

ORDER BY
    Cantidad_Ofertas DESC;
GO


/* ============================================================
   23. OFERTAS POR PAÍS
   ============================================================ */

SELECT

    L.Country,

    L.Continent,

    COUNT(*) AS Cantidad_Ofertas

FROM dw.FactJob F

INNER JOIN dw.DimLocation L
    ON F.Location_Key = L.Location_Key

GROUP BY

    L.Country,
    L.Continent

ORDER BY
    Cantidad_Ofertas DESC;
GO


/* ============================================================
   24. SALARIO PROMEDIO POR ESPECIALIZACIÓN
   ============================================================ */

SELECT

    J.AI_Specialization,

    COUNT(*) AS Cantidad_Ofertas,

    AVG(F.Salary_USD) AS Salario_Promedio,

    MIN(F.Salary_USD) AS Salario_Minimo,

    MAX(F.Salary_USD) AS Salario_Maximo

FROM dw.FactJob F

INNER JOIN dw.DimJob J
    ON F.Job_Key = J.Job_Key

GROUP BY
    J.AI_Specialization

ORDER BY
    Salario_Promedio DESC;
GO


/* ============================================================
   25. SALARIO POR NIVEL DE EXPERIENCIA
   ============================================================ */

SELECT

    J.Experience_Level,

    COUNT(*) AS Cantidad_Ofertas,

    AVG(F.Salary_USD) AS Salario_Promedio

FROM dw.FactJob F

INNER JOIN dw.DimJob J
    ON F.Job_Key = J.Job_Key

GROUP BY
    J.Experience_Level

ORDER BY
    Salario_Promedio DESC;
GO


/* ============================================================
   26. TRABAJO REMOTO
   ============================================================ */

SELECT

    J.Industry,

    COUNT(*) AS Cantidad_Ofertas,

    AVG(F.Remote_Work_Percent) AS Remote_Work_Promedio,

    AVG(F.Salary_USD) AS Salario_Promedio

FROM dw.FactJob F

INNER JOIN dw.DimJob J
    ON F.Job_Key = J.Job_Key

GROUP BY
    J.Industry

ORDER BY
    Remote_Work_Promedio DESC;
GO


/* ============================================================
   27. OFERTAS POR MES DE PUBLICACIÓN
   ============================================================ */

SELECT

    D.Year,

    D.Month,

    D.Month_Name,

    COUNT(*) AS Cantidad_Ofertas

FROM dw.FactJob F

INNER JOIN dw.DimDate D
    ON F.Posted_Date_Key = D.Date_Key

GROUP BY

    D.Year,
    D.Month,
    D.Month_Name

ORDER BY

    D.Year,
    D.Month;
GO


/* ============================================================
   28. RELACIÓN ENTRE EXPERIENCIA Y SALARIO
   ============================================================ */

SELECT

    F.Years_of_Experience,

    COUNT(*) AS Cantidad_Ofertas,

    AVG(F.Salary_USD) AS Salario_Promedio

FROM dw.FactJob F

GROUP BY
    F.Years_of_Experience

ORDER BY
    F.Years_of_Experience;
GO


/* ============================================================
   29. OFERTAS CON MAYOR RIESGO DE AUTOMATIZACIÓN
   ============================================================ */

SELECT TOP 20

    J.Job_Title,

    J.AI_Specialization,

    J.Industry,

    F.Automation_Risk_Percent,

    F.Salary_USD

FROM dw.FactJob F

INNER JOIN dw.DimJob J
    ON F.Job_Key = J.Job_Key

ORDER BY
    F.Automation_Risk_Percent DESC;
GO


/* ============================================================
   30. OFERTAS CON MAYOR PROYECCIÓN DE CRECIMIENTO
   ============================================================ */

SELECT TOP 20

    J.Job_Title,

    J.AI_Specialization,

    J.Industry,

    F.Job_Growth_Projection_Percent,

    F.Salary_USD

FROM dw.FactJob F

INNER JOIN dw.DimJob J
    ON F.Job_Key = J.Job_Key

ORDER BY
    F.Job_Growth_Projection_Percent DESC;
GO


/* ============================================================
   31. RESUMEN GENERAL DEL DATA WAREHOUSE
   ============================================================ */

SELECT

    COUNT(*) AS Total_Ofertas,

    COUNT(DISTINCT Company_Key) AS Empresas,

    COUNT(DISTINCT Location_Key) AS Ubicaciones,

    COUNT(DISTINCT Job_Key) AS Puestos,

    AVG(Salary_USD) AS Salario_Promedio,

    MIN(Salary_USD) AS Salario_Minimo,

    MAX(Salary_USD) AS Salario_Maximo,

    AVG(Remote_Work_Percent) AS Remote_Work_Promedio,

    AVG(Job_Satisfaction_1_10) AS Satisfaccion_Promedio,

    AVG(Work_Life_Balance_1_10) AS Work_Life_Balance_Promedio

FROM dw.FactJob;
GO

