# Load packages ----------------------------------------------------------------

library(shiny)
streamData <- read.csv('parsedData/streamgraph.csv')

# install.packages("remotes")
# remotes::install_github("davidsjoberg/ggstream")
library(ggstream)
# install.packages("ggplot2")
library(ggplot2)
library(plotly)

#install.packages("xlsx")
#library(xlsx)

#install.packages("readxl")
library(readxl)

stream <- ggplot(streamData, aes(x = Agebins, y = count, fill = Cause.of.Death))+
  geom_stream(type = "proportional", color=1, lwd=0.1) +
  xlab("Age") +
  ylab("Proportion of deaths")+
  ggtitle('Proportion of Death Causes by Age')

finalStream <- ggplotly(stream)
cdcData <- read.csv('parsedData/cleaned.csv')


df_t <- read_excel("NationalUS.xlsx", sheet = "Tuberculosis" )
df_h <- read_excel("NationalUS.xlsx", sheet = "HIV AIDS" )
df_d <-  read_excel("NationalUS.xlsx", sheet = "Diarrheal diseases" )
df_r <- read_excel("NationalUS.xlsx", sheet = "Lower respiratory infections")
df_m <-  read_excel("NationalUS.xlsx", sheet = "Meningitis" )
df_hp <-  read_excel("NationalUS.xlsx", sheet = "Hepatitis" )

tub_data <- filter(df_t, FIPS < 100)
hiv_data <- filter(df_h, FIPS < 100)
diar_data <- filter(df_d, FIPS < 100)
resp_data <- filter(df_r, FIPS < 100)
men_data <- filter(df_m, FIPS < 100)
hep_data <- filter(df_hp, FIPS < 100)


code <- df_t$code[1:50]
tub_data$code <- code
hiv_data$code <-code
diar_data$code <- code
resp_data$code <- code
men_data$code <-code
hep_data$code <- code

tub_data$hover <-with(tub_data,paste(Location,'<br>',"Mortality_rate",tub_data$MR_1985))
hiv_data$hover <-with(hiv_data,paste(Location,'<br>',"Mortality_rate",hiv_data$MR_1985))
diar_data$hover <-with(diar_data,paste(Location,'<br>',"Mortality_rate",diar_data$MR_1985))

resp_data$hover <-with(resp_data,paste(Location,'<br>',"Mortality_rate",resp_data$MR_1985))
men_data$hover <-with(men_data,paste(Location,'<br>',"Mortality_rate",men_data$MR_1985))
hep_data$hover <-with(hep_data,paste(Location,'<br>',"Mortality_rate",hep_data$MR_1985))



library(viridis)
educationfilterOptions <- c("No Filter", unique(cdcData$Education) )
sexfilterOptions <- c("No Filter", unique(cdcData$Sex))
occupationfilterOptions <- c("No Filter", unique(cdcData$Usual.Occupation))
diseasefilterOptions <- c("Tuberculosis","HIV AIDS", "Hepatitis", "Meningitis", "Diarrheal diseases", "Lower respiratory infections")



