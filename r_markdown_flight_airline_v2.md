Flight_Price_Airline
================
Harper Ream
4/7/2022

``` r
library(tidyverse)
```

    ## Warning: package 'tidyverse' was built under R version 4.1.3

    ## -- Attaching packages --------------------------------------- tidyverse 1.3.1 --

    ## v ggplot2 3.3.5     v purrr   0.3.4
    ## v tibble  3.1.6     v dplyr   1.0.8
    ## v tidyr   1.2.0     v stringr 1.4.0
    ## v readr   2.1.2     v forcats 0.5.1

    ## -- Conflicts ------------------------------------------ tidyverse_conflicts() --
    ## x dplyr::filter() masks stats::filter()
    ## x dplyr::lag()    masks stats::lag()

``` r
library(readr)
library(ggplot2)
library(lubridate)
```

    ## Warning: package 'lubridate' was built under R version 4.1.3

    ## 
    ## Attaching package: 'lubridate'

    ## The following objects are masked from 'package:base':
    ## 
    ##     date, intersect, setdiff, union

``` r
library(skimr)
```

    ## Warning: package 'skimr' was built under R version 4.1.3

``` r
library(dplyr)
library(zoo)
```

    ## Warning: package 'zoo' was built under R version 4.1.3

    ## 
    ## Attaching package: 'zoo'

    ## The following objects are masked from 'package:base':
    ## 
    ##     as.Date, as.Date.numeric

``` r
library(ggpubr)
```

    ## Warning: package 'ggpubr' was built under R version 4.1.3

``` r
library(tidyr)
library(stringr)
```

``` r
airline_flights <- read.csv("Clean_Dataset.csv")
```

``` r
summary(airline_flights$price)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##    1105    4783    7425   20890   42521  123071

Does price vary with Airlines?

``` r
df_airline_mean <- airline_flights %>% 
  group_by(airline) %>% 
  summarise_at(vars(price), list(airline_mean = mean))
```

``` r
ggplot(df_airline_mean, aes(x = airline , y = airline_mean, fill = airline)) +
  geom_col() + scale_fill_manual(
    values = c(
      "Air_India" = "#FE9901",
      "AirAsia" = "#E32526",
      "GO_FIRST" = "#094a9a", 
      "Indigo" = "#001B94",
      "SpiceJet" = "#FAD903",
      "Vistara" = "#47143D")) +
    labs(title = "Mean Price per Airline",
         x = NULL,
         y = "Mean Price in Rupee",
         caption = "(based on data from https://www.kaggle.com/shubhambathwal/flight-price-prediction)" ) +
    scale_y_continuous(breaks = seq(1000, 31000, by = 1500),
                       minor_breaks = NULL) +
    theme(plot.title = element_text(face = "bold"))
```

![](r_markdown_flight_airline_v2_files/figure-gfm/Mean%20per%20Airline%20Graph-1.png)<!-- -->

How is the price affected when tickets are bought in just 1 or 2 days
before departure?

``` r
df_bookings_total <- airline_flights %>%
  filter(airline_flights$days_left %in% 1:50) %>% 
  group_by(days_left) %>% 
  summarise(mean=mean(price))
```

``` r
total_graph <- ggplot(df_bookings_total) + 
  geom_point(aes(x = days_left, y = mean)) +
  labs(title = "Mean Price vs Days Left Before Departure",
       x = "Days left before Departure",
       y = "Mean Price in Rupee")

total_graph
```

![](r_markdown_flight_airline_v2_files/figure-gfm/Graph:%20Total%20mean%20of%20price%20of%20days_left%20both%20business%20and%20economy-1.png)<!-- -->

``` r
hist(airline_flights$days_left)
```

![](r_markdown_flight_airline_v2_files/figure-gfm/Graph:%20Count%20days_left-1.png)<!-- -->

The plane is trying to get more people to fill up the seats in the last
day before departure.

``` r
df_bookings_business <- airline_flights %>%
  filter(airline_flights$days_left %in% 1:50 & 
           #airline_flights$airline == "Vistara" & 
           airline_flights$class == "Business") %>% 
  group_by(days_left) %>% 
  summarise(mean=mean(price))
```

``` r
business_graph <- ggplot(df_bookings_business) + geom_point(aes(x = days_left, y = mean)) +
  labs(title = "Business Class",
       x = "Days Left Before Departure",
       y = "Mean Price in Rupee")
business_graph
```

![](r_markdown_flight_airline_v2_files/figure-gfm/Graph:%20Total%20business%20class-1.png)<!-- -->

``` r
df_bookings_economy <- airline_flights %>%
  filter(airline_flights$days_left %in% 1:50 & 
           airline_flights$class == "Economy") %>% 
  group_by(days_left) %>% 
  summarise(mean=mean(price))
```

``` r
economy_graph <- ggplot(df_bookings_economy) + geom_point(aes(x = days_left, y = mean)) + 
  labs(title = "Economy Seats",
       x = "Days Left before Departure",
       y = "Mean Price in Rupee")
economy_graph
```

![](r_markdown_flight_airline_v2_files/figure-gfm/Graph:%20Total%20economy%20seats-1.png)<!-- -->

``` r
figure <- ggarrange(total_graph,
                    ggarrange(business_graph, economy_graph, ncol = 2,
                    labels = c("B", "C")),
                    nrow = 2,
                    labels = "A")

figure
```

![](r_markdown_flight_airline_v2_files/figure-gfm/Graph:%20Combine%20Busines%20and%20Economy%20graphs-1.png)<!-- -->

Why is the price so low on the last day before departure compared to the
2nd to last day before departure?

GO_FIRST, AirAsia, SpiceJet only have Economy class compared to Business
class
