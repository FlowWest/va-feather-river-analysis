Mini Snorkel Feather HSI Workflow
================
Maddee Rubenson
2024-04-04

``` r
# read in mini snorkel data
mini_snorkel <- read_csv('../../feather-mini-snorkel/data/microhabitat_with_fish_observations.csv') |>
  mutate(count = ifelse(is.na(count), 0, count)) |> 
  glimpse()
```

    ## Rows: 5018 Columns: 28
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr   (2): species, channel_geomorphic_unit
    ## dbl  (25): micro_hab_data_tbl_id, location_table_id, transect_code, depth, v...
    ## date  (1): date
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

    ## Rows: 5,018
    ## Columns: 28
    ## $ micro_hab_data_tbl_id                       <dbl> 18, 18, 18, 19, 20, 21, 22…
    ## $ location_table_id                           <dbl> 11, 11, 11, 11, 11, 11, 11…
    ## $ transect_code                               <dbl> 0.1, 0.1, 0.1, 0.2, 0.3, 0…
    ## $ depth                                       <dbl> 17, 17, 17, 19, 11, 12, 11…
    ## $ velocity                                    <dbl> 0.22, 0.22, 0.22, 0.35, 1.…
    ## $ percent_fine_substrate                      <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0,…
    ## $ percent_sand_substrate                      <dbl> 40, 40, 40, 50, 25, 0, 70,…
    ## $ percent_small_gravel_substrate              <dbl> 20, 20, 20, 40, 75, 80, 30…
    ## $ percent_large_gravel_substrate              <dbl> 30, 30, 30, 10, 0, 20, 0, …
    ## $ percent_cobble_substrate                    <dbl> 10, 10, 10, 0, 0, 0, 0, 0,…
    ## $ percent_boulder_substrate                   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0,…
    ## $ percent_no_cover_inchannel                  <dbl> 75, 75, 75, 100, 100, 100,…
    ## $ percent_small_woody_cover_inchannel         <dbl> 15, 15, 15, 0, 0, 0, 20, 0…
    ## $ percent_large_woody_cover_inchannel         <dbl> 0, 0, 0, 0, 0, 0, 40, 0, 0…
    ## $ percent_submerged_aquatic_veg_inchannel     <dbl> 10, 10, 10, 0, 0, 0, 30, 0…
    ## $ percent_undercut_bank                       <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0,…
    ## $ percent_no_cover_overhead                   <dbl> 100, 100, 100, 100, 100, 1…
    ## $ percent_cover_half_meter_overhead           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0,…
    ## $ percent_cover_more_than_half_meter_overhead <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0,…
    ## $ surface_turbidity                           <dbl> 20, 20, 20, 30, 30, 30, 10…
    ## $ fish_data_id                                <dbl> 21, 22, 23, NA, NA, NA, 25…
    ## $ count                                       <dbl> 2, 3, 1, 0, 0, 0, 3, 0, 0,…
    ## $ fl_mm                                       <dbl> 35, 35, 25, NA, NA, NA, 25…
    ## $ dist_to_bottom                              <dbl> 1.0, 1.5, 1.5, NA, NA, NA,…
    ## $ focal_velocity                              <dbl> 0.94, 0.16, 0.16, NA, NA, …
    ## $ species                                     <chr> "Chinook salmon", "Chinook…
    ## $ date                                        <date> 2001-03-14, 2001-03-14, 2…
    ## $ channel_geomorphic_unit                     <chr> "Glide", "Glide", "Glide",…

``` r
# mini_snorkel <- read_csv('https://raw.githubusercontent.com/FlowWest/feather-mini-snorkel/qc-data/data/microhabitat_with_fish_observations.csv?token=GHSAT0AAAAAACCSPYJRVFBZ33MHJ2WM5ZX4ZQMRB5A') |> 
#   mutate(count = ifelse(is.na(count), 0, count)) |> 
#   glimpse()
```

## Draft Workflow

