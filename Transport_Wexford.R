
transport_2011 <- read.csv('transportCSOfile.csv')
names(transport_2011)
headers <- names(transport_2011)

library(stringr)
library(tidyr)
library(dplyr)
library(ggplot2)
library(viridis)
library(hrbrthemes)
library(scales)

# headers
headers_travelby <- headers[10:22]
headers_travelby <- str_split_fixed(headers_travelby, "_", 18)[,c(13:16)]
headers_travelby <- paste("Travelby", headers_travelby[,1], headers_travelby[,2], 
                              headers_travelby[,3], headers_travelby[,4], sep = " ")


headers_travel_time <- headers[23:32]
headers_travel_time <- str_split_fixed(headers_travel_time, "_", 17)[,c(15:17)]
headers_travel_time <- paste("Leaving", headers_travel_time[,1], headers_travel_time[,2],
                             headers_travel_time[,3], sep = " ")

headers_journey <- headers[33:40]
headers_journey <- str_split_fixed(headers_journey, "_", 20)[,c(12:20)]
headers_journey <- paste("Journey", headers_journey[,1], headers_journey[,2], headers_journey[,3],
                         headers_journey[,4], headers_journey[,5], headers_journey[,6], 
                         headers_journey[,7], headers_journey[,8], headers_journey[,9])

headers[10:22] <- headers_travelby
headers[23:32] <- headers_travel_time
headers[33:40] <- headers_journey

headers[10:40] <- str_split_fixed(headers[10:40], '2011', 2)[,1]
headers <- trimws(headers)
headers <- make.names(headers, unique=TRUE)

names(transport_2011) <- headers
names(transport_2011)


# handling null values

which(is.na(transport_2011), arr.ind = TRUE)

transport_2011[79,30] <- ceiling(mean(transport_2011[,30], na.rm = TRUE))

travelby_total = rowSums(transport_2011[10:18], na.rm = TRUE)
transport_2011[29,22] <- travelby_total[29]

which(is.na(transport_2011), arr.ind = TRUE)


# handling outliers


treat_outliers <- function(df){
  summary(df)
  sd(df)
  boxplot(df, xlab='before')
  boxplot.stats(df)
  if(abs(mean(df) - median(df)) <= 5){
    df[df>(quantile(df,prob=.75)) + (1.5*IQR(df))] <- mean(df)
    df[df<(quantile(df,prob=.25)) - (1.5*IQR(df))] <- mean(df)
    boxplot(df, xlab='after')
  }
  else{
    df[df>(quantile(df,prob=.75)) + (1.5*IQR(df))] <- median(df)
    df[df<(quantile(df,prob=.25)) - (1.5*IQR(df))] <- median(df)
    boxplot(df, xlab='after')
  }
  return(df)
}

for(i in 10:40){
  transport_2011[,i] <- treat_outliers(transport_2011[,i])
}

transport_2011$Travelby.Total <- rowSums(transport_2011[10:18])
transport_2011$Leaving.Total <- rowSums(transport_2011[23:31])
transport_2011$Journey.Total <- rowSums(transport_2011[33:39])

transport_2011$Travelby.Soft.Modes.Comb <- rowSums(transport_2011[10:11])
transport_2011$Travelby.Public.Transport.Comb <- rowSums(transport_2011[12:13])
transport_2011$Travelby.Private.Transport.Comb <- rowSums(transport_2011[14:17])

write.csv('cleaned_TransportCSOfile.csv', "")


#1

df <- as.data.frame(colSums(transport_2011[10:18]))
df <- cbind(rownames(df),df)
names(df)[1] <- 'Travelby'
names(df)[2] <- 'Total'
df[,2] <- as.integer(df[,2])

p<-ggplot(data = df, aes(x=df$Travelby, y=df$Total)) +
  geom_bar(stat="identity", fill = "#56B4E9") +
  geom_text(aes(label=df$Travelby), vjust=-1, size=3.5)  +
  theme_minimal() +
  xlab("Mode of Transports Nationally") +
  ylab("Count")
