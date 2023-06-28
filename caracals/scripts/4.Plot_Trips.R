s script takes the output of Cluster_Locations.R and summarizes some trip information
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
library(ggpubr)
library(ggmap)
register_google(key = "AIzaSyCSsRQi5vhLqJ_NLpIVR3HitI-suQ98mDg") # KEEP THIS SECRET

full_trip = read.table('Caracal_Denning_Data_Trips-250m_2023JUNE25.txt',header=TRUE,comment.char='',sep='\t') %>% as_tibble

# Define the bounding box of your data
bbox <- st_bbox(st_as_sf(full_trip, coords = c("Longitude", "Latitude"), crs = 4326)) 
names(bbox) = c('left','bottom','right','top')

# Download a satellite map
map <- get_map(bbox, maptype = "satellite", zoom = 11)
ggmap(map)

# Grab and plot a random trip 
trip = sample(unique(full_trip$trip_ID),1) # Grab a random trip


test = 'TMC13'
for (id in unique(full_trip$ID)) {
  counter = 0; plot_list = list()
  id_dat = full_trip %>% filter(ID == id) %>% drop_na(trip_ID)
  
  #Loop through each trip
  for (trip in unique(id_dat$trip_ID)) {
    
    cat('Ploting trip: ',trip,' for sample: ',id,'\n') ; counter = counter + 1 
    
    # Grab points for that trip 
    df = full_trip[grepl(paste0(trip,'$'),full_trip$trip_ID),] 
    
    # Grab centroid too for reference 
    centroid = full_trip[grepl(paste0(trip,'$'),full_trip$trip_ID),] %>% select(ID,trip_ID,centroid_lat,centroid_long) %>% unique
    
    # Grab labels about trip statistics 
    labs = df %>% ungroup %>% select(ID,max_dist,total_dist,total_hours,proportion) %>% unique %>% 
      mutate(Label = paste0(trip,'. Max Dist: ',round(max_dist,0),'m Total Dist: ',round(total_dist,0),'m Total Hours: ',round(total_hours,0)))
    
    #add some room around the edges
    push = 0.02
    
    #plot it 
    gp = ggmap(map) +
      # To limit the plot to the bounding box of the current trip:
      coord_cartesian(xlim = c(min(df$Longitude)-push, max(df$Longitude)+push), 
                      ylim = c(min(df$Latitude)-push, max(df$Latitude)+push)) +
      geom_point(data = centroid, aes(x=centroid_long, y=centroid_lat),shape=21,size=4,fill='yellow') +
      geom_line(data = df, aes(x=Longitude, y=Latitude),col='white',lwd=2) + 
      geom_point(data = df, aes(x=Longitude, y=Latitude),shape=21,size=2,fill='white') +
      geom_label(data=labs,aes(x=Inf,y=Inf,label=Label),size=1.5,hjust=1,vjust=1) + 
      xlab('')+ylab('')+theme(axis.text.x=element_blank(),axis.text.y=element_blank())
    
    plot_list[[counter]] = gp
 
  }
  arranged_plots = ggarrange(plotlist = plot_list)
  ggsave(paste0(id,'_Trips.png'), arranged_plots, dpi=300,width = 16, height = 14)  
  
  plot_list = list()
}


