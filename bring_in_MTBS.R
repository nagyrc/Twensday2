#Script for bringing in fire data for Twensday hazard project
#Dr. R. Chelsea Nagy
#created August 29, 2019


#load multiple libraries 
x <- c("sf", "assertthat", "purrr", "httr", "plyr", "stringr", "raster", "ggplot2", "doBy", "reshape", "velox", "sp", "tidyverse","rgdal")
lapply(x, library, character.only = TRUE, verbose = FALSE)

#set crs for all data layers: Albers Equal Area
crs1 <- 'ESRI:102003'
crs1b <- '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs'


#Download US shapefile
us_shp <- file.path('data', 'states_shp', "cb_2016_us_state_20m.shp")
if (!file.exists(us_shp)) {
  # The location where the data is housed
  loc <- "https://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_state_20m.zip"
  # Where you want to data to be downloaded to
  dest <- paste0(file.path('states_shp', ".zip"))
  # Download the data
  download.file(loc, dest)
  # Unzip the data file and move to permenant location
  unzip(dest, exdir = file.path('states_shp'))
  # Delete zip file
  unlink(dest)
  # Check to make sure it worked
  assert_that(file.exists(us_shp))
}


#bring in shapefile of US states; select 48 contiguous; tranform to match crs of other layers; remove extra fields
usa_shp <- st_read(file.path('data', 'states_shp'), layer = 'cb_2016_us_state_20m') %>%
  dplyr::filter(!(NAME %in% c("Alaska", "Hawaii", "Puerto Rico"))) %>%
  dplyr::select(STATEFP, STUSPS) %>%
  setNames(tolower(names(.))) %>% 
  st_transform(.,crs1b)
#not sure if the transform statment worked here

st_crs(usa_shp)

#MTBS
#Download the MTBS fire polygons
mtbs_shp <- file.path('data', 'mtbs', 'mtbs_perims_DD.shp')
if (!file.exists(mtbs_shp)) {
  loc <- "https://edcintl.cr.usgs.gov/downloads/sciweb1/shared/MTBS_Fire/data/composite_data/burned_area_extent_shapefile/mtbs_perimeter_data.zip"
  dest <- paste0('mtbs', ".zip")
  download.file(loc, dest)
  unzip(dest, exdir = 'data/mtbs')
  unlink(dest)
  assert_that(file.exists(mtbs_shp))
}


#bring in MTBS data
mtbs_fire <- st_read(dsn = 'data/mtbs',
                     layer = "mtbs_perims_DD", quiet = TRUE) %>%
  mutate(MTBS_ID = Fire_ID,
         MTBS_DISCOVERY_YEAR = Year) %>%
  dplyr::select(MTBS_ID, MTBS_DISCOVERY_YEAR) %>%
  st_transform(., crs1b)

st_crs(mtbs_fire)
#yes, this was correctly transformed



#plot mtbs fires and usa_shp
plot(usa_shp[1])

#this runs forever
#plot(mtbs_fire[1])

#plot both together
plot(mtbs_fire[1], add = TRUE)


####convert mtbs polygons to raster
require(raster)
library(fasterize)

# Create a generic raster, set the extent to the same as mtbs_fire
r.raster <- raster("data/EmptyGrid/Empty_250_US.tif")

# Make a raster of the mtbs fires:
mtbs.r <- fasterize(st_transform(mtbs_fire, crs(r.raster)), r.raster)

plot(mtbs.r)

writeRaster(x = mtbs.r, filename = "data/data_output/large-fire-occurrence_1984-2017_mtbs_zillow-grid.tif")