p

#2
transport_2011_wexford <- transport_2011[transport_2011$County == 'Wexford',]
transport_2011_wexford
df <- as.data.frame(colSums(transport_2011_wexford[10:18]))
df <- cbind(rownames(df),df)
names(df)[1] <- 'Travelby'
names(df)[2] <- 'Total'
df[,2] <- as.integer(df[,2])

p<-ggplot(data = df, aes(x=df$Travelby, y=df$Total)) +
  geom_bar(stat="identity", fill = "steelblue") +
  geom_text(aes(label=df$Travelby), vjust=-1, size=3.5)  +
  theme_minimal() +
  xlab("Mode of Transports in County Wexford") +
  ylab("Count")
p

#3
transport_2011_city <- grep("City", transport_2011$County, value = TRUE)
transport_2011_city

transport_2011_noncity <- grep("City", transport_2011$County, value = TRUE, invert = TRUE)
transport_2011_noncity

transport_2011_citydf <- subset(transport_2011, transport_2011$County %in% transport_2011_city)
transport_2011_noncitydf <- subset(transport_2011, transport_2011$County %in% transport_2011_noncity)

df1 <- as.data.frame(colSums(transport_2011_citydf[10:18]))
df2 <- as.data.frame(colSums(transport_2011_noncitydf[10:18]))
df1 <- cbind(rownames(df1),df1)
df2 <- cbind(rownames(df2),df2)
dfc <- as.data.frame(c(rep('City',9)))
dfnc <- as.data.frame(c(rep('Non-City',9)))
df1 <- cbind(df1, dfc)
df2 <- cbind(df2, dfnc)

names(df1)[1] <- 'Travelby'
names(df1)[2] <- 'Total'
names(df1)[3] <- 'Region'
names(df2)[1] <- 'Travelby'
names(df2)[2] <- 'Total'
names(df2)[3] <- 'Region'
df1[,2] <- as.integer(df1[,2])
df2[,2] <- as.integer(df2[,2])
df <- rbind.data.frame(df1, df2)

ggplot(data = df, aes(fill=df$Region, y=df$Total, x=df$Travelby)) + 
  geom_bar(position="dodge", stat="identity") +
  geom_text(aes(label=df$Travelby), vjust=-1, size=3.5)  +
  scale_fill_viridis(discrete = T, option = "E") +
  ggtitle("Min and Max for Travel Modes") +
  facet_wrap(~df$Region) +
  theme_classic() +
  xlab("Areas") +
  ylab("Min and Max Values")

#4

df <- as.data.frame(c(sum(colSums(transport_2011[c(23:26,29:30)]))/colSums(transport_2011[32]), 
                      1-sum(colSums(transport_2011[c(23:26,29:30)]))/colSums(transport_2011[32])))

names(df)[1] <- 'ratio'

ggplot(data = df, aes(x=" " , y=df$ratio, fill=c('outside_8to9am','total'))) +
  geom_bar(stat="identity") +
  coord_polar("y", start=0) +
  geom_text(aes(y = df$ratio + c(0, cumsum(df$ratio)[-length(df$ratio)]), 
                label = percent(df$ratio)), size=5) +
  theme_get() +
  scale_fill_brewer(palette="Set2") +
  ylab("Proportion of commuters leaving outside 8 to 9 hr")


#5
df <- as.data.frame(c(sum(colSums(transport_2011_wexford[c(36:37)]))/colSums(transport_2011_wexford[40]),
                      1-sum(colSums(transport_2011_wexford[c(36:37)]))/colSums(transport_2011_wexford[40])))
names(df)[1] <- 'ratio'

ggplot(data = df, aes(x=" " , y=df$ratio, fill=c('longer than 45 min','total'))) +
  geom_bar(stat="identity") +
  coord_polar("y", start=0) +
  geom_text(aes(y = df$ratio + c(0, cumsum(df$ratio)[-length(df$ratio)]), 
                label = percent(df$ratio)), size=5) +
  scale_fill_brewer(palette="Blues")+
  theme_minimal() +
  ylab("Ratio of commuters travelling longer than 45 min in county Wexford")
  

