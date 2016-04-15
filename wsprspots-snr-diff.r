library(scales)
library(ggplot2)
library(gridExtra)
library(data.table)
library(RColorBrewer)

args <- commandArgs(trailingOnly = TRUE)

file1 <- args[1]
file2 <- args[2]
file3 <- args[3]
call <- args[4]
date1 <- args[5]
date2 <- args[6]

# file1 <- 'wsprspots-2016-04-SWLJO20.csv'
# file2 <- 'wsprspots-2016-04-PI4THT.csv'
# file3 <- 'wsprspots-2016-04-snr-diff-SWLJO20.png'
# call <- 'SWLJO20'
# date1 <- '2016-04-01'
# date2 <- '2016-12-31'

colNames <- c('id', 'epoch', 'rcall',
  'rgrid', 'snr', 'freq', 'call',
  'grid', 'power', 'drift', 'distance',
  'azimuth', 'band', 'version', 'code')
colClasses <- c('numeric', 'numeric', 'character',
  'character', 'numeric', 'numeric', 'character',
  'character', 'numeric', 'numeric', 'numeric',
  'numeric', 'numeric', 'character', 'numeric')

spots1 <- as.data.table(read.table(file1, header = F, sep = ',', col.names = colNames, colClasses = colClasses))
spots2 <- as.data.table(read.table(file2, header = F, sep = ',', col.names = colNames, colClasses = colClasses))

spots1[, time := as.POSIXct(epoch, origin = '1970-01-01')]
spots2[, time := as.POSIXct(epoch, origin = '1970-01-01')]

freqs <- c(0, 1, 3, 5, 7, 10, 14, 18, 21, 24, 28, 50)
bands <- c('MF', '160m', '80m', '60m', '40m', '30m', '20m', '17m', '15m', '12m', '10m', '6m')

proc1 <- function(x){
  x[
    ,
    list(
      diff = mean(as.numeric(snr.x) - as.numeric(snr.y))
    ),
    list(
      mday = mday(time),
      band
    )
  ]
}

spots <- merge(spots1, spots2, by = c('time', 'band', 'call'))

diff <- proc1(spots)
# diff[, time := as.POSIXct(paste0('2016/04/', mday, ' ', hour, ':00:00'))]
diff[, time := as.POSIXct(paste0('2016/04/', mday, ' 12:00:00'))]

subset <- diff[time >= as.POSIXct(paste0(date1, ' 00:00:00')) & time <= as.POSIXct(paste0(date2, ' 23:59:59'))]

p <- lapply(2:7, function(i)
  ggplot(data = subset[band == freqs[i]], aes(x = time, y = diff)) +
    geom_point() + scale_color_hue() +
    scale_x_datetime(breaks = date_breaks('1 day'), minor_breaks = date_breaks('1 hour')) +
    theme(axis.text.x = element_text(angle = 45)) +
    labs(title = bands[i]) + labs(x = '', y = 'average SNR difference') +
    theme(legend.position = 'none') + coord_cartesian(ylim = c(-20.0, 10.0))
)

png(file3, width = 1200, height = 600, res = 90)
grid.arrange(arrangeGrob(grobs = p, nrow = 2))
dev.off()
