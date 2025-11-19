# Time Database

## Introduction

Time database represents the time dimension: Year, Half, Quarter, Month, Week and Day

![ER_diagram](images/time_ER_diagram.JPG)

Is usefull to have the time dimension already in place to and use it as base for any other projects wich needs to have some calendar based informations like holidays and weekdays.

Running `EXECEUTE [dbo].[initiaize]	@start_date = N'20190101', @number_of_years = 1, @country_holiday = N'ITA'` stored procedure is possible to initialize all the entities in the hierarchy according to the parameters: with the current implementation only 'ITA' and 'USA' holiday are available.

## Software and Libraries

This project uses TSQL and was developed using 
* [Microsoft Visual Studio Community](https://visualstudio.microsoft.com/vs/community/) 2019 16.3.5
* [Microsoft SQL Server Management Studio](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15) 14.0.17289.0 

## List of activities

In the [TODO.md](TODO.md) file you can find the list of tasks and on going activities.

## Licensing and acknowledgements

Have a look at [LICENSE.md](LICENSE.md).

## Outro

I hope this repository was interesting and thank you for taking the time to check it out. On my Medium you can find a more in depth [story](https://medium.com/@simone-rigoni01/) and on my Blogspot you can find the same [post](https://simonerigoni01.blogspot.com/) in italian. Let me know if you have any question and if you like the content that I create feel free to [buy me a coffee](https://www.buymeacoffee.com/simonerigoni).