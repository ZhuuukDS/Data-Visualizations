library(sf)
library(tigris)
library(tidyverse)
library(stars)
library(rgl)
library(rayshader)
library(colorspace)
library(magick)
library(glue)
library(stringr)


# load kontur data
data <- st_read('kontur_population_IL_20220630.gpkg')

data |>
  ggplot() +
  geom_sf()


bb <- st_bbox(data)


# boundaries
bottom_left <- st_point(c(bb[["xmin"]], bb[["ymin"]])) |> 
  st_sfc(crs = st_crs(data))

bottom_right <- st_point(c(bb[["xmax"]], bb[["ymin"]])) |> 
  st_sfc(crs = st_crs(data))

top_left <- st_point(c(bb[["xmin"]], bb[["ymax"]])) |> 
  st_sfc(crs = st_crs(data))

width <- st_distance(bottom_left, bottom_right)

height <- st_distance(bottom_left, top_left)

# plot the boundaries
data |> 
  ggplot() +
  geom_sf() +
  geom_sf(data = bottom_left, color = 'green') +
  geom_sf(data = bottom_right, color = "red") + 
  geom_sf(data = top_left, color = "blue")


# aspect ratio
if (width > height) {
  w_ratio <- 1
  h_ratio <- as.vector(height / width)
} else {
  h_ratio <- 1
  w_ratio <- as.vector(width / height)
}

# convert to raster
size <- 4000 # arbitrary
size_x <- floor(w_ratio * size)
size_y <- floor(h_ratio * size)

rast <- st_rasterize(data, nx = size_x, ny = size_y)

# convert to matrix
mat <- matrix(rast$population, nrow = size_x, ncol = size_y)

# color palette
c1 <- c("#ebc174","#bad6f9", "#7db0ea", '#005EB8', '#133e7e')
swatchplot(c1)

texture <- grDevices::colorRampPalette(c1, bias = 2.2)(256)
swatchplot(texture)


# closing rgl window
rgl::rgl.close()

# plot 3d map
mat |> 
  height_shade(texture = texture) |> 
  plot_3d(heightmap = mat,
          zscale = 150/(size/1000),
          solid=FALSE,
          soliddepth=0,
          shadowdepth = 0)

# changing the view, angle, zoom 
render_camera(theta = -60, 
              phi = 40, 
              zoom = 0.85)

# making snapshot
render_snapshot()

# name for the rendered map file
outfile <- "final_plot.png"

# rendering the picture
{
  start_time <- Sys.time()
  cat(crayon::cyan(start_time), "\n")
  if (!file.exists(outfile)) {
    png::writePNG(matrix(1), target = outfile)
  }
  render_highquality(
    filename = outfile,
    interactive = FALSE,
    lightdirection = 230, 
    lightaltitude = c(30, 80), 
    lightcolor = c("#d29c44", "white"),
    lightintensity = c(600, 250),
    samples = 450,
    width = 4000,
    height = 3000
  )
  end_time <- Sys.time()
  diff <- end_time - start_time
  cat(crayon::cyan(diff), "\n")
}



# making title and annotations

img <- image_read('final_plot.png')

text_color <- darken('#133e7e', 0.2)
swatchplot('#133e7e',text_color)

text_font = 'Georgia' #'Papyrus' # 'Hoefler Text'

annot <- glue('This map displays the population density. ',
              'Each bar is the 400 meter hexagon, whose ',
              'height represents the number of inhabitants.') |>
  str_wrap(35) # 46

# add title, text and save to final file
img |>
  image_crop(gravity = 'east',
             geometry_area(3700, 2500)) |>
  image_crop(gravity = 'west',
             geometry_area(3600, 2500)) |>
  image_crop(gravity = 'north',
             geometry_area(3600, 2300)) |>
  image_annotate('The State of Israel Population Density',
                 gravity = 'north',
                 location = '+350+100',
                 size = 150,
                 color =text_color,
                 font = text_font) |> # Papyrus
  image_annotate(annot,
                 gravity = 'east',
                 location = '+270-210', #+15-70
                 color =text_color,
                 font = text_font,
                 size = 80) |>
  image_annotate('Data: Kontur Population (Released 2022/06/30)',
                 gravity = 'southwest',
                 location =  '+80+50',
                 font = text_font,
                 size = 50,
                 color = alpha(text_color, .5)) |>
  image_annotate('Visualization: Alex Zhukov (@zhuuukds)',
                 gravity = 'southeast',
                 location = '+80+50',
                 font = text_font,
                 color = alpha(text_color, .5),
                 size = 50) |>
  image_write('titled_plot.png')


