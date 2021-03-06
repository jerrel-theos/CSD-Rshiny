# Shiny Dashboard (No SQL). 
# Written by : Jerrel Audric Theos
# Department of Business statistics, Matana University (Tangerang)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(shiny)
library(shinydashboard)
library(dplyr)
library(readxl)
library(plotly)
library(rworldmap)

# Import the data
requests <- read_xlsx("SampleDataSet_CallCenter_Dash.xlsx", sheet = "Requests")
survey <- read_xlsx("SampleDataSet_CallCenter_Dash.xlsx", sheet = "Survey")


# Define UI for application that draws a histogram
ui <- dashboardPage(skin = "purple",
                    # header
                    dashboardHeader(
                        title = "Jerrel Audric Theos",
                        tags$li(class = "dropdown",
                                style = "margin-top: 7px; margin-right: 5px;",
                                actionButton(icon = icon("question"), "help", "", title = "Start a tour of the dashboard"),
                                dropdownMenuOutput("msgOutput")),
                        dropdownMenu(type = "message",
                                     messageItem(from = "Latest Year", message = "Total caller this year"))
                    ),
                    
                    # sidebar
                    dashboardSidebar(
                        sidebarSearchForm("searchText","buttonSearch","Search"),
                        sidebarMenu(
                            menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
                            menuItem("Customer Map", tabName = "map", icon = icon("map")),
                            menuItem("Filter", icon = icon("filter"), startExpanded = FALSE,
                                     radioButtons("center", "Filter by Support Center", 
                                                  list("Combined", "Support Center A", "Support Center B", "Support Center C", "Support Center D"))),
                            menuItem("Data Download", icon = icon("download",lib='glyphicon'), href = "https://github.com/jerrel-theos/CSD-Rshiny/raw/master/SampleDataSet_CallCenter_Dash.xlsx"),
                            menuItem("App Source Code", icon = icon("code"), href = "https://github.com/jerrel-theos/CSD-Rshiny")
                        )
                    ),
                    
                    # body
                    dashboardBody(
                        
                        tabItems(
                            tabItem(tabName = "dashboard",
                                    # link custom javascript
                                    tags$head(tags$script(src="myscript.js")),
                                    # link custom css, intro.css and c3.css
                                    tags$head(
                                        tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
                                        tags$link(rel = "stylesheet", type = "text/css", href = "https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/introjs.css"),
                                        tags$link(rel = "stylesheet", type = "text/css", href = "https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.1/c3.min.css")
                                    ),
                                    # link intro.js, d3.js and c3.js
                                    tags$head(tags$script(src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js")),
                                    tags$head(tags$script(src="https://cdnjs.cloudflare.com/ajax/libs/d3/5.9.2/d3.min.js")),
                                    tags$head(tags$script(src="https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.1/c3.min.js")),
                                    # row one
                                    frow1 <- fixedRow(
                                        valueBoxOutput("value1", width = 3),
                                        valueBoxOutput("value2", width = 3),
                                        valueBoxOutput("value3", width = 3),
                                        valueBoxOutput("value4", width = 3)
                                    ),
                                    
                                    # row 2
                                    frow2 <- fluidRow( 
                                        box(
                                            title = "Major Issues"
                                            ,id = "box1"
                                            ,status = "primary"
                                            ,solidHeader = FALSE 
                                            ,collapsible = TRUE 
                                            ,plotlyOutput("bar", height = "300px")
                                        )
                                        ,box(
                                            title = "Channel Types"
                                            ,id = "box2"
                                            ,status = "primary"
                                            ,solidHeader = FALSE 
                                            ,collapsible = TRUE 
                                            ,plotlyOutput("pie", height = "300px")
                                        )
                                    ),
                                    
                                    #row 3
                                    frow3 <- fluidRow(
                                        box(
                                            title = "Demand",
                                            id = "box3",
                                            status = "primary",
                                            solidHeader = FALSE,
                                            collapsible = TRUE,
                                            width = 12,
                                            plotlyOutput("line", height = "300px")
                                        )
                                    )
                            ),
                            
                            # map tab
                            tabItem(tabName = "map",
                                    frow4 <- fluidRow(
                                        box(
                                            title = "Customer Issues by Location",
                                            id = "box4",
                                            status = "primary",
                                            solidHeader = TRUE,
                                            width = 12,
                                            plotOutput("map", height = "750px")
                                        )
                                    )
                            )
                        )
                        
                        
                    )
)


# Define server logic required to draw a histogram
server <- function(input, output, session) {
    
    # average product quality
    product_quality <- as.numeric(c(survey$`ProductQuality 9pt act`))
    product_score <- round(mean(na.rm = TRUE, product_quality), 2)
    
    # overall satisfaction
    satisfaction_quality <- as.numeric(c(survey$`QualityOfSupport 9pt act`))
    satisfaction_score <- round(mean(na.rm = TRUE, satisfaction_quality), 2)
    
    # subset issue codes data as factor
    requests$`Issue Code 1` <- as.factor(requests$`Issue Code 1`)
    
    # KPI boxes
    # average time to close
    output$value1 <- renderValueBox({
        if (input$center == "Combined") {
            time <- requests
        } else {
            time <- requests %>% filter(requests$`Vendor - Site` == input$center)
        }
        time_to_close <- c(time$`Time To Close`)
        avg_time_to_close <- round(mean(na.rm = TRUE, time_to_close), 2)
        valueBox(
            avg_time_to_close
            ,paste('Time to Close', '(Hours)')
            ,icon = icon("time",lib='glyphicon')
            ,color = "purple")  
    })
    
    # average monthly requests 2015 (previous year)
    output$value2 <- renderValueBox({ 
        if (input$center == "Combined") {
            ly_requests <- filter(requests, Year == 2015)
        } else {
            ly_requests <- filter(requests, Year == 2015)
            ly_requests <- ly_requests %>% filter(ly_requests$`Vendor - Site` == input$center)
        }
        avg_monthly_requests <- round(count(ly_requests) / 12)
        valueBox(
            avg_monthly_requests
            ,'Monthly Service Requests'
            ,icon = icon("signal",lib='glyphicon')
            ,color = "purple")  
    })
    
    # product quality
    output$value3 <- renderValueBox({
        valueBox(
            product_score
            ,paste('Product Quality (1-9)')
            ,icon = icon("laptop")
            ,color = "yellow")   
    })
    
    # overall satisfaction
    output$value4 <- renderValueBox({
        valueBox(
            satisfaction_score,
            paste("Overall Satisfaction (1-9)"),
            icon = icon("thumbs-up", lib = "glyphicon"),
            color = "yellow"
        )
    })
    
    # customer channel types plot
    output$pie <- renderPlotly({
        if (input$center == "Combined") {
            channel <- requests
        } else {
            channel <- requests %>% filter(requests$`Vendor - Site` == input$center)
        }
        channel <- channel %>% group_by(channel$`Support Channel`) %>% tally
        channel <- channel %>%
            rename(
                channel = "channel$\`Support Channel\`"
            )
        channel <- channel[1:3, ]
        
        plot_ly(
            requests, 
            labels = channel$channel,
            values = channel$n, 
            type='pie'
        )
    })
    
    # time series analysis - single chart setup
    output$line2 <- renderPlotly({
        plot_ly(demand, x = demand$`demand$date`, y = demand$n, type = 'scatter', mode = 'lines')
    })
    
    # demand vs speed of closure - multi chart setup - count daily service requests and avg time to close
    output$line <- renderPlotly({
        if (input$center == "Combined") {
            demand <- requests
        } else {
            demand <- requests %>% filter(requests$`Vendor - Site` == input$center)
        }
        
        demand <- data_frame(date = demand$`Ticket Close Date`, id = demand$`Service Request Id`, time = demand$`Time To Close`)
        time_to_close <- aggregate(demand["time"], by=demand["date"], mean)
        demand <- demand %>% group_by(demand$date) %>% tally
        
        plot_ly() %>%
            add_bars(x = demand$`demand$date`, y = demand$n, name = "Tickets") %>%
            add_lines(x = time_to_close$date, y = time_to_close$time, name = "Hours", yaxis = "y2") %>%
            layout(
                yaxis = list(side = 'left', title = 'Tickets', showgrid = FALSE, zeroline = FALSE),
                yaxis2 = list(side = 'right', overlaying = "y", title = 'Time', showgrid = FALSE, zeroline = FALSE)
            )
    })
    
    # top issues plot
    output$bar <- renderPlotly({
        if (input$center == "Combined") {
            issues <- requests
        } else {
            issues <- requests %>% filter(requests$`Vendor - Site` == input$center)
        }
        
        # count data using group by
        issues <- issues %>% group_by(issues$`Issue Code 1`) %>% tally
        
        # select top 10
        issues <- issues %>% top_n(10, n)
        
        # rename bar chart column
        issues <- issues %>%
            rename(
                issues = "issues$\`Issue Code 1\`"
            )
        
        # example of creating and sending JSON object to the browser
        # issues_json <- toJSON(issues)
        # session$sendCustomMessage("issues", issues_json)
        plot_ly(
            # factor() again to drop the levels that are null - 29 to 10
            data = issues,
            y = factor(issues$issues),
            x = issues$n,
            name = "Major Issues",
            type = "bar",orientation = "h")})
    
    # world map plot
    output$map <- renderPlot({
        # create country frequency table, match then output map plot
        if (input$center == "Combined") {countries <- requests} 
        else {countries <- requests %>% filter(requests$`Vendor - Site` == input$center)}
        countries <- as.data.frame(table(countries$`Customer Country/Region`))
        colnames(countries) <- c("country", "value")
        matched <- joinCountryData2Map(countries, joinCode = "NAME", nameJoinColumn = "country")
        mapCountryData(matched, nameColumnToPlot = "value", mapTitle = "", 
                       catMethod = "pretty", colourPalette = c("lightblue", "darkblue"))
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