#6
south_east_other <- transport_2011[transport_2011$NUTS_III == 'South-East' & transport_2011$County != 'Wexford',]
df <- as.data.frame(c(sum(colSums(south_east_other[c(36:37)]))/colSums(south_east_other[40]),
                      1-sum(colSums(south_east_other[c(36:37)]))/colSums(south_east_other[40])))
names(df)[1] <- 'ratio'

ggplot(data = df, aes(x=" " , y=df$ratio, fill=c('longer than 45 min','total'))) +
  geom_bar(stat="identity") +
  coord_polar("y", start=0) +
  geom_text(aes(y = df$ratio + c(0, cumsum(df$ratio)[-length(df$ratio)]), 
                label = percent(df$ratio)), size=5) +
  scale_fill_brewer(palette="Reds")+
  theme_minimal() +
  ylab("Ratio of commuters travelling longer than 45 min in other counties of same NUTS III region")


#7
transport_2011_grouped <- tapply(transport_2011[,38], transport_2011[,6], sum)
transport_2011_grouped
df <- as.data.frame(sort(tail(sort(transport_2011_grouped),5)))
df <- cbind(rownames(df),df)
names(df)[1] <- 'County'
names(df)[2] <- 'CommuteTimes'
df[,2] <- as.integer(df[,2])

p<-ggplot(data = df, aes(x=df$County, y=df$CommuteTimes)) +
  geom_bar(stat="identity", fill = "#CC79A7") +
  geom_text(aes(label=df$County), vjust=2, size=4, color="white")  +
  theme_minimal() +
  xlab("Top 5 Counties with longest commute times") +
  ylab("Commute Times")
p

#8
occurances <- table(transport_2011$Travelby.Car.Driver)
occurances[names(occurances) == 1]/sum(occurances)

df <- as.data.frame(c(occurances[names(occurances) == 1]/sum(occurances),
                      1-occurances[names(occurances) == 1]/sum(occurances)))
names(df)[1] <- 'ratio'

ggplot(data = df, aes(x=" " , y=df$ratio, fill=c('only single person','total'))) +
  geom_bar(stat="identity") +
  coord_polar("y", start=0) +
  geom_text(aes(y = df$ratio + c(0, cumsum(df$ratio)[-length(df$ratio)]), 
                label = percent(df$ratio)), size=5) +
  scale_fill_brewer(palette="Greens")+
  theme_minimal() +
  ylab("Ratio of commuters containing only single person")

#9

agg <- function(df, value) {
  df1 <- tapply(df, transport_2011_wexford$Electoral.Division.Name, sum)
  dfmin <- as.data.frame(head(sort(df1[!is.na(df1)]),1))
  dfmax <- as.data.frame(tail(sort(df1[!is.na(df1)]),1))
  names(dfmin)[1] <- 'min_max'
  names(dfmax)[1] <- 'min_max'
  df2 <- rbind.data.frame(dfmin,dfmax)
  dft <- as.data.frame(c(rep(value,2)))
  names(dft)[1] <- 'type'
  dft <- cbind.data.frame(df2,dft)
  dft <- cbind(rownames(dft),dft)
  names(dft)[1] <- 'Areas'
  return(dft)
}

t1 <- agg(transport_2011_wexford$Travelby.Public.Transport.Comb,'travelby_public')
t2 <- agg(transport_2011_wexford$Travelby.Private.Transport.Comb, 'travelby_private')
t3 <- agg(transport_2011_wexford$Travelby.Soft.Modes.Comb, 'travelby_soft')
l1 <- agg(transport_2011_wexford$Leaving.Before.0630, 'leaving_before_6_30')
l2 <- agg(transport_2011_wexford$Leaving.0801.0830, 'leaving_8_to_8_30')
l3 <- agg(transport_2011_wexford$Leaving.After.0930, 'leaving_after_9_30')
j1 <- agg(transport_2011_wexford$Journey.Under.15.mins, 'journey_under_15min')
j2 <- agg(transport_2011_wexford$Journey.Three.Quarter.Hours.To.Under.One.Hour, 'journey_45min_to_1hr')
j3 <- agg(transport_2011_wexford$Journey.One.And.Half.Hours.And.Over, 'journey_over_1.5hr')

