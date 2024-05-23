AccessUK
================

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)

Easily streamline accessibility measures for Great Britain.

## Introduction

`AccessUK` is an open-source tool for the R programming language
designed to streamline the integration of accessibility measures into R
workflows focusing on Great Britain (GB), thereby unlocking the
potential of spatial data and analysis by informing decision-making
processes and supporting sustainable practices across diverse sectors.

The main aim of this tool is to manage and distribute a series of
pre-computed Accessibility-related measures for small geographic areas
in GB described
[here](https://www.nature.com/articles/s41597-023-02890-w) (PTAI
dataset). It offers additional functions that enable users to customise
or create new accessibility measures.

`AccessUK` uses [`DuckDB`](https://duckdb.org/), a relational database
management system optimised for analytical workloads, in the background.
This facilitates the rapid execution of queries without loading the full
data into virtual memory. This mitigates common computational challenges
associated with large travel matrices.

## Installation

To install the latest version of `AccessUK` directly from GitHub, please
follow the steps below:

### 1. Install the `devtools` package (if not already installed)

You’ll need the `devtools` package to install R packages from GitHub. If
you don’t have it installed, run:

``` r
install.packages("devtools")
```

### 2. Install AccessUK

With devtools installed, you can now install the AccessUK package:

``` r
devtools::install_github("urbanbigdatacentre/AccessUK")
```

## Usage

`AccessUK` does three main things: (1) get ready-to-use accessibility
measures for a range of urban and regional services; (2) tailor
accessibility measures to destinations not previously included in the
dataset based on pre-computed travel matrices; (3) estimate new
accessibility measures based on user-generated TTMs and service
locations.

``` r
library(AccessUK)
library(tidyverse)
library(sf)
```

### 1. Getting precomputed accessibility measures

To get precomputed measures, the first step is to define a list 2011
lower super output areas (LSOA) or data zones (DZ) code for the desired
locations. the example below selects a few areas in central London,

``` r
lsoa_london <- c('E01000919', 'E01002726', 'E01003014', 'E01033490', 'E01000914', 'E01000937', 'E01032583', 'E01000855', 'E01003016', 'E01000918', 'E01000002', 'E01032739', 'E01000916', 'E01004734', 'E01000936', 'E01004735', 'E01002724', 'E01000850', 'E01033596', 'E01000852', 'E01000853', 'E01003927', 'E01033595', 'E01004731', 'E01000001', 'E01003935', 'E01004763', 'E01004736', 'E01000917', 'E01003929', 'E01003013', 'E01032740', 'E01032582', 'E01000915', 'E01003930', 'E01000920', 'E01003017', 'E01003934', 'E01004733', 'E01032584')
```

The desired locations are passed to the `get_accessibility()` function.
Also, the type of destination can be specified in the ‘service’
argument. It can be chosen from “employment”, “supermarkets”, “school”,
“gp” (general practice), “hospital”, and “cities”. The example below
retrieves accessibility to employment in central London.

``` r
accessibility_london <- get_accessibility(
  from = lsoa_london, 
  service = 'employment', 
  mode = "public_transport"
)
glimpse(accessibility_london)
## Rows: 40
## Columns: 18
## $ geo_code           <chr> "E01032584", "E01032583", "E01032582", "E01003927",…
## $ geo_label          <chr> "Southwark 034E", "Southwark 034D", "Lambeth 036E",…
## $ employment_15      <dbl> 116600, 146950, 106650, 140075, 475675, 326450, 201…
## $ employment_30      <dbl> 2006530, 2265690, 2120155, 1924470, 1930935, 216792…
## $ employment_45      <dbl> 3382235, 3474700, 3508980, 3219590, 3187045, 325164…
## $ employment_60      <dbl> 4532830, 4630565, 4701855, 4311400, 4307635, 452590…
## $ employment_75      <dbl> 5937880, 5992060, 6095340, 5729995, 5717505, 599671…
## $ employment_90      <dbl> 7356745, 7474240, 7465010, 7140865, 7082720, 756973…
## $ employment_105     <dbl> 8488575, 8515250, 8598215, 8312200, 8297765, 879248…
## $ employment_120     <dbl> 9596665, 9628955, 9690610, 9379390, 9323300, 992857…
## $ employment_pct_15  <dbl> 0.3877880, 0.4887260, 0.3546963, 0.4658611, 1.58199…
## $ employment_pct_30  <dbl> 6.673313, 7.535226, 7.051206, 6.400398, 6.421899, 7…
## $ employment_pct_45  <dbl> 11.24863, 11.55615, 11.67016, 10.70770, 10.59947, 1…
## $ employment_pct_60  <dbl> 15.07528, 15.40032, 15.63742, 14.33884, 14.32632, 1…
## $ employment_pct_75  <dbl> 19.74819, 19.92838, 20.27187, 19.05680, 19.01526, 1…
## $ employment_pct_90  <dbl> 24.46705, 24.85781, 24.82711, 23.74907, 23.55569, 2…
## $ employment_pct_105 <dbl> 28.23128, 28.32000, 28.59592, 27.64470, 27.59669, 2…
## $ employment_pct_120 <dbl> 31.91657, 32.02396, 32.22901, 31.19395, 31.00741, 3…
```

The results includes both the absolute employment available for a range
of travel times in minutes as well as the relative employment in
percent.

### 2. Tailored accessibility measures

Given new point locations in GB, the user can tailor its own
accessibility measures at the LSOA/DZ level. This uses 2011 LSOA/DZ
geometries in the background. This is combined with pre-computed travel
times in the [PTAI
dataset](https://www.nature.com/articles/s41597-023-02890-w). The
example below uses retail points and for various time cuts.

``` r
# New destination points for this example
data_dir = system.file('data', package = "AccessUK")
load(file.path(data_dir, 'retail_points.RData'))
retail_points <- retail_points %>% 
  st_as_sf(coords = c('long_wgs', 'lat_wgs'), crs = 4326)

# Run my_accessibility
timecuts <- c(10, 20, 30)
retail_accessibility <- my_accessibility(
  destinations = retail_points, 
  time_cut = timecuts
)
## Warning: attribute variables are assumed to be spatially constant throughout
## all geometries

glimpse(retail_accessibility)
## Rows: 41,729
## Columns: 4
## $ from_id     <chr> "E01000001", "E01000002", "E01000003", "E01000005", "E0100…
## $ access_n_10 <dbl> 6, 4, 6, 0, 0, 3, 0, 3, 4, 0, 0, 2, 2, 2, 0, 2, 2, 0, 0, 1…
## $ access_n_20 <dbl> 27, 16, 25, 24, 5, 11, 6, 11, 11, 9, 8, 4, 3, 2, 3, 6, 3, …
## $ access_n_30 <dbl> 109, 74, 89, 95, 12, 15, 14, 17, 17, 13, 12, 18, 13, 9, 8,…
```

The result includes accessibility for all of GB, given that the retail
points cover all the territory. However, we visualise a subset in
central London.

``` r
# Read LSOA geometries
lsoa_geoms <- st_read(file.path(data_dir, 'lsoa_geoms/infuse_lsoa_lyr_2011_clipped.shp'))
## Reading layer `infuse_lsoa_lyr_2011_clipped' from data source 
##   `C:\Users\jvt3d\AppData\Local\Programs\R\R-4.3.0\library\AccessUK\data\lsoa_geoms\infuse_lsoa_lyr_2011_clipped.shp' 
##   using driver `ESRI Shapefile'
## Simple feature collection with 42619 features and 3 fields
## Geometry type: MULTIPOLYGON
## Dimension:     XY
## Bounding box:  xmin: -69.1254 ymin: 5337.9 xmax: 655604.7 ymax: 1220302
## Projected CRS: OSGB36 / British National Grid
# Map
retail_accessibility %>% 
  filter(from_id %in% lsoa_london) %>% 
  left_join(lsoa_geoms, by = c('from_id' = 'geo_code')) %>% 
  st_as_sf() %>% 
  ggplot() +
  geom_sf(aes(fill =  access_n_30), col = NA) +
  scale_fill_viridis_c() +
  labs(
    title = 'Accessibility to retail points in London by public transport within 30 minutes',
    subtitle = 'Contains retail points larger than 280 m2',
    fill = 'Retail points'
  ) +
  theme_void()
```

![](README_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

### 3. Compute new accessibility measures

The user can estimate completely new accessibility measures using
`DuckDB` in the background for any region by providing a travel matrix
in `CSV` or `Parquet` format. The user should input aggregated locations
using the same ID as the travel matrix. This can contain different types
of locations in each column with the first column named “id”.

``` r
# Aggregate locations in Manchester by LSOA
aggregated_retail <- retail_points %>% 
  filter(town == 'Manchester') %>% 
  my_accessibility(0)
## Warning: attribute variables are assumed to be spatially constant throughout
## all geometries
# First column as 'id'
aggregated_retail <- aggregated_retail %>% 
  rename(retail = access_n_0, id = from_id)

# Specify the location of a travel matrix. This can be a folder with multiple files or a single file
ttm_path <- file.path(data_dir, 'accessibility_indicators_gb/ttm/ttm_pt_20211122.csv')

# Estimate accessibility for various thresholds
new_accessibility <- estimate_accessibility(
  travel_matrix = ttm_path, 
  travel_cost =  'travel_time_p50',
  weights = aggregated_retail, 
  time_cut = timecuts
)
glimpse(new_accessibility)
## Rows: 41,729
## Columns: 4
## $ from_id          <chr> "E01000001", "E01000002", "E01000003", "E01000005", "…
## $ access_retail_10 <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
## $ access_retail_20 <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
## $ access_retail_30 <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
```

This returns all LSOA/DZ in GB. As we are providing data for Manchester
only, we can filter relevant observations only.

``` r
new_accessibility %>% 
  filter(access_retail_20 > 0) %>% 
  left_join(lsoa_geoms, by = c('from_id' = 'geo_code')) %>% 
  st_as_sf() %>% 
  ggplot() +
  geom_sf(aes(fill =  access_retail_20), col = NA) +
  scale_fill_viridis_c() +
  labs(
    title = 'Accessibility to retail points in Manchester by public transport within 20 minutes',
    subtitle = 'Contains retail points larger than 280 m2',
    fill = 'Retail points'
  ) +
  theme_void()
```

![](README_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->

## Citation

If you use this package, please cite as following:

- Verduzco Torres, J. R., & McArthur, D. P. (2024). Public transport
  accessibility indicators to urban and regional services in Great
  Britain. Scientific Data, 11(1), Article 1.
  <https://doi.org/10.1038/s41597-023-02890-w>
- Verduzco Torres, J. R. (2023). AccessUK (v0.0.1-alpha) \[R\].
  University of Glasgow.
  <https://github.com/urbanbigdatacentre/AccessUK>

## Related resources and projects

- DuckDB - <https://duckdb.org/>
- Public transport accessibility indicators (PTAI) in Great Britain
  repo - <https://github.com/urbanbigdatacentre/access_uk_open>
- `accessibility` R package - <https://github.com/ipeaGIT/accessibility>

## References

1.  Verduzco Torres, J. R., & McArthur, D. (2022). Public Transport
    Accessibility Indicators for Great Britain \[dataset\]. Zenodo.
    <https://doi.org/10.5281/zenodo.8037156>
2.  Verduzco Torres, J. R., & McArthur, D. P. (2024). Public transport
    accessibility indicators to urban and regional services in Great
    Britain. Scientific Data, 11(1), Article 1.
    <https://doi.org/10.1038/s41597-023-02890-w>
