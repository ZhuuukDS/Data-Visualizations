library(plotly)
library(ggplot2)

df <- read.csv("rfm.csv")

fig <- plot_ly(df, 
               x = ~recency, 
               y = ~monetary, 
               z = ~frequency,
               color = ~rfm_segment_name,
               colors = c("#04a3bd","#f0be3d",
                          "#931e18","#da7901",
                          "#247d3f"),
               type = 'scatter3d',
               mode = "markers",
               marker = list(
                            size = 4,
                            line = list(color='',
                                        width=1)
                            )
               )


fig <- fig %>% layout(title = 'Customers Segmentation',
                      scene = list(xaxis = list(title = 'recency'),
                                   yaxis = list(title = 'monetary'),
                                   zaxis = list(title = 'frequency')),
                      legend = list(itemsizing='constant')
                      )

fig

p = ggplotly(fig)

p