[**2004a**](https://netorg629193.sharepoint.com/:b:/s/VA-FeatherRiver/EY9qLwY15ypFn3W42E02takBH745JkefSPAbS4y9VFzuBQ?e=n2QRXK)
Data Analysis

- Stepwise binary logistic regression analysis was used to assess
  factors influencing the occurrence of steelhead and Chinook salmon.
  Fine scale survey results were analyzed at both the mesohabitat (100
  m2) and microhabitat (1 m2) scale.

- Mesohabitat analysis was performed by treating the entire 25 m reach
  as a sample

- Reach habitat variables where steelhead or salmon were present
  (logistic response variable) were compared to reaches where fish were
  absent (logistic reference variable)

- Microhabitat was done similarly except that individual one square
  meter cells were considered rather than entire reaches

- Reaches lacking salmon or steelhead were not included in microhabitat
  analysis

[**2005**](https://netorg629193.sharepoint.com/:b:/s/VA-FeatherRiver/ES8H3f7ZUO5Aj7OK8hfW03UB721tCgZd_OEb8P9cbJLiMA?e=L95bf8):
HSC development- chinook salmon rearing

- HSC were created for fry (\<50 mm) and juvenile Chinook salmon depth
  and mean column velocity data using a three-point running mean to
  smooth frequency distributions of the fry habitat use data and using
  NPTL \[what does this stand for?\] for the juvenile habitat use data.

- all substrate suitability given value of 1 after finding that
  substrate was not driving factor for microhabitat selection of fry and
  juveniles

- cover modified to: with and without. Suitability of without cover was
  calculated as the percentage of fish observed without cover to the
  total sample size

- suitability of cover present was assigned a value of 1.0 and 0.30 or
  0.22 for cover absent for Chinook salon fry and juveniles \[I do not
  get this… \]

- Focus on suitability of instream cover. When a cover variable did not
  exist, preference for low velocity and shallow depth in a large river
  indicate suitable habitat along stream margins or out in the main
  channel when the river is nearly dry and the preferred conditions are
  prevalent.

- intermediate scale data separated into four cover types: no cover,
  object only cover overhead only cover, both object and overhead cover

[**Gard
2023**](https://netorg629193.sharepoint.com/:b:/s/VA-FeatherRiver/EelfImRfhzxKjLQdrstbIPgBqbRV5S0Wke5GkSh06_CUrQ?e=6PdWKh) -
HSC comparison

- Presence/absence HSC are developed using a polynomial logistic
  regression that uses both the occupied and unoccupied data; the
  results are then rescaled that the highest value is 1 to calculate the
  HSI

- For depth and velocity HSC, the criteria were developed directly from
  use observations using a range of curve fitting and smoothing
  techniques

- Use/availability criteria are developed by dividing use observations,
  generally binned, by availability data from transects

``` r
mini_snorkel_model_ready <- mini_snorkel |> 
  select(depth:percent_cover_more_than_half_meter_overhead, count, channel_geomorphic_unit, species) |> 
  mutate(fish_presence = as.factor(ifelse(count < 1, "0", "1")))
```

# Chinook Salmon

### Explore Variables

Specifically looking for collinearity in the variables

``` r
chn_mini_snorkel_substrate <- mini_snorkel_model_ready |> 
  filter(species == "Chinook salmon" | is.na(species)) |> 
  select(fish_presence, percent_fine_substrate:percent_boulder_substrate) 

cor_matrix <- cor(chn_mini_snorkel_substrate |> select(-fish_presence))

print(cor_matrix)
```

    ##                                percent_fine_substrate percent_sand_substrate
    ## percent_fine_substrate                     1.00000000            -0.04435118
    ## percent_sand_substrate                    -0.04435118             1.00000000
    ## percent_small_gravel_substrate            -0.17186508            -0.30474352
    ## percent_large_gravel_substrate            -0.18275391            -0.43339353
    ## percent_cobble_substrate                  -0.10849584            -0.26288062
    ## percent_boulder_substrate                 -0.05829675            -0.12077048
    ##                                percent_small_gravel_substrate
    ## percent_fine_substrate                             -0.1718651
    ## percent_sand_substrate                             -0.3047435
    ## percent_small_gravel_substrate                      1.0000000
    ## percent_large_gravel_substrate                     -0.3351311
    ## percent_cobble_substrate                           -0.3955015
    ## percent_boulder_substrate                          -0.2279385
    ##                                percent_large_gravel_substrate
    ## percent_fine_substrate                            -0.18275391
    ## percent_sand_substrate                            -0.43339353
    ## percent_small_gravel_substrate                    -0.33513107
    ## percent_large_gravel_substrate                     1.00000000
    ## percent_cobble_substrate                          -0.04373516
    ## percent_boulder_substrate                         -0.12013439
    ##                                percent_cobble_substrate
    ## percent_fine_substrate                      -0.10849584
    ## percent_sand_substrate                      -0.26288062
    ## percent_small_gravel_substrate              -0.39550146
    ## percent_large_gravel_substrate              -0.04373516
    ## percent_cobble_substrate                     1.00000000
    ## percent_boulder_substrate                    0.20302349
    ##                                percent_boulder_substrate
    ## percent_fine_substrate                       -0.05829675
    ## percent_sand_substrate                       -0.12077048
    ## percent_small_gravel_substrate               -0.22793850
    ## percent_large_gravel_substrate               -0.12013439
    ## percent_cobble_substrate                      0.20302349
    ## percent_boulder_substrate                     1.00000000

``` r
heatmap(cor_matrix, 
        col = colorRampPalette(c("blue", "white", "red"))(20),
        symm = TRUE,
        margins = c(10, 10))
```

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

### Logistic Regression

Build a logistic regression of fish presence and absence to identify
important cover and substrate variables.

**Findings**

- Substrate: most important predictor is small gravel
- Cover: all predictors (aside from the two NAs and
  `percent_cover_half_meter_overhead`) were significant.
  `percent_no_cover_overhead` was most significant.

**Questions**

- Substrate: boulder came out as NA in model. Should explore why this
  occurred.
- Cover: `percent_undercut_bank` and
  `percent_cover_more_than_half_meter_overhead` came back as NA. Need to
  explore.

#### Substrate Logistic Regression

``` r
set.seed(06221988)

# start with Chinook and substrate 
chn_mini_snorkel <- mini_snorkel_model_ready |> 
  filter(species == "Chinook salmon" | is.na(species)) |> 
  select(fish_presence, percent_fine_substrate:percent_boulder_substrate) 

# Define a recipe
rec <- recipe(fish_presence ~  percent_fine_substrate + percent_sand_substrate + percent_small_gravel_substrate + percent_large_gravel_substrate + percent_boulder_substrate + percent_cobble_substrate, data = chn_mini_snorkel)  

# Split the data into training and testing sets
data_split <- initial_split(chn_mini_snorkel, prop = 0.8, strata = "fish_presence")
data_train <- training(data_split)
data_test <- testing(data_split)

# Create a logistic regression model
log_reg <- logistic_reg() |> 
  set_engine("glm") |> 
  set_mode("classification") |> translate()

# Create a workflow
wf <- workflow()  |> 
  add_recipe(rec) |> 
  add_model(log_reg)

# Train the model
wf_fit <- wf |> 
  fit(data_train)

tidy(wf_fit) # why is boulder NA? small gravel only significant predictor
```

    ## # A tibble: 7 × 5
    ##   term                             estimate std.error statistic   p.value
    ##   <chr>                               <dbl>     <dbl>     <dbl>     <dbl>
    ## 1 (Intercept)                    -3.39        0.390    -8.68     3.98e-18
    ## 2 percent_fine_substrate          0.0116      0.00543   2.13     3.29e- 2
    ## 3 percent_sand_substrate          0.0141      0.00428   3.29     1.01e- 3
    ## 4 percent_small_gravel_substrate -0.00593     0.00464  -1.28     2.01e- 1
    ## 5 percent_large_gravel_substrate  0.0000212   0.00526   0.00404  9.97e- 1
    ## 6 percent_boulder_substrate       0.00722     0.00864   0.836    4.03e- 1
    ## 7 percent_cobble_substrate       NA          NA        NA       NA

``` r
glance(wf_fit)
```

    ## # A tibble: 1 × 8
    ##   null.deviance df.null logLik   AIC   BIC deviance df.residual  nobs
    ##           <dbl>   <int>  <dbl> <dbl> <dbl>    <dbl>       <int> <int>
    ## 1         1345.    3871  -643. 1299. 1336.    1287.        3866  3872

``` r
# Make predictions
predictions <- predict(wf_fit, data_test) |>
  bind_cols(data_test)
```

    ## Warning in predict.lm(object, newdata, se.fit, scale = 1, type = if (type == :
    ## prediction from a rank-deficient fit may be misleading

#### Cover Logistic Regression

``` r
# start with Chinook and substrate 
chn_mini_snorkel <- mini_snorkel_model_ready |> 
  filter(species == "Chinook salmon" | is.na(species)) |> 
  select(fish_presence, percent_no_cover_inchannel:percent_cover_more_than_half_meter_overhead) |> 
  na.omit() 

# Define a recipe
rec <- recipe(fish_presence ~  percent_no_cover_inchannel + percent_small_woody_cover_inchannel + percent_large_woody_cover_inchannel + percent_submerged_aquatic_veg_inchannel + percent_undercut_bank + percent_no_cover_overhead + percent_cover_half_meter_overhead + percent_cover_more_than_half_meter_overhead, data = chn_mini_snorkel)  

# Split the data into training and testing sets
data_split <- initial_split(chn_mini_snorkel, prop = 0.8, strata = "fish_presence")
data_train <- training(data_split)
data_test <- testing(data_split)

# Create a logistic regression model
log_reg <- logistic_reg() |> 
  set_engine("glm") |> 
  set_mode("classification") |> translate()

# Create a workflow
wf <- workflow()  |> 
  add_recipe(rec) |> 
  add_model(log_reg)

# Train the model
wf_fit <- wf |> 
  fit(data_train)

tidy(wf_fit) # 
```

    ## # A tibble: 9 × 5
    ##   term                                     estimate std.error statistic  p.value
    ##   <chr>                                       <dbl>     <dbl>     <dbl>    <dbl>
    ## 1 (Intercept)                               5.50      1.83         3.00  2.66e-3
    ## 2 percent_no_cover_inchannel               -0.0732    0.0185      -3.95  7.70e-5
    ## 3 percent_small_woody_cover_inchannel      -0.0474    0.0187      -2.54  1.11e-2
    ## 4 percent_large_woody_cover_inchannel      -0.0565    0.0236      -2.39  1.69e-2
    ## 5 percent_submerged_aquatic_veg_inchannel  -0.0815    0.0190      -4.30  1.69e-5
    ## 6 percent_undercut_bank                    NA        NA           NA    NA      
    ## 7 percent_no_cover_overhead                -0.0156    0.00306     -5.08  3.68e-7
    ## 8 percent_cover_half_meter_overhead        -0.00849   0.00580     -1.46  1.43e-1
    ## 9 percent_cover_more_than_half_meter_over… NA        NA           NA    NA

``` r
# Make predictions
# predictions <- predict(wf_fit, data_test) |>
#   bind_cols(data_test)
```

### Adapted Mark Gard 1998 HSC process to Cover and Substrate

Mark Gard’s 1998 paper identified a method to developing HSC for
presence and absence of redds in different substrate classes. I will
follow the same methodology using fish presence/absence and total fish
count instead of redds and also apply to cover.

1.  Determine number of fish with each substrate-size class
2.  Calculate the proportion of fish with each substrate size class
3.  Calculate the HSC value for each substrate size class by dividing
    the proportion of fish in each substrate class by the proportion of
    fish with the most frequent substrate class

To convert from percent to discrete:

- Cover decision: 20% or greater is considered present

- Substrate decision: used same criteria as cover (for now)

**Discussion**

Substrate: - Sand has a stronger HSI when looking at number of fish vs.
presence/absence

- Presence/absence results are consistent with logistic regression

Cover: - More consistent results when looking at number of fish
vs. presence/absence

``` r
mark_gard_1998_hsi <- function(data, percent_presence = 20, cols = c()) {
  data_tidy <- data |> 
    select(count, fish_presence, cols) |> 
    pivot_longer(cols = cols, names_to = "type", values_to = "percent") |> 
    mutate(presence = ifelse(percent >= percent_presence, 1, 0)) |> 
    filter(presence == 1) |> 
    group_by(type) |>
    summarise(n_fish_presence = sum(as.numeric(fish_presence)),
              n_fish_total = sum(count)) |> 
    mutate(prop_fish_presence = n_fish_presence/sum(n_fish_presence),
           prop_fish_total = n_fish_total/sum(n_fish_total)) |> 
    ungroup()
  
     most_freq_total <- data_tidy |> 
      arrange(desc(prop_fish_total)) |> 
      slice(1) 
 
     most_freq_presence <- data_tidy |> 
      arrange(desc(prop_fish_presence)) |> 
      slice(1) 
  
  
  data_tidy_final <- data_tidy |> 
    mutate(hsc_presence = prop_fish_presence/most_freq_presence$prop_fish_presence,
           hsc_total = prop_fish_total/most_freq_total$prop_fish_total)
  
  return(data_tidy_final)

}
```

#### Substrate

``` r
cols <- c('percent_fine_substrate', "percent_sand_substrate" , 'percent_small_gravel_substrate', 'percent_large_gravel_substrate', 'percent_cobble_substrate', 'percent_boulder_substrate')

hsi_substrate <- mark_gard_1998_hsi(data = mini_snorkel_model_ready, percent_presence = 20, cols = cols)
```

    ## Warning: Using an external vector in selections was deprecated in tidyselect 1.1.0.
    ## ℹ Please use `all_of()` or `any_of()` instead.
    ##   # Was:
    ##   data %>% select(cols)
    ## 
    ##   # Now:
    ##   data %>% select(all_of(cols))
    ## 
    ## See <https://tidyselect.r-lib.org/reference/faq-external-vector.html>.
    ## This warning is displayed once every 8 hours.
    ## Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
    ## generated.

``` r
hsi_substrate |> 
  pivot_longer(cols = c(hsc_presence, hsc_total), names_to = "hsc", values_to = "values") |> 
  ggplot() + 
  geom_col(aes(y = values, x = type, fill = hsc), position = "dodge") +
  coord_flip() +
  ggtitle('Mark Gard 1998: Substrate HSI Comparison')
```

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

#### Cover

TODO: treat instream and overhanging as different cover types TODO:
explore no cover more - do we want to use this? how? need to change
percentage

Need a summary of the habitat conditions that were surveyed

``` r
cols <- c('percent_no_cover_inchannel', 'percent_small_woody_cover_inchannel', 'percent_large_woody_cover_inchannel', 
          'percent_submerged_aquatic_veg_inchannel', 'percent_undercut_bank', 'percent_no_cover_overhead', 'percent_cover_half_meter_overhead',
          'percent_cover_more_than_half_meter_overhead')

hsi_cover <- mark_gard_1998_hsi(data = mini_snorkel_model_ready, percent_presence = 20, cols = cols)

hsi_cover |> 
  pivot_longer(cols = c(hsc_presence, hsc_total), names_to = "hsc", values_to = "values") |> 
  ggplot() + 
  geom_col(aes(y = values, x = type, fill = hsc), position = "dodge") +
  coord_flip() +
  ggtitle('Mark Gard 1998: Cover HSI Comparison')
```

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->

## Velocity and Depth

``` r
ggplot(mini_snorkel_model_ready) + 
  geom_point(aes(x = count, y = velocity)) 
```

    ## Warning: Removed 80 rows containing missing values (`geom_point()`).

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

``` r
ggplot(mini_snorkel_model_ready) + 
  geom_boxplot(aes(x = fish_presence, y = velocity)) 
```

    ## Warning: Removed 80 rows containing non-finite values (`stat_boxplot()`).

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-9-2.png)<!-- -->

``` r
ggplot(mini_snorkel_model_ready) + 
  geom_point(aes(x = count, y = depth)) 
```

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-9-3.png)<!-- -->

``` r
ggplot(mini_snorkel_model_ready) + 
  geom_boxplot(aes(x = fish_presence, y = depth)) 
```

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-9-4.png)<!-- -->
\### Adapted Mark Gard 2023 HSC approach for Velocity and Depth

