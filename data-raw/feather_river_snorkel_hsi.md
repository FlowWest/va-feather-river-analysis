Feather River - HSI exploration
================
Maddee Rubenson (FlowWest)
2024-03-07

### Questions/Notes

- explanation for high fish counts, how are these counted?
- habitat types are not mutually exclusive, does it make sense to assign
  weights to types?
- unique hsi developed for high and low flow channels?
- is there more data? froroville (1999-2003) - FR S and S Oroville.MDB
  (ashley slacked to me)

### TODO:

- look into how CVPIA habitat docs defined the substrate HSI
  <https://s3-us-west-2.amazonaws.com/cvpiahabitat-r-package/cvpia-sit-model-inputs/Feather_FERC_IFIM_Phase_2.pdf>
- continue lit review of HSI methods

### Limitations:

- DWR HSC does not include Cover and is outdated
  <https://s3-us-west-2.amazonaws.com/cvpiahabitat-r-package/cvpia-sit-model-inputs/Feather_FERC_IFIM_Phase_2.pdf>

``` r
# https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/qc-markdowns/seine-snorkel-data/feather-river/feather_snorkel_qc.Rmd
cleaner_snorkel_data <- readRDS('cleaner_snorkel_data.RDS') |> 
  rename(fish_count = count) |> 
  filter(!is.na(fish_count) & !is.na(instream_cover)) |> 
  mutate(section_name = case_when(section_name == "Eye" ~ "Eye Riffle",
                                  section_name == "Vance West" ~ "Vance Riffle",
                                  section_name %in% c("Hatchery Side Ditch") ~ "Hatchery Ditch",
                                  section_name == "Hatchery Side Channel" ~ "Hatchery Riffle", # TODO: check this one
                                  section_name == "Gridley Side Channel" ~ "Gridley Riffle", # TODO: check this one
                                  section_name %in% c("Robinson", "Lower Robinson") ~ "Robinson Riffle",
                                  section_name == "Goose" ~ "Goose Riffle", 
                                  section_name == "Auditorium" ~ "Auditorium Riffle",
                                  section_name %in% c("Matthews", "Mathews", "Mathews Riffle") ~ "Matthews Riffle",
                                  section_name %in% c("G95 Side Channel", "G95 West Side Channel", "G95 Side West", "G95 Side") ~ "G95", 
                                  section_name %in% c("Vance West Riffle", "Vance W Riffle", "Vance East") ~ "Vance Riffle",
                                  section_name == "Moes" ~ "Mo's Ditch",
                                  section_name == "Aleck" ~ "Aleck Riffle",
                                  section_name == "Lower Mcfarland" ~ "McFarland",
                                  section_name %in% c("Bed Rock Riffle", "Bedrock", "Bedrock Park") ~ "Bedrock Park Riffle",
                                  section_name == "Steep" ~ "Steep Riffle",
                                  section_name %in% c("Keister", "Keister Riffle") ~ "Kiester Riffle",
                                  section_name == "Junkyard" ~ "Junkyard Riffle",
                                  section_name == "Gateway" ~ "Gateway Riffle",
                                  section_name == "Trailer Park" ~ "Trailer Park Riffle",
                                  section_name %in% c("Hatchery Ditch And Moes", "Hatchery Ditch Moes Ditch", 
                                                      "Hatchery Side Channel Moes Ditch", 
                                                      "Hatchery Ditch And Moes Ditch", 
                                                      "Hatchery Side Channel And Moes Ditch", 
                                                      "Hatchery Ditch Moes") ~ "Hatchery Ditch and Mo's Ditch", # TODO: check this one since they are separate in the map
                                  section_name %in% c("Hatchery And Moes Side Channels", "Hatchery Side Ch Moes Side Ch", 
                                                      "Hatchery Side Channel And Moes") ~ "Hatchery and Mo's Riffles", # TODO: check on this one 
                                  .default = as.character(section_name))) |> 
  glimpse()
```

    ## Rows: 1,999
    ## Columns: 27
    ## $ survey_id            <chr> "46", "48", "318", "318", "318", "318", "318", "3…
    ## $ date                 <date> 2010-08-11, 2010-08-17, 2018-03-19, 2018-03-19, …
    ## $ flow                 <dbl> 620, 620, 800, 800, 800, 800, 800, 800, 800, 800,…
    ## $ weather_code         <chr> "sunny", "sunny", "clear", "clear", "clear", "cle…
    ## $ turbidity            <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
    ## $ temperature          <dbl> 64.8, 65.2, 46.4, 46.4, 46.4, 46.4, 46.4, 46.4, 4…
    ## $ time_of_temperature  <time>       NA,       NA, 13:00:00, 13:00:00, 13:00:00…
    ## $ start_time           <time> 10:30:00, 11:00:00, 12:50:00, 12:50:00, 12:50:00…
    ## $ end_time             <time>       NA, 14:00:00, 14:24:00, 14:24:00, 14:24:00…
    ## $ section_name         <chr> NA, NA, "Hatchery Riffle", "Hatchery Riffle", "Ha…
    ## $ units_covered        <chr> NA, NA, "33 26", "33 26", "33 26", "33 26", "33 2…
    ## $ survey_comments      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    ## $ observation_id       <chr> "1068", "1091", "6420", "6421", "6422", "6423", "…
    ## $ unit                 <chr> "104", "185", "33", "33", "33", "33", "33", "33",…
    ## $ fish_count           <dbl> 6, 1, 50, 50, 25, 50, 5, 10, 10, 40, 10, 1, 8, 5,…
    ## $ size_class           <chr> "VI", "VI", NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    ## $ est_size             <dbl> 900, 600, 35, 40, 50, 45, 35, 40, 45, 50, 60, 70,…
    ## $ substrate            <chr> "5", "5", "13", "13", "13", "13", "23", "23", "23…
    ## $ instream_cover       <chr> "A", "A", "BDEF", "BDEF", "BDEF", "BDEF", "FE", "…
    ## $ overhead_cover       <chr> "0", "0", "0", "0", "0", "0", "1", "1", "1", "1",…
    ## $ hydrology_code       <chr> "Riffle", "Glide", "Glide Edgewater", "Glide Edge…
    ## $ water_depth_m        <dbl> 1.0, 0.5, 0.4, 0.4, 0.4, 0.4, 0.3, 0.4, 0.4, 0.4,…
    ## $ lwd_number           <chr> NA, NA, "0", "0", "0", "0", "0", "0", "0", "0", "…
    ## $ observation_comments <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    ## $ run                  <chr> "unknown", "unknown", "unknown", "unknown", "unkn…
    ## $ tagged               <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
    ## $ clipped              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …

``` r
high_flows <- c('Vance Riffle', 'G95', 'Kiester Riffle', 'Goose Riffle', 'Big Riffle', 'McFarland', 'Gridley Riffle', 'Junkyard Riffle')
low_flows <- cleaner_snorkel_data |> filter(!(section_name %in% high_flows)) |> filter(!is.na(section_name)) |> pull(section_name) |> unique()

high_flows
```

    ## [1] "Vance Riffle"    "G95"             "Kiester Riffle"  "Goose Riffle"   
    ## [5] "Big Riffle"      "McFarland"       "Gridley Riffle"  "Junkyard Riffle"

``` r
low_flows
```

    ##  [1] "Hatchery Riffle"               "Mo's Ditch"                   
    ##  [3] "Bedrock Riffle"                "Trailer Park Riffle"          
    ##  [5] "Aleck Riffle"                  "Steep Riffle"                 
    ##  [7] "Eye Riffle"                    "Bedrock Park Riffle"          
    ##  [9] "Gateway Riffle"                "Hatchery Ditch"               
    ## [11] "Matthews Riffle"               "Robinson Riffle"              
    ## [13] "Hatchery and Mo's Riffles"     "Auditorium Riffle"            
    ## [15] "Hatchery Ditch and Mo's Ditch"

``` r
cleaner_snorkel_data <- cleaner_snorkel_data |> 
  mutate(channel_flow_type = ifelse(section_name %in% high_flows, "high flow channel", "low flow channel"))
```

``` r
snorkel_data_dev <- cleaner_snorkel_data |> 
  select(section_name, date, fish_count, substrate, instream_cover, overhead_cover, size_class, est_size) |> 
  mutate(substrate_unique = strsplit(substrate, ""),
         instream_cover_unique = strsplit(instream_cover, ""),
         overhead_cover_unique = strsplit(overhead_cover, "")) |> 
  unnest(substrate_unique) |> 
  unnest(instream_cover_unique) |> 
  unnest(overhead_cover_unique) 
```

