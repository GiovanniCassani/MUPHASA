args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 3) {
    setwd(args[3])
}


source("CHVintersect.R")

results = CHVintersect(args[1], args[2])

vertices.int = results[3][[1]]
vol.int = results[4][[1]][3][[1]]

write.table(vertices.int, "vertices.csv", sep = ',', row.names = FALSE, col.names = FALSE)
write.table(vol.int, "volume.csv", sep = ',', row.names = FALSE, col.names = FALSE)