t <- rbind.data.frame(t1,t2,t3)

ggplot(data = t, aes(fill=t$type, y=t$min_max, x=t$Areas)) + 
  geom_bar(position="dodge", stat="identity") +
  geom_text(aes(label=t$Areas), vjust=-1, size=3.5)  +
  scale_fill_viridis(discrete = T, option = "B") +
  ggtitle("Min and Max for Travel Modes") +
  facet_wrap(~t$type) +
  theme_classic() +
  xlab("Areas") +
  ylab("Min and Max Values")

l <- rbind.data.frame(l1,l2,l3)

ggplot(data = l, aes(fill=l$type, y=l$min_max, x=l$Areas)) + 
  geom_bar(position="dodge", stat="identity") +
  geom_text(aes(label=l$Areas), vjust=-1, size=3.5)  +
  scale_fill_viridis(discrete = T, option = "C") +
  ggtitle("Min and Max for Leaving Time") +
  facet_wrap(~l$type) +
  theme_classic() +
  xlab("Areas") +
  ylab("Min and Max Values")

j <- rbind.data.frame(j1,j2,j3)

ggplot(data = j, aes(fill=j$type, y=j$min_max, x=j$Areas)) + 
  geom_bar(position="dodge", stat="identity") +
  geom_text(aes(label=j$Areas), vjust=-1, size=3.5)  +
  scale_fill_viridis(discrete = T, option = "D") +
  ggtitle("Min and Max for Journey Time") +
  facet_wrap(~j$type) +
  theme_classic() +
  xlab("Areas") +
  ylab("Min and Max Values")

#10

class(transport_2011$Planning.Region)

for (i in 1:ncol (transport_2011)) if (class (transport_2011[,i]) == "factor") transport_2011[,i] <- as.character(transport_2011[,i])
class(transport_2011$Planning.Region)

transport_2011$Planning.Region[18450:18458] <- "Eastern and Midlands"
transport_2011$Planning.Region[18450:18458]
transport_2011$Planning.Region[transport_2011$Planning.Region == 'South'] <- "Southern"

southern <- filter(transport_2011, Planning.Region == 'Southern')
east_mid <- filter(transport_2011, Planning.Region == 'Eastern and Midlands')
north_west <- filter(transport_2011, Planning.Region == 'North and West')

southern_bymean <- tapply(southern$Travelby.Public.Transport.Comb, southern$Electoral.Division.Name, mean)
res1 <- head(sort(southern_bymean, decreasing = TRUE),1)

east_mid_bymean <- tapply(east_mid$Travelby.Public.Transport.Comb, east_mid$Electoral.Division.Name, mean)
res2 <- head(sort(east_mid_bymean, decreasing = TRUE),1)

north_west_bymean <- tapply(north_west$Travelby.Public.Transport.Comb, north_west$Electoral.Division.Name, mean)
res3 <- head(sort(north_west_bymean, decreasing = TRUE),1)

df <- as.data.frame(c(res1,res2,res3))
df <- cbind(rownames(df),df)
names(df)[1] <- 'Electoral_Division'
names(df)[2] <- 'Public_Transportation'
df[,2] <- as.integer(df[,2])

p<-ggplot(data = df, aes(x=df$Electoral_Division, y=df$Public_Transportation)) +
  geom_bar(stat="identity", fill = "#D16103") +
  geom_text(aes(label=df$Electoral_Division), vjust=2, size=4.5, color="white")  +
  theme_minimal() +
  xlab("Electoral Divisions in Southern, Eastern and Midlands, and North and West respectively") +
  ylab("Total Public Transportation Counts")
p