#### Approach 1: Criteria from use observations using curve fitting

``` r
lm_data <- mini_snorkel_model_ready |> 
  select(count, depth, velocity) |> 
  na.omit()

fit <- lm(count ~ poly(depth, 3) + poly(velocity, 3) , data = lm_data)
hsi_values <- predict(fit, type = "response")
lm_data$hsi_values <- hsi_values

tidy(fit)
```

    ## # A tibble: 7 × 5
    ##   term               estimate std.error statistic  p.value
    ##   <chr>                 <dbl>     <dbl>     <dbl>    <dbl>
    ## 1 (Intercept)           3.90      0.633    6.16   7.97e-10
    ## 2 poly(depth, 3)1     205.       46.0      4.46   8.20e- 6
    ## 3 poly(depth, 3)2      57.3      44.9      1.27   2.03e- 1
    ## 4 poly(depth, 3)3     106.       44.6      2.38   1.75e- 2
    ## 5 poly(velocity, 3)1 -122.       45.9     -2.66   7.82e- 3
    ## 6 poly(velocity, 3)2   -0.741    44.7     -0.0166 9.87e- 1
    ## 7 poly(velocity, 3)3   37.3      44.9      0.830  4.07e- 1

``` r
lm_data %>%
  ggplot(aes(x = depth, y = count)) +
  geom_point() +
  geom_smooth(aes(x = depth, y = hsi_values), method = "lm", color = "blue") +
  labs(x = "Depth", y = "Fish Count") +
  theme_minimal()
```

    ## `geom_smooth()` using formula = 'y ~ x'

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-10-1.png)<!-- -->

