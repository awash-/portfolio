# Wrangling CSVs into Postgres

## 1. The purpose
One of my clients is an upstart real estate development company looking to build their own product-specific database. The data that they use is unique to their niche, so they want a scalable way of storing the data that they've gathered so far. The goal was to have something to grow with the company over time. The previous method (spreadsheets) worked for smaller-scale projects, but became unwieldy when more data was gradually introduced. <br>

PostgresSQL was chosen specifically for its utility in GIS applications. Since this client makes heavy use of ESRI's ArcGIS suite of tools, I wanted something with easy connectivity. The need for easy connectivity ruled out many of the popular open source options. Yet I still wanted to use something open source so that the client wasn't out of thousands of dollars if this DBMS didn't work out. With these criteria in mind, Postgres was the most effective solution. Above all else, PostGIS introduces geospatial-specific capabilities that will be useful further down the road.

## 2. The process
### Identifying the problem
We had a lot of CSVs. Several employees would gather data and input them into separate sheets. The base data would look something like the following table:

| Grocery Store | Address | City | State | Apple Price | Banana Price |
| ----------- | ----------- | ------- | --- | --- | --- |
| Winn Dixie | 100 N. Main | Jacksonville | FL | | |
| Aldis | 58 Magnolia | Natchitoches | LA | | | |
| Harolds Meat Market | 402 Reagan Causeway | Dallas | TX | | |     <br><br>

Of course, data entry and data analysis are two totally different things. So the employees inputting the data would put in all sorts of interesting data that's legible to the human eye but not great for processing.

| Grocery Store | Address | City | State | Apple Price | Banana Price |
| ----------- | ----------- | ------- | --- | --- | --- |
| Winn Dixie | 100 N. Main | Jacksonville | FL | NO PRICE, WILL CALL BACK LATER | I'm putting apostrophes in here |
| Aldis | 58 Magnolia | Natchitoches | LA | $1.50 | 25 cents | 
| Harolds Meat Market | 402 Reagan Causeway | Dallas | TX | 0.80 | 0.25 |     <br><br>

This same issue was found throughout thousands of other records. Additionally, there was no way to control for duplicates. So if two people called the same store and only one got price data, that price data may have been lost if doing a simple "Remove Duplicates" function in Excel.

### Setting everything up - the csvs
The joy of SQL and RDBMS overall is the primary key, or `pkey`. The `pkey` doesn't allow NULLS or duplicates, making it the perfect way to control for unclean data. I set the unique identifier to a combination of the store name, address, city, and state. 

pkey | Grocery Store | Address | City | State | Apple Price | Banana Price |
| ------- | ----------- | ----------- | ------- | --- | --- | --- |
| WINN100JAFL | Winn Dixie | 100 N. Main | Jacksonville | FL | NO PRICE, WILL CALL BACK LATER | unknown |
| ALDI58MNALA | Aldis | 58 Magnolia | Natchitoches | LA | $1.50 | 25 cents | 
| HARO402DATX | Harolds Meat Market | 402 Reagan Causeway | Dallas | TX | 0.80 | 0.25 |     <br><br>

Once the primary key was established, I got to work cleaning the data. Since much of the data was inputted for human eyes, there were a lot of illegal characters. To keep it simple and agile, I did this part in Excel. For larger datasets, I prefer to make use of `pandas.Series.map` due to processing speeds and memory consumption.4

### Setting everything up - the database
One of my favorite things about SQL is the precision required when setting everything up. Excel and ArcGIS will often try to infer data types, which leads to headaches and time wasted. `pandas` occasionally attempts this as well (despite setting dtypes), and often the troubleshooting can consume valuable time -- which is not something that freelance consultants have the luxury of doing!

I kept it simple and created one table to base the others off of.

```
CREATE TABLE grocery_base (
    pkey char(11) PRIMARY KEY,
    grocery_store char(250),
    address char(250),
    city char(250),
    state char(2),
    apple_price float,
    banana_price float,
    lat double precision,
    lon double precision
);
```

`grocery_base` is the main table that ArcGIS pulls from. Therefore, I didn't want to pull data directly into it until I was certain of its cleanliness. I imported the additional tables using the `CREATE TABLE name AS grocery_base` syntax. These tables are staging tables so I can trace my steps. For future databases I'd rather set up a recursion function to optimize memory usage.

To populate the newly-created tables, I used psql's `\copy FROM` function for each csv. Again, recursion is likely the best option moving forward but this is my first time setting up a RDBMS so I cut myself some slack. 

With our staging and base tables created, the only thing left to do was merge them! In psql, what would normally be a pythonic merge is instead called `UPSERT`, a portmanteau of "update" and "insert". I would move each staging table into the base table using the following syntax:

```
INSERT INTO grocery_base (apple_price,banana_price)
SELECT ON (la.pkey) pkey, apple_price, banana_price
FROM grocery_louisiana AS la
WHERE pkey = la.pkey
ON CONFLICT (pkey) DO UPDATE 
	SET
        apple_price= EXCLUDED.apple_price
        banana_price= EXCLUDED.banana_price
```

I would check the data and know it was working if everything showed up in ArcGIS. My client also liked having an export of the data, so I would `\copy TO` a csv for the client to run their own calculations on the data.

## 3. Further considerations
Recursion, recursion, recursion! Having become a little more comfortable in Python recently, it pained me to manually copy/paste the same tasks. But this project had a relatively quick turnaround so done is better than perfectly executed.

I know that it's possible to join all of this data into a large csv via `pandas` or RStudio as well. However, psql comes with pgadmin. pgadmin is an easily navigable GUI that shows use metrics, writes common queries, and even allows the user to import and export. Ultimately I want my workflow to be easily transferable and transparent and pgadmin allows for that possibility.