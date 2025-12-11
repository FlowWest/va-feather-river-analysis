---
editor_options: 
  markdown: 
    wrap: 72
---

# Mini Snorkel Feather Presence/Absence Model

Maddee Rubenson 2024-11-12

-   [Objective](#objective)
-   [Methodology](#methodology)
    -   [Hurdle Models and
        Interpretation](#hurdle-models-and-interpretation)
-   [Build Models](#build-models)
    -   [Read in data](#read-in-data)
    -   [Review Data](#review-data)
    -   [High Flow vs. Low Flow Channel](#high-flow-vs-low-flow-channel)
-   [Model 1 - Binary Cover Values](#model-1---binary-cover-values)
    -   [Model 1 Results](#model-1-results)
-   [Splitting out High Flow and Low Flow into Separate
    Models](#splitting-out-high-flow-and-low-flow-into-separate-models)
    -   [High Flow Model](#high-flow-model)
    -   [Low Flow Channel](#low-flow-channel)

## Objective {#objective}

Develop a model that reflects the significance of cover, substrate,
depth, and velocity on fish presence and absence.

## Methodology {#methodology}

Model was developed using [Feather River Mini Snorkel
Data](https://github.com/FlowWest/feather-mini-snorkel). The data is
structured with a numeric fish count variable that can be converted to a
binary presence/absence. Logistic regression models were tested using
the presence/absence as the response and cover, substrate, depth and
velocity as the explanatory variables. However, due to the skewness of
absence values, none of the developed models were well fit to the data.
Based on a Gard 2024 paper (in-review), we decided to explore the use of
hurdle models. Hurdle models excel with data types that are heavily
skewed towards absence.

### Hurdle Models and Interpretation {#hurdle-models-and-interpretation}

A hurdle model was used in Gard 2024 (in-review) to test for the effects
of cover and habitat type on the total abundance of Chinook salmon at
both site and cell level. Here we use the hurdle model to help
understand the influence of velocity, depth, and cover on fish count and
presence/absence.

**Hurdle Models**

Hurdle models are used when count data has an excess of zeros. These
models can be understood as a mixture of two subset of populations. In
one subset, we have a usual count model that may or may not generate
zero, and the other subset only produce zero count.

A hurdle model models excess zeroes separately from the rest of the
data. The zero counts are modeled as a binary response variable and the
positive counts are modeled using poisson distribution.

*Interpreting a Hurdle Model*

The binary part of the model helps identify factors that influence the
presence/absence of fish. The coefficients of the zero part of the
hurdle model represent the odds ratio of observing at least one fish.

The count part of the model estimate the effects of predictor variables
on the count outcome, excluding all zero counts. Coefficients of counts
represent rate ratios of one or more fish observed.

The Incidence Result Ratio (IRR) in the count part of the model (count
\> 0) represent the multiplicative effect of a one-unit change in a
predictor variable on the expected count of non-zero observations,
assuming all other variables are held constant. For example, if the IRR
for a predictor is 1.2, it means that a one-unit increase in that
predictor is associated with a 20% increase in the expected count of
non-zero observations, assuming all other variables remain constant. For
the binary part of the model - if the coefficient for a predictor in the
binary part of the hurdle model is 0.5, it means that a one-unit
increase in the predictor is associated with a 50% increase in the odds
of having a zero count versus a positive count, assuming all other
variables are held constant.

## Build Models {#build-models}

### Read in data {#read-in-data}

```         
## Rows: 17,882
## Columns: 44
## $ micro_hab_data_tbl_id                       <dbl> 18, 18, 18, 19, 20, 21, 22…
## $ location_table_id                           <dbl> 11, 11, 11, 11, 11, 11, 11…
## $ transect_code                               <dbl> 0.1, 0.1, 0.1, 0.2, 0.3, 0…
## $ fish_data_id                                <dbl> 21, 22, 23, NA, NA, NA, 25…
## $ date                                        <date> 2001-03-14, 2001-03-14, 2…
## $ count                                       <dbl> 2, 3, 1, 0, 0, 0, 3, 0, 0,…
## $ species                                     <chr> "chinook salmon", "chinook…
## $ fl_mm                                       <dbl> 35, 35, 25, NA, NA, NA, 25…
## $ dist_to_bottom                              <dbl> 1.0, 1.5, 1.5, NA, NA, NA,…
## $ depth                                       <dbl> 17, 17, 17, 19, 11, 12, 11…
## $ focal_velocity                              <dbl> 0.94, 0.16, 0.16, NA, NA, …
## $ velocity                                    <dbl> 0.22, 0.22, 0.22, 0.35, 1.…
## $ surface_turbidity                           <dbl> 20, 20, 20, 30, 30, 30, 10…
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
## $ channel_geomorphic_unit                     <chr> "glide", "glide", "glide",…
## $ location                                    <chr> "hatchery ditch", "hatcher…
## $ channel_location                            <chr> "LFC", "LFC", "LFC", "LFC"…
## $ water_temp                                  <dbl> 47, 47, 47, 47, 47, 47, 47…
## $ weather                                     <chr> "direct sunlight", "direct…
## $ flow                                        <dbl> 12, 12, 12, 12, 12, 12, 12…
## $ number_of_divers                            <dbl> 3, 3, 3, 3, 3, 3, 3, 3, 3,…
## $ reach_length                                <dbl> 25, 25, 25, 25, 25, 25, 25…
## $ reach_width                                 <dbl> 4, 4, 4, 4, 4, 4, 4, 4, 4,…
## $ channel_width                               <dbl> 7, 7, 7, 7, 7, 7, 7, 7, 7,…
## $ channel_type                                <chr> "sidechannel", "sidechanne…
## $ river_mile                                  <dbl> 66.6, 66.6, 66.6, 66.6, 66…
## $ coordinate_method                           <chr> "assigned based on similar…
## $ latitude                                    <dbl> 39.51602, 39.51602, 39.516…
## $ longitude                                   <dbl> -121.5588, -121.5588, -121…
## $ fish_presence                               <fct> 1, 1, 1, 0, 0, 0, 1, 0, 0,…
## $ month                                       <dbl> 3, 3, 3, 3, 3, 3, 3, 3, 3,…
```

### Review Data {#review-data}

#### Outliers

There are two `count` outliers, one in the high flow and one in the low
flow channel (figure 1), however their removal did not impact the model
results so they were kept in the dataset.

![](feather_river_hsi_hurdle_model_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

### High Flow vs. Low Flow Channel

Table 1 and figure 2 explore whether fish presence was impacted by the
high or low flow channels. Overall there are approximately half as many
fish present in the high flow channel compared to the low flow channel
(table 1). There are more fish present in the high flow channel but they
move quickly downstream into the low flow channel. Fish remain in the
low flow channel for much longer time (figure 2).

do we have the same amount of sampling plots in the high flow vs. low
flow?

| channel_location |     n |
|:-----------------|------:|
| HFC              | 11082 |
| LFC              | 17073 |

Table 1. Total count of fish between high flow and low flow channels

![](feather_river_hsi_hurdle_model_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

## Model 1 - Binary Cover Values {#model-1---binary-cover-values}

**Notes**

For this hurdle model, all substrate and cover variables
presence/absence based on a 20% threshold. Some of the cover variables
were also grouped as a cumulative of inchannel and overhead.

**Predictors**

-   small woody inchannel + half meter overhead
-   small woody inchannel + more than half meter overhead
-   large woody inchannel + half meter overhead
-   large woody inchannel + more than half meter overhead
-   cobble substrate
-   boulder substrate
-   small woody inchannel
-   large woody inchannel
-   submerged aquatic veg inchannel
-   undercut bank
-   more than half meter overhead
-   small woody half meter overhead
-   small woody more than half meter overhead
-   velocity
-   depth
-   fork length (mm)
-   month

<!-- -->

```         
## Rows: 7,067
## Columns: 15
## $ count                                           <dbl> 2, 3, 1, 0, 0, 0, 3, 0…
## $ depth                                           <dbl> 17, 17, 17, 19, 11, 12…
## $ velocity                                        <dbl> 0.22, 0.22, 0.22, 0.35…
## $ cobble_substrate                                <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ boulder_substrate                               <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ small_woody_cover_inchannel                     <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ large_woody_cover_inchannel                     <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ submerged_aquatic_veg_inchannel                 <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ undercut_bank                                   <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ half_meter_overhead                             <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ cover_more_than_half_meter_overhead             <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ small_woody_half_meter_overhead                 <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ small_woody_cover_more_than_half_meter_overhead <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ large_woody_cover_more_than_half_meter_overhead <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ month                                           <dbl> 3, 3, 3, 3, 3, 3, 3, 3…

## Start:  AIC=7558.11
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     large_woody_cover_inchannel + submerged_aquatic_veg_inchannel + 
##     cover_more_than_half_meter_overhead + half_meter_overhead + 
##     cobble_substrate + boulder_substrate + undercut_bank
## 
##                                       Df    AIC
## - large_woody_cover_inchannel          2 7557.4
## <none>                                   7558.1
## - submerged_aquatic_veg_inchannel      2 7558.3
## - velocity                             2 7558.9
## - boulder_substrate                    2 7559.5
## - undercut_bank                        2 7561.6
## - cobble_substrate                     2 7562.5
## - small_woody_cover_inchannel          2 7570.0
## - half_meter_overhead                  2 7598.7
## - depth                                2 7613.3
## - cover_more_than_half_meter_overhead  2 7615.2
## - month                                2 7931.2
## 
## Step:  AIC=7557.4
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     submerged_aquatic_veg_inchannel + cover_more_than_half_meter_overhead + 
##     half_meter_overhead + cobble_substrate + boulder_substrate + 
##     undercut_bank
## 
##                                       Df    AIC
## - submerged_aquatic_veg_inchannel      2 7557.2
## <none>                                   7557.4
## - velocity                             2 7558.0
## - boulder_substrate                    2 7558.8
## - undercut_bank                        2 7560.7
## - cobble_substrate                     2 7561.5
## - small_woody_cover_inchannel          2 7569.3
## - half_meter_overhead                  2 7601.1
## - depth                                2 7612.7
## - cover_more_than_half_meter_overhead  2 7613.7
## - month                                2 7935.9
## 
## Step:  AIC=7557.15
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     cover_more_than_half_meter_overhead + half_meter_overhead + 
##     cobble_substrate + boulder_substrate + undercut_bank
## 
##                                       Df    AIC
## - velocity                             2 7556.5
## <none>                                   7557.2
## - boulder_substrate                    2 7558.4
## - undercut_bank                        2 7560.4
## - cobble_substrate                     2 7560.8
## - small_woody_cover_inchannel          2 7568.7
## - half_meter_overhead                  2 7599.4
## - cover_more_than_half_meter_overhead  2 7612.4
## - depth                                2 7618.9
## - month                                2 7938.5
## 
## Step:  AIC=7556.52
## count ~ small_woody_cover_inchannel + depth + month + cover_more_than_half_meter_overhead + 
##     half_meter_overhead + cobble_substrate + boulder_substrate + 
##     undercut_bank
## 
##                                       Df    AIC
## <none>                                   7556.5
## - boulder_substrate                    2 7557.7
## - cobble_substrate                     2 7559.3
## - undercut_bank                        2 7560.2
## - small_woody_cover_inchannel          2 7568.4
## - half_meter_overhead                  2 7598.9
## - cover_more_than_half_meter_overhead  2 7613.4
## - depth                                2 7626.5
## - month                                2 7940.0
```

### Model 1 Results {#model-1-results}

```         
## 
## Call:
## pscl::hurdle(formula = count ~ small_woody_cover_inchannel + depth + 
##     month + cover_more_than_half_meter_overhead + half_meter_overhead + 
##     cobble_substrate + boulder_substrate + undercut_bank, data = hurdle_data, 
##     dist = "negbin")
## 
## Pearson residuals:
##      Min       1Q   Median       3Q      Max 
## -0.48190 -0.15100 -0.11491 -0.08316 25.83309 
## 
## Count model coefficients (truncated negbin with log link):
##                                       Estimate Std. Error z value
## (Intercept)                          -7.394203 119.665562  -0.062
## small_woody_cover_inchannel          -0.105111   0.252284  -0.417
## depth                                 0.042045   0.005796   7.254
## month                                -0.798561   0.076456 -10.445
## cover_more_than_half_meter_overhead   0.517212   0.251708   2.055
## half_meter_overhead                  -0.453936   0.229967  -1.974
## cobble_substrate                     -0.328315   0.262597  -1.250
## boulder_substrate                     0.013511   0.421461   0.032
## undercut_bank                        -0.744455   0.576608  -1.291
## Log(theta)                          -14.527592 119.665154  -0.121
##                                                 Pr(>|z|)    
## (Intercept)                                       0.9507    
## small_woody_cover_inchannel                       0.6769    
## depth                                  0.000000000000404 ***
## month                               < 0.0000000000000002 ***
## cover_more_than_half_meter_overhead               0.0399 *  
## half_meter_overhead                               0.0484 *  
## cobble_substrate                                  0.2112    
## boulder_substrate                                 0.9744    
## undercut_bank                                     0.1967    
## Log(theta)                                        0.9034    
## Zero hurdle model coefficients (binomial with logit link):
##                                      Estimate Std. Error z value
## (Intercept)                         -0.192882   0.166833  -1.156
## small_woody_cover_inchannel          0.501640   0.123275   4.069
## depth                                0.003441   0.001684   2.044
## month                               -0.558201   0.035181 -15.866
## cover_more_than_half_meter_overhead  0.917466   0.117449   7.812
## half_meter_overhead                  0.786198   0.116583   6.744
## cobble_substrate                    -0.247525   0.108561  -2.280
## boulder_substrate                    0.391418   0.166701   2.348
## undercut_bank                        0.854106   0.329881   2.589
##                                                 Pr(>|z|)    
## (Intercept)                                      0.24762    
## small_woody_cover_inchannel          0.00004715699577725 ***
## depth                                            0.04098 *  
## month                               < 0.0000000000000002 ***
## cover_more_than_half_meter_overhead  0.00000000000000565 ***
## half_meter_overhead                  0.00000000001544348 ***
## cobble_substrate                                 0.02260 *  
## boulder_substrate                                0.01887 *  
## undercut_bank                                    0.00962 ** 
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
## 
## Theta: count = 0
## Number of iterations in BFGS optimization: 60 
## Log-likelihood: -3759 on 19 Df

## Scale for colour is already present.
## Adding another scale for colour, which will replace the existing scale.
```

![](feather_river_hsi_hurdle_model_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

## Splitting out High Flow and Low Flow into Separate Models {#splitting-out-high-flow-and-low-flow-into-separate-models}

### High Flow Model {#high-flow-model}

For this hurdle model, all substrate and cover variables
presence/absence based on a 20% threshold. Some of the cover variables
were also grouped as a cumulative of inchannel and overhead.

**Predictors**

-   depth
-   velocity
-   month
-   percent large woody cover in channel
-   percent small woody cover in channel
-   percent cover half meter overhead
-   percent cover more than half meter overhead
-   percent cobble
-   percent boulder
-   percent undercut bank

**Notes**

-   removed combined cover variables (small and large woody in channel
    with cover overhead) because of issues with collinearity within the
    hurdle model

<!-- -->

```         
## Rows: 3,139
## Columns: 16
## $ count                                           <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ depth                                           <dbl> 2, 10, 18, 22, 6, 16, …
## $ velocity                                        <dbl> 0.00, 0.00, 0.20, 0.33…
## $ cobble_substrate                                <dbl> 0, 0, 1, 1, 0, 1, 1, 0…
## $ boulder_substrate                               <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ small_woody_cover_inchannel                     <dbl> 0, 0, 0, 0, 1, 1, 0, 0…
## $ large_woody_cover_inchannel                     <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ submerged_aquatic_veg_inchannel                 <dbl> 1, 1, 1, 0, 0, 0, 0, 0…
## $ undercut_bank                                   <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ half_meter_overhead                             <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ cover_more_than_half_meter_overhead             <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ small_woody_half_meter_overhead                 <dbl> 0, 0, 0, 0, 1, 1, 0, 0…
## $ small_woody_cover_more_than_half_meter_overhead <dbl> 0, 0, 0, 0, 1, 1, 0, 0…
## $ large_woody_cover_more_than_half_meter_overhead <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ month                                           <dbl> 3, 3, 3, 3, 3, 3, 3, 3…
## $ channel_location                                <chr> "HFC", "HFC", "HFC", "…

## Start:  AIC=1550.38
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     large_woody_cover_inchannel + submerged_aquatic_veg_inchannel + 
##     cover_more_than_half_meter_overhead + half_meter_overhead + 
##     cobble_substrate + boulder_substrate + undercut_bank

##                                       Df    AIC
## - undercut_bank                        2 1546.5
## - velocity                             2 1546.9
## - boulder_substrate                    2 1547.1
## - cobble_substrate                     2 1547.2
## - submerged_aquatic_veg_inchannel      2 1548.7
## - half_meter_overhead                  2 1549.4
## <none>                                   1550.4
## - large_woody_cover_inchannel          2 1555.7
## - cover_more_than_half_meter_overhead  2 1556.0
## - small_woody_cover_inchannel          2 1557.5
## - depth                                2 1585.4
## - month                                2 1608.3

## 
## Step:  AIC=1546.49
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     large_woody_cover_inchannel + submerged_aquatic_veg_inchannel + 
##     cover_more_than_half_meter_overhead + half_meter_overhead + 
##     cobble_substrate + boulder_substrate

##                                       Df    AIC
## - velocity                             2 1543.0
## - boulder_substrate                    2 1543.2
## - cobble_substrate                     2 1543.3
## - submerged_aquatic_veg_inchannel      2 1544.8
## - half_meter_overhead                  2 1545.5
## <none>                                   1546.5
## - large_woody_cover_inchannel          2 1551.8
## - cover_more_than_half_meter_overhead  2 1552.0
## - small_woody_cover_inchannel          2 1553.7
## - depth                                2 1581.7
## - month                                2 1604.5

## 
## Step:  AIC=1542.98
## count ~ small_woody_cover_inchannel + depth + month + large_woody_cover_inchannel + 
##     submerged_aquatic_veg_inchannel + cover_more_than_half_meter_overhead + 
##     half_meter_overhead + cobble_substrate + boulder_substrate

##                                       Df    AIC
## - cobble_substrate                     2 1539.8
## - boulder_substrate                    2 1539.8
## - submerged_aquatic_veg_inchannel      2 1541.0
## - half_meter_overhead                  2 1542.1
## <none>                                   1543.0
## - large_woody_cover_inchannel          2 1548.2
## - cover_more_than_half_meter_overhead  2 1548.7
## - small_woody_cover_inchannel          2 1551.1
## - depth                                2 1578.6
## - month                                2 1604.3

## 
## Step:  AIC=1539.75
## count ~ small_woody_cover_inchannel + depth + month + large_woody_cover_inchannel + 
##     submerged_aquatic_veg_inchannel + cover_more_than_half_meter_overhead + 
##     half_meter_overhead + boulder_substrate

##                                       Df    AIC
## - boulder_substrate                    2 1536.3
## - submerged_aquatic_veg_inchannel      2 1537.7
## - half_meter_overhead                  2 1538.8
## <none>                                   1539.8
## - large_woody_cover_inchannel          2 1544.8
## - cover_more_than_half_meter_overhead  2 1545.5
## - small_woody_cover_inchannel          2 1548.3
## - depth                                2 1574.8
## - month                                2 1601.0

## 
## Step:  AIC=1536.34
## count ~ small_woody_cover_inchannel + depth + month + large_woody_cover_inchannel + 
##     submerged_aquatic_veg_inchannel + cover_more_than_half_meter_overhead + 
##     half_meter_overhead

##                                       Df    AIC
## - submerged_aquatic_veg_inchannel      2 1534.3
## - half_meter_overhead                  2 1535.3
## <none>                                   1536.3
## - large_woody_cover_inchannel          2 1541.4
## - cover_more_than_half_meter_overhead  2 1542.0
## - small_woody_cover_inchannel          2 1544.7
## - depth                                2 1571.6
## - month                                2 1597.6

## 
## Step:  AIC=1534.33
## count ~ small_woody_cover_inchannel + depth + month + large_woody_cover_inchannel + 
##     cover_more_than_half_meter_overhead + half_meter_overhead

##                                       Df    AIC
## - half_meter_overhead                  2 1533.0
## <none>                                   1534.3
## - large_woody_cover_inchannel          2 1539.2
## - cover_more_than_half_meter_overhead  2 1539.7
## - small_woody_cover_inchannel          2 1542.3
## - depth                                2 1574.8
## - month                                2 1597.5

## 
## Step:  AIC=1532.95
## count ~ small_woody_cover_inchannel + depth + month + large_woody_cover_inchannel + 
##     cover_more_than_half_meter_overhead

##                                       Df    AIC
## <none>                                   1533.0
## - large_woody_cover_inchannel          2 1537.8
## - cover_more_than_half_meter_overhead  2 1539.6
## - small_woody_cover_inchannel          2 1545.1
## - depth                                2 1573.2
## - month                                2 1595.5
```

#### HFC Results

```         
## 
## Call:
## pscl::hurdle(formula = count ~ small_woody_cover_inchannel + depth + 
##     month + large_woody_cover_inchannel + cover_more_than_half_meter_overhead, 
##     data = hurdle_data, dist = "negbin")
## 
## Pearson residuals:
##      Min       1Q   Median       3Q      Max 
## -0.44409 -0.09011 -0.06011 -0.04483 50.63391 
## 
## Count model coefficients (truncated negbin with log link):
##                                      Estimate Std. Error z value Pr(>|z|)
## (Intercept)                           6.55203         NA      NA       NA
## small_woody_cover_inchannel           0.18700         NA      NA       NA
## depth                                 0.01534         NA      NA       NA
## month                                -0.88009         NA      NA       NA
## large_woody_cover_inchannel         -16.79550         NA      NA       NA
## cover_more_than_half_meter_overhead  -0.19287         NA      NA       NA
## Log(theta)                           -1.56152         NA      NA       NA
## Zero hurdle model coefficients (binomial with logit link):
##                                        Estimate  Std. Error z value
## (Intercept)                           -1.634536    0.451236  -3.622
## small_woody_cover_inchannel            1.258419    0.294020   4.280
## depth                                  0.017424    0.002621   6.648
## month                                 -0.593916    0.100566  -5.906
## large_woody_cover_inchannel          -16.205767 1137.643507  -0.014
## cover_more_than_half_meter_overhead    1.140610    0.333613   3.419
##                                            Pr(>|z|)    
## (Intercept)                                0.000292 ***
## small_woody_cover_inchannel         0.0000186850871 ***
## depth                               0.0000000000298 ***
## month                               0.0000000035110 ***
## large_woody_cover_inchannel                0.988634    
## cover_more_than_half_meter_overhead        0.000629 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
## 
## Theta: count = 0.2098
## Number of iterations in BFGS optimization: 27 
## Log-likelihood: -753.5 on 13 Df
```

![](feather_river_hsi_hurdle_model_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

### Low Flow Channel {#low-flow-channel}

```         
## Rows: 4,257
## Columns: 16
## $ count                                           <dbl> 2, 3, 1, 0, 0, 0, 3, 0…
## $ depth                                           <dbl> 17, 17, 17, 19, 11, 12…
## $ velocity                                        <dbl> 0.22, 0.22, 0.22, 0.35…
## $ cobble_substrate                                <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ boulder_substrate                               <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ small_woody_cover_inchannel                     <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ large_woody_cover_inchannel                     <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ submerged_aquatic_veg_inchannel                 <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ undercut_bank                                   <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ half_meter_overhead                             <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ cover_more_than_half_meter_overhead             <dbl> 0, 0, 0, 0, 0, 0, 0, 0…
## $ small_woody_half_meter_overhead                 <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ small_woody_cover_more_than_half_meter_overhead <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ large_woody_cover_more_than_half_meter_overhead <dbl> 0, 0, 0, 0, 0, 0, 1, 0…
## $ month                                           <dbl> 3, 3, 3, 3, 3, 3, 3, 3…
## $ channel_location                                <chr> "LFC", "LFC", "LFC", "…

## Start:  AIC=5482.77
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     large_woody_cover_inchannel + submerged_aquatic_veg_inchannel + 
##     cover_more_than_half_meter_overhead + half_meter_overhead + 
##     cobble_substrate + boulder_substrate + undercut_bank
## 
##                                       Df    AIC
## - boulder_substrate                    2 5480.9
## - submerged_aquatic_veg_inchannel      2 5481.4
## <none>                                   5482.8
## - undercut_bank                        2 5483.0
## - large_woody_cover_inchannel          2 5483.4
## - small_woody_cover_inchannel          2 5484.7
## - velocity                             2 5486.5
## - cobble_substrate                     2 5496.2
## - half_meter_overhead                  2 5504.2
## - cover_more_than_half_meter_overhead  2 5506.2
## - depth                                2 5511.6
## - month                                2 5806.4
## 
## Step:  AIC=5480.9
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     large_woody_cover_inchannel + submerged_aquatic_veg_inchannel + 
##     cover_more_than_half_meter_overhead + half_meter_overhead + 
##     cobble_substrate + undercut_bank
## 
##                                       Df    AIC
## - submerged_aquatic_veg_inchannel      2 5479.5
## <none>                                   5480.9
## - undercut_bank                        2 5481.0
## - large_woody_cover_inchannel          2 5481.5
## - small_woody_cover_inchannel          2 5483.1
## - velocity                             2 5484.9
## - cobble_substrate                     2 5492.6
## - half_meter_overhead                  2 5502.2
## - cover_more_than_half_meter_overhead  2 5504.7
## - depth                                2 5510.6
## - month                                2 5808.1
## 
## Step:  AIC=5479.52
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     large_woody_cover_inchannel + cover_more_than_half_meter_overhead + 
##     half_meter_overhead + cobble_substrate + undercut_bank
## 
##                                       Df    AIC
## - undercut_bank                        2 5479.3
## <none>                                   5479.5
## - large_woody_cover_inchannel          2 5479.8
## - small_woody_cover_inchannel          2 5481.5
## - velocity                             2 5482.7
## - cobble_substrate                     2 5490.8
## - half_meter_overhead                  2 5501.5
## - cover_more_than_half_meter_overhead  2 5501.8
## - depth                                2 5512.9
## - month                                2 5808.2
## 
## Step:  AIC=5479.27
## count ~ small_woody_cover_inchannel + depth + velocity + month + 
##     large_woody_cover_inchannel + cover_more_than_half_meter_overhead + 
##     half_meter_overhead + cobble_substrate
## 
##                                       Df    AIC
## <none>                                   5479.3
## - large_woody_cover_inchannel          2 5479.5
## - small_woody_cover_inchannel          2 5481.0
## - velocity                             2 5482.7
## - cobble_substrate                     2 5491.5
## - cover_more_than_half_meter_overhead  2 5502.7
## - half_meter_overhead                  2 5506.1
## - depth                                2 5513.0
## - month                                2 5811.7
```

#### LFC Results

```         
## 
## Call:
## pscl::hurdle(formula = count ~ small_woody_cover_inchannel + depth + 
##     velocity + month + large_woody_cover_inchannel + cover_more_than_half_meter_overhead + 
##     half_meter_overhead + cobble_substrate, data = hurdle_data, dist = "negbin")
## 
## Pearson residuals:
##     Min      1Q  Median      3Q     Max 
## -0.3991 -0.1835 -0.1331 -0.0917 23.3386 
## 
## Count model coefficients (truncated negbin with log link):
##                                       Estimate Std. Error z value
## (Intercept)                          -5.456301  44.316254  -0.123
## small_woody_cover_inchannel          -0.231072   0.282405  -0.818
## depth                                 0.041585   0.007427   5.599
## velocity                             -0.302204   0.232650  -1.299
## month                                -0.746931   0.090156  -8.285
## large_woody_cover_inchannel          -0.621159   0.667033  -0.931
## cover_more_than_half_meter_overhead   0.499440   0.285283   1.751
## half_meter_overhead                  -0.504560   0.271015  -1.862
## cobble_substrate                     -0.194857   0.260716  -0.747
## Log(theta)                          -12.492252  44.314583  -0.282
##                                                 Pr(>|z|)    
## (Intercept)                                       0.9020    
## small_woody_cover_inchannel                       0.4132    
## depth                                       0.0000000216 ***
## velocity                                          0.1940    
## month                               < 0.0000000000000002 ***
## large_woody_cover_inchannel                       0.3517    
## cover_more_than_half_meter_overhead               0.0800 .  
## half_meter_overhead                               0.0626 .  
## cobble_substrate                                  0.4548    
## Log(theta)                                        0.7780    
## Zero hurdle model coefficients (binomial with logit link):
##                                      Estimate Std. Error z value
## (Intercept)                          0.697772   0.205700   3.392
## small_woody_cover_inchannel          0.323436   0.140747   2.298
## depth                               -0.001453   0.002527  -0.575
## velocity                            -0.189312   0.079757  -2.374
## month                               -0.603630   0.040222 -15.007
## large_woody_cover_inchannel          0.699894   0.360236   1.943
## cover_more_than_half_meter_overhead  0.663903   0.131526   5.048
## half_meter_overhead                  0.697217   0.130509   5.342
## cobble_substrate                    -0.463989   0.119436  -3.885
##                                                 Pr(>|z|)    
## (Intercept)                                     0.000693 ***
## small_woody_cover_inchannel                     0.021562 *  
## depth                                           0.565332    
## velocity                                        0.017616 *  
## month                               < 0.0000000000000002 ***
## large_woody_cover_inchannel                     0.052031 .  
## cover_more_than_half_meter_overhead         0.0000004472 ***
## half_meter_overhead                         0.0000000918 ***
## cobble_substrate                                0.000102 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 
## 
## Theta: count = 0
## Number of iterations in BFGS optimization: 44 
## Log-likelihood: -2721 on 19 Df
```

![](feather_river_hsi_hurdle_model_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

``` r
knitr::knit_exit()
```