``` r
lm_data %>%
  ggplot(aes(x = velocity, y = count)) +
  geom_point() +
  geom_smooth(aes(x = velocity, y = hsi_values), method = "lm", color = "blue") +
  labs(x = "Velocity", y = "Fish Count") +
  theme_minimal()
```

    ## `geom_smooth()` using formula = 'y ~ x'

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-10-2.png)<!-- -->

#### Approach 2: Use/Availability criteria from binned data

Use/availability criteria are developed by dividing use observations,
generally binned, by availability data from transects.

``` r
approach_2 <- mini_snorkel_model_ready |> 
  select(count, fish_presence, depth, velocity) |> 
  na.omit()
```

#### Approach 3: Presence/absence HSC using logistic regression

``` r
log_reg_data <- mini_snorkel_model_ready |> 
  select(fish_presence, depth, velocity) |> 
  na.omit()

# Fit polynomial logistic regression model
model <- glm(fish_presence ~ poly(depth, 2) + poly(velocity, 2), data = log_reg_data, family = binomial)

tidy(model)
```

    ## # A tibble: 5 × 5
    ##   term               estimate std.error statistic p.value
    ##   <chr>                 <dbl>     <dbl>     <dbl>   <dbl>
    ## 1 (Intercept)           -2.53    0.0547   -46.2   0      
    ## 2 poly(depth, 2)1       -1.28    3.72      -0.343 0.731  
    ## 3 poly(depth, 2)2        8.03    2.77       2.90  0.00376
    ## 4 poly(velocity, 2)1    -5.15    4.51      -1.14  0.253  
    ## 5 poly(velocity, 2)2    -6.46    5.18      -1.25  0.212

``` r
# Calculate HSI values
hsi_values <- predict(model, type = "response")
log_reg_data$hsi_values <- hsi_values

ggplot(log_reg_data) + 
  geom_point(aes(x = depth, y = hsi_values)) + 
  geom_smooth(aes(x = depth, y = hsi_values), method = "loess", color = "blue") 
```

    ## `geom_smooth()` using formula = 'y ~ x'

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-12-1.png)<!-- -->

``` r
ggplot(log_reg_data) + 
  geom_point(aes(x = velocity, y = hsi_values)) + 
  geom_smooth(aes(x = velocity, y = hsi_values), method = "loess", color = "blue") 
```

    ## `geom_smooth()` using formula = 'y ~ x'

![](feather_river_mini_snorkel_hsi_workflow_files/figure-gfm/unnamed-chunk-12-2.png)<!-- -->

``` r
knitr::knit_exit()
```