### Variable: `substrate`

| SubstrateCode | Substrate                    | Proposed Weight |
|---------------|------------------------------|-----------------|
| 1             | Organic Fines, Mud (0.05 mm) | 1               |
| 2             | Sand (0.05 to 2 mm)          | 1               |
| 3             | Small Gravel (2 to 50 mm)    | 2               |
| 4             | Large Gravel (50 to 150 mm)  | 5               |
| 5             | Cobble (150 to 300 mm)       | 5               |
| 6             | Boulder (\> 300 mm)          | 2               |
| 0             | ?                            | 0               |

### Variable: `instream_cover`

| CoverCode | Cover                                            | Proposed Weight |
|-----------|--------------------------------------------------|-----------------|
| A         | No apparent cover                                | 0               |
| B         | Small instream objects/small-medium woody debris | 2               |
| C         | Large instream objects/large woody debris        | 4               |
| D         | Overhead objects                                 | 4               |
| E         | Submerged aquatic veg/filamentous algae          | 0               |
| F         | Undercut bank                                    | 0               |

### Variable: `overhead_cover`

| CoverCode | Cover                                         | Proposed Weight |
|-----------|-----------------------------------------------|-----------------|
| 0         | No Apparent Cover                             | 0               |
| 1         | Overhanging veg/obj (\< 0.5 m above surface)  | 2               |
| 2         | Overhanging veg/obj (0.5 to 2 m above surface | 4               |
| 3         | Surface turbulence, bubble curtain            | 2               |

### Data Exploration

#### fish count by habitat types

``` r
snorkel_data_dev |> 
  ggplot() +
  geom_jitter(aes(y = fish_count, x = substrate_unique))
```

![](feather_river_snorkel_hsi_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

``` r
snorkel_data_dev |> 
  ggplot() +
  geom_jitter(aes(y = fish_count, x = instream_cover_unique))
```

![](feather_river_snorkel_hsi_files/figure-gfm/unnamed-chunk-3-2.png)<!-- -->

``` r
snorkel_data_dev |> 
  ggplot() +
  geom_jitter(aes(y = fish_count, x = overhead_cover_unique))
```

![](feather_river_snorkel_hsi_files/figure-gfm/unnamed-chunk-3-3.png)<!-- -->

#### Data Completeness

Summarizes how complete the fish count data is by `year`, `section` and
`flow type`.

``` r
# by year
cleaner_snorkel_data |> 
  mutate(year = year(date)) |>
  group_by(year) |> 
  summarise(total_fish_obs = length(fish_count))|> 
  knitr::kable(col.names = c('year', 'total fish observations'))
```

| year | total fish observations |
|-----:|------------------------:|
| 2010 |                      27 |
| 2011 |                     199 |
| 2012 |                     338 |
| 2013 |                      21 |
| 2015 |                      50 |
| 2016 |                     114 |
| 2017 |                       1 |
| 2018 |                     511 |
| 2019 |                     218 |
| 2020 |                     520 |

``` r
cleaner_snorkel_data |> 
  group_by(year(date)) |> 
  summarise(total_fish_obs = length(fish_count)) |> 
  rename(year = `year(date)`) |> 
  ggplot() + 
  geom_col(aes(x = as.factor(year), y = total_fish_obs)) +
  xlab("year") + ylab("total fish count observations")
```

![](feather_river_snorkel_hsi_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

``` r
# by section
cleaner_snorkel_data |> 
  group_by(section_name) |> 
  summarise(total_fish_obs = length(fish_count)) |> 
  knitr::kable(col.names = c('section name', 'total fish observations'))
```

| section name                  | total fish observations |
|:------------------------------|------------------------:|
| Aleck Riffle                  |                      51 |
| Auditorium Riffle             |                      31 |
| Bedrock Park Riffle           |                      54 |
| Bedrock Riffle                |                      35 |
| Big Riffle                    |                      21 |
| Eye Riffle                    |                     123 |
| G95                           |                      42 |
| Gateway Riffle                |                      80 |
| Goose Riffle                  |                      16 |
| Gridley Riffle                |                      18 |
| Hatchery Ditch                |                     171 |
| Hatchery Ditch and Mo’s Ditch |                      95 |
| Hatchery Riffle               |                     149 |
| Hatchery and Mo’s Riffles     |                      54 |
| Junkyard Riffle               |                      16 |
| Kiester Riffle                |                       7 |
| Matthews Riffle               |                      59 |
| McFarland                     |                       9 |
| Mo’s Ditch                    |                       9 |
| Robinson Riffle               |                     108 |
| Steep Riffle                  |                     168 |
| Trailer Park Riffle           |                      62 |
| Vance Riffle                  |                      36 |
| NA                            |                     585 |

``` r
cleaner_snorkel_data |> 
  group_by(section_name) |> 
  summarise(total_fish_obs = length(fish_count)) |> 
  ggplot() + 
  geom_col(aes(x = section_name, y = total_fish_obs)) +
  xlab("section name") + ylab("total fish count observations") + 
  coord_flip()
```

![](feather_river_snorkel_hsi_files/figure-gfm/unnamed-chunk-4-2.png)<!-- -->

``` r
# by section
cleaner_snorkel_data |> 
  group_by(channel_flow_type) |> 
  summarise(total_fish_obs = length(fish_count)) |> 
  knitr::kable(col.names = c('channel flow type', 'total fish count observations'))
```

| channel flow type | total fish count observations |
|:------------------|------------------------------:|
| high flow channel |                           165 |
| low flow channel  |                          1834 |

``` r
cleaner_snorkel_data |> 
  group_by(channel_flow_type) |> 
  summarise(total_fish_obs = length(fish_count)) |> 
  ggplot() + 
  geom_col(aes(x = channel_flow_type, y = total_fish_obs)) +
  xlab("channel flow type") + ylab("total fish count observations") + 
  coord_flip()
```

![](feather_river_snorkel_hsi_files/figure-gfm/unnamed-chunk-4-3.png)<!-- -->

#### Fish size

##### Notes

- size class is mostly `NA`s
- we do not know what the units are for `est_size` nor what it is
  describing

| Size Class | Size Range |
|------------|------------|
| I          | 0-50       |
| II         | 51-75      |
| III        | 76-100     |
| IV         | 101-150    |
| V          | 151-300    |
| VI         | 301-499    |
| VII        | 500+       |

``` r
table(cleaner_snorkel_data$size_class, useNA = "always")
```

    ## 
    ##    I   II  III   IV    V   VI  VII <NA> 
    ##  177  202  121   41   10   46   55 1347

``` r
summary(cleaner_snorkel_data$est_size)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
    ##    30.0    45.0    60.0   126.3    85.0   950.0       2

#### Large Wood

- assuming `lwd_number` stands for large wood number
- `28` NAs for large wood
- mostly `0` values with some values in the 3000 range. The most being
  `16` observations at a `lwd_number` of `3006`

``` r
table(as.numeric(cleaner_snorkel_data$lwd_number), useNA = "always")
```

    ## 
    ##    0 3001 3002 3003 3004 3005 3006 3007 3008 3010 3013 3018 3020 <NA> 
    ## 1928    2    1    7    1    1   16    6    2    4    1    1    1   28

## HSI Dev

### Mark Gard 1998 Process

1.  Determine number of redds with each substrate-size class
2.  Calculate the proportion of redds with each substrate size class
3.  Calculate the HSC value for each substrate size class by dividing
    the proportion of redds in each substrate class by the proportion of
    redds with the most frequent substrate class

#### Discussion

- This process incorporates substrate only - will need to add depth,
  velocity, and cover  
- This keeps the substrate types grouped - should we ungroup?
- Used fish counts instead of redds

``` r
hsi_dev_markgard_1998 <- cleaner_snorkel_data |> 
  group_by(substrate) |> # note this is grouped by multiple substrate types
  summarise(n_fish = sum(fish_count)) |>  # don't have a value for redds
  mutate(prop_fish_count = n_fish/sum(n_fish)) |> 
  ungroup()

most_freq <- hsi_dev_markgard_1998 |> 
  arrange(desc(n_fish)) |> 
  slice(1) 

hsi_dev_markgard_1998 <- hsi_dev_markgard_1998 |> 
  mutate(hsc = prop_fish_count/most_freq$prop_fish_count)

ggplot(hsi_dev_markgard_1998) +
  geom_col(aes(y = hsc, x = substrate)) +
  coord_flip()
```

![](feather_river_snorkel_hsi_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

``` r
knitr::knit_exit()
```