ui <- fluidPage(
  h2("Introduction"),
  p("In this project, we are looking at data sets from CDC(Center for Disease Control and Prevention) for COVID and a data set from IHME, Institute of Health Metrics and Exchange, an independent Global Health Research center for infectious diseases. Both data sets contain information about the mortality related to different counties and regions in the United States in the last few years and some additional attributes such as gender, few types of infectious diseases, age, occupation, education. With this information there is plenty of different opportunities for engaging and informative visualizations such as cumulative bar graphs for showing loss of years due to preventable disease, economic predictions based on current resource demand for population growth, impacts of the different diseases, choropleth maps showing potential geological factors, and finally a stream graph showing deaths by different causes and how those are affected by age groups.
"),
  p("The primary motivation for this project is to understand what happens within each year in the context of death in the United States. These highlighted questions and answers could be used in the future to help guide policy making, and generally inform the public as to what happens to individual people. In particular, a goal of these graphs would be to help others understand these statistics as not just numbers, but real people with real families who die over the year. In each of their individual deaths, there is an impact both emotionally and economically to the people around them and long term as demonstrated later"),
  h3("In the wake of the covid pandemic what was the real comparison between covid deaths and deaths from other diseases with control for education, sex, or usual occupation?
"),
  fluidRow(
    column(3,
      selectizeInput("educationFilter", "Select Education Filter", educationfilterOptions)
    ),
    column(3,
      selectizeInput("sexFilter", "Select Sex Filter", sexfilterOptions)
    ),
    column(3,
      selectizeInput("occupationFilter", "Select Occupation Filter", occupationfilterOptions)
    )
  ),
  plotlyOutput("Bar"),
  h3("Across age groups how does death by different causes change?
     "),
  plotlyOutput("Stream"),
  h3("If we could stop preventable diseases and their deaths in 2020, how would it have affected the population, in terms of years lost?
"),
  plotlyOutput("Death"),
  h3("If we stopped preventable disease/death in 2020, how would it affect GDP?
"),
  plotlyOutput("GDP"),
  h3("Across the US States how the mortality rate prevailed with different infectious diseases
"),
  selectInput("diseaseFilter", "Select Disease for MR", diseasefilterOptions),
  plotlyOutput("Chloropleth"),
  h2("Discussion and Future Work"),
  p("Our project focuses on understanding what happens within each year in the context of death in the United States and the impact they can have. Our first question answered how the distribution of deaths changed with sex, level of education and occupation as well as what impact the COVID-19 pandemic in terms of death as compared to other diseases. Moreover, using the streamgraph we dived into how the distribution changes for individual age groups for different diseases. A potential future work can be to add filters for top X number (Say 10) of diseases and try to find connections when factors like age, sex and occupation changes. We restricted our study for the United States and could be extended to developing countries which could potentially offer more insights into the problem and help us study the effects of economical and social factors. We analyzed the lost year and lost death while considering deaths from the year 2020 only, and it can be extended to include multiple years in future works.")
  
)

server <- function(input, output, session) {
  
  filteredDf <- reactive({
    filteredDfOut <- cdcData
    if(input$educationFilter != "No Filter"){
      filteredDfOut <- filter(filteredDfOut, Education == input$educationFilter)
    }
    if(input$sexFilter != "No Filter"){
      filteredDfOut <- filter(filteredDfOut, Sex == input$sexFilter)
    }
    if(input$occupationFilter != "No Filter"){
      filteredDfOut <- filter(filteredDfOut, Usual.Occupation == input$occupationFilter)
    }
    filteredDfOut
  })
  
  output$Bar <- renderPlotly({
    req(filteredDf())
    tempPlot <- ggplot(data=filteredDf(), aes(x=Cause.of.Death))+
          geom_bar(color='black') +
          xlab('Cause of Death')+
          ylab('Count')+
          ggtitle('Education, Sex, Occupation, and Their Effect on Distribution of Disease Death')
    p <- ggplotly(tempPlot)
    p
  })
  
  output$Stream<- renderPlotly({
    finalStream
  })
  
  output$Death <- renderPlotly({
    data <- read.csv("ActualVsPredictedDeath.csv")
    
    # Create data
    age <- seq(1,116)
    death_actual <- data$count
    death_predicted <- data$death_predicted
    
    # Area chart with 2 groups
    p <- plot_ly(x = age, y = death_actual, type="scatter", mode = 'lines' , fill = "tozeroy", name = 'Actual Deaths')
    p <- add_trace(p, x = age, y = death_predicted, type="scatter", mode = 'lines', fill = "tonexty", name = 'Predicted Deaths')
    p <- p %>% layout(
      title = "Actual Deaths Vs Predicted Deaths",
      xaxis = list(
        title = "Age",
        rangeslider = list(
          title = "Age"
        )
      ),
      yaxis = list(
        title = "No. of Deaths",
        zeroline = F
      )
    )
    p
  })
  
  output$GDP <- renderPlotly({
    gdp_lost = c(33147078798.142864,
                 33801899421.011272,
                 34463813263.80624,
                 35195345150.10931,
                 33431044029.661495,
                 31706851403.015396,
                 30089985325.662487,
                 28536031368.330685,
                 27050435525.230225,
                 25683497799.11665)
    
    gdp_lost_comm = c(33147078798.142864,
                      66948978219.15414,
                      101412791482.96037,
                      136608136633.06967,
                      170039180662.73117,
                      201746032065.74658,
                      231836017391.40906,
                      260372048759.73975,
                      287422484284.97,
                      313105982084.0866)
    year = c(2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029)
    
    fig <- plot_ly(
      x = c(2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029),
      y = gdp_lost,
      name = "Lost GDP",
      type = "bar"
    )
    
    ay <- list(
      tickfont = list(color = "red"),
      overlaying = "y",
      side = "right",
      title = "Commumlative Lost GDP")
    
    fig <- fig %>% add_trace(x = year, y = gdp_lost_comm, name = "Commulative Lost GDP", yaxis = "y2", mode = "lines+markers", type = "scatter")
    
    fig <- fig %>% layout(
      title = "Lost GPD", yaxis2 = ay,
      xaxis = list(title="Year"),
      yaxis = list(title="Lost GDP")
    )%>%
      layout(plot_bgcolor='#e5ecf6',
             xaxis = list(
               zerolinecolor = '#ffff',
               zerolinewidth = 2,
               gridcolor = 'ffff'),
             yaxis = list(
               zerolinecolor = '#ffff',
               zerolinewidth = 2,
               gridcolor = 'ffff')
      )
    
    fig
  })
  
  
  filteredChloropleth <- reactive({
    filteredDfOut <- tub_data
    if(input$diseaseFilter == "Tuberculosis"){
      filteredDfOut <- tub_data
    }
    if(input$diseaseFilter == "HIV AIDS"){
      filteredDfOut <- hiv_data
    }
    if(input$diseaseFilter == "Hepatitis"){
      filteredDfOut <- hep_data
    }
    if(input$diseaseFilter == "Meningitis"){
      filteredDfOut <- men_data
    }
    if(input$diseaseFilter == "Diarrheal diseases"){
      filteredDfOut <- diar_data
    }
    if(input$diseaseFilter == "Lower respiratory infections"){
      filteredDfOut <- resp_data
    }
    filteredDfOut
  })
  
  
  output$Chloropleth <- renderPlotly({
    req(filteredChloropleth())
    
    
    #filteredDf <- tub_data
    
    # specify some map projection/options
    
    g <- list(
      
      scope = 'usa',
      
      projection = list(type = 'albers usa'),
      
      showlakes = TRUE
      
    )
    
    
    fig <- plot_geo(filteredChloropleth(), locationmode = 'USA-states')
    
    
    
    fig <- fig %>% add_trace(
      
      z = ~filteredChloropleth()$MR_1985, text = ~filteredChloropleth()$hover, locations = ~code,
      
      color = ~filteredChloropleth()$MR_1985, colors = 'Purples'
      
    )
    
    
    fig <- fig %>% colorbar(title = "Mortality Rates")
    
    fig <- fig %>% layout(
      
      geo = g,
      
      title = '1985 US Disease Mortality by State<br>(Hover for breakdown)'
      
    )
    
    
    
    fig
    
  })
  
  

}

shinyApp(ui = ui, server = server)
