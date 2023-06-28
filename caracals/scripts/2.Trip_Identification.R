# This script takes the output of Cluster_Locations.R and identifies trips
# Potential parameter sensitivity in the distance away from centroid a track is considered
# a 'trip'

# Set basic stuff we need on the cluster rstudio
setwd('C:/Users/herit/My Drive/Research/Caracal/Denning/2023JUNE')
#setwd('~/merondun/misc_research/caracals/')
#.libPaths('~/mambaforge/envs/caracals/lib/R/library')
set.seed(111)

library(tidyverse)
library(geosphere)
library(viridis)
library(sf)
library(ggmap)

##### Calculate some metrics #####
# We will base all these analyses on a 'trip'
df_full = read.table('Caracal_Denning_Data_2023JUNE25.txt',header=TRUE,sep='\t')  %>%
  as_tibble %>%
  mutate(Date_time = ymd_hms(Date_time))

threshold = 250 #meters away from centroid until a trip starts

# Define the start and end of a trip. A trip starts when the individual is
# more than n meters from the cluster centroid, and ends when the individual
# returns within n meters of the centroid, not including the distances before / after 
# the individual was within the threshold
df_full = df_full %>% 
  group_by(ID) %>% 
  mutate(away = ifelse(dist_to_centroid > threshold,1,0),
         trip = ifelse(away == 1, data.table::rleid(away), NA))

# The numbering of the rleid command will count 1..3..5 due to the succession of 0 and 1 aways, so add a unique ID for each trip  
trips = df_full %>% select(ID,trip) %>% drop_na(trip) %>% unique %>% group_by(ID) %>% mutate(trip_ID = paste0(ID,'_',row_number())) 

# Bind into a final frame, points not involved a trip will be 'NA'
df_trips = left_join(df_full %>% select(-c(cluster,away)),trips) %>% select(-c(trip)) 

# Calculating the distance between subsequent points, we will need this for total distance for each trip 
df_trips = df_trips %>%
  group_by(ID) %>%
  arrange(Date_time) %>%
  mutate(
    lat_lag = lag(Latitude, default = first(Latitude)),
    lon_lag = lag(Longitude, default = first(Longitude)),
    dist = distHaversine(cbind(lon_lag, lat_lag), cbind(Longitude, Latitude))) %>%  #using geosphere calculate distance between points, used for total_distance 
  group_by(ID,trip_ID) %>% 
  mutate(dist1 = if_else(row_number() == 1, dist_to_centroid, dist)) %>% # BUT, for the initial trip start, we DO want to use distance from centroid, since we need our initial distance 
  mutate(dist2 = if_else(row_number() == n(), dist + dist_to_centroid, dist1)) %>% #AND for the final trip end, we ADD the distance_to_centroid to the distance from the last segment 
  ungroup()

# Check that things are sensible with df_trips %>% print(n = 100), and then drop the columns we don't need
df_trips = df_trips %>% select(-c(dist,lat_lag,lon_lag,dist1)) %>% dplyr::rename(dist=dist2)

# Summarize those trips! 
trip_summaries <- df_trips %>%
  group_by(ID, trip_ID) %>%
  summarise(
    trip_start = min(Date_time),
    max_dist = max(dist_to_centroid, na.rm = TRUE),
    total_dist = sum(dist, na.rm = TRUE),
    duration = max(Date_time) - min(Date_time),
    total_hours = as.numeric(duration / 60 / 60) + 6, #WE MUST ADD THE +6, because our tracks do not include the initial 2 time steps (when the animal was within the boundary). See chart 
    .groups = "drop"
  ) %>% ungroup %>% 
  group_by(ID) %>% 
  mutate(proportion = (total_hours/sum(total_hours)))  # Proportion of time spent on each trip compared to the total

# How many trips for each caracal
trip_summaries %>% 
  drop_na(trip_ID) %>%
  ggplot(aes(x=ID,fill=ID))+
  geom_bar(position=position_dodge())+
  scale_fill_viridis(discrete=TRUE)+
  ggtitle('Total Number of Trips')+
  xlab('')+ylab('Number of Trips')+
  theme_bw()

# Inspect a few manually, rebind with the original frame
trip_summaries %>% arrange(desc(total_hours)) 
full_trip = left_join(df_trips %>% dplyr::rename(segment_distance = dist),trip_summaries %>% select(-c(trip_start,duration)))
write.table(full_trip,'Caracal_Denning_Data_Trips-250m_2023JUNE25.txt',quote=F,sep='\t',row.names=F)

# Output a KML of all trips for manual inspection
# Loop through each trip and export a kml file (THIS WILL CREATE A LOT OF KML FILES!) 
trips = full_trip %>% drop_na(trip_ID) %>% pull(trip_ID) %>% unique; counter = 0
for (trip in trips) {
  
  cat('Working on trip: ',trip,'\n'); counter = counter + 1
  # Grab trip
  df_tp = full_trip[grepl(trip,full_trip$trip_ID),]
  #Convert to sf
  df_sf = st_as_sf(df_tp, coords = c("Longitude", "Latitude"), crs = 4326)
  # Convert point data to a linestring
  #df_line = st_combine(df_sf) %>% st_cast("LINESTRING")
  # Write kml
  st_combine(df_sf) %>% st_write(paste0('kmls/',trip,'.kml'),append=TRUE)
  
}

