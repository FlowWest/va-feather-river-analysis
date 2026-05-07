library(shiny)
library(bslib)
library(tidyverse)
library(glmmTMB)
library(pROC)
library(broom.mixed)
library(leaflet)
library(sf)
library(scales)
library(DT)
library(cowplot)
library(patchwork)


# ── shared helpers ────────────────────────────────────────────────────────────
custom_colors  <- c("#E69F00","#56B4E9","#009E73","#F0E442","#0072B2","#D55E00","#CC79A7")
channel_colors <- c(HFC = "#899DA4", LFC = "#02401B")
percent_threshold <- 20

metrics_from_cm <- function(cm, model_name, auc_val) {
  TN <- cm["0","0"]; FN <- cm["0","1"]
  FP <- cm["1","0"]; TP <- cm["1","1"]
  n  <- TN + FN + FP + TP
  po <- (TP + TN) / n
  pe <- ((TP+FP)*(TP+FN) + (TN+FN)*(TN+FP)) / n^2
  tibble(
    Model = model_name, N = n,
    TP=TP, FP=FP, TN=TN, FN=FN,
    Accuracy    = (TP+TN)/n,
    Sensitivity = TP/(TP+FN),
    Specificity = TN/(TN+FP),
    Precision   = TP/(TP+FP),
    NPV         = TN/(TN+FN),
    `Bal. Acc.` = ((TP/(TP+FN))+(TN/(TN+FP)))/2,
    Kappa       = (po-pe)/(1-pe),
    Prevalence  = (TP+FN)/n,
    AUC         = auc_val
  ) |> mutate(across(where(is.numeric), \(x) round(x,3)))
}

mini_locations_raw     <- read_csv("mini_locations_raw.csv",  show_col_types=FALSE)
mini_fish_raw          <- read_csv("mini_fish_raw.csv",       show_col_types=FALSE)
steelhead_redd_summary <- read_rds("steelhead_redd_summary.rds")
chinook_redd_summary   <- read_rds("chinook_redd_summary.rds")
raw_chinook_redds      <- read_rds("raw_redd_location_chinook.rds")   |> sf::st_cast("POINT")
raw_steelhead_redds    <- read_rds("raw_redd_location_steelhead.rds") |> sf::st_cast("POINT")

prepare_species_data <- function(species_choice) {
  redd_summary <- if (species_choice=="chinook salmon") chinook_redd_summary else steelhead_redd_summary
  raw <- mini_fish_raw |>
    left_join(mini_locations_raw |> distinct()) |>
    mutate(
      count         = ifelse(is.na(count),0,count),
      fish_presence = as.factor(ifelse(count<1,"0","1")),
      month         = lubridate::month(date)
    ) |>
    filter(
      if (species_choice=="chinook salmon")
        species=="chinook salmon" | count==0
      else
        species %in% c("steelhead trout (wild)","steelhead trout (clipped)") | count==0
    )
  model_data <- raw |>
    select(count, location, channel_location, depth, velocity,
           contains("inchannel"), contains("overhead"),
           percent_cobble_substrate, percent_boulder_substrate,
           percent_undercut_bank, month, fl_mm,
           channel_geomorphic_unit, reach_length, reach_width, channel_type,
           any_of("surface_turbidity")) |>
    mutate(
      small_woody       = percent_small_woody_cover_inchannel,
      large_woody       = percent_large_woody_cover_inchannel,
      boulder_substrate = percent_boulder_substrate,
      cobble_substrate  = percent_cobble_substrate,
      undercut_bank     = percent_undercut_bank,
      aquatic_veg       = percent_submerged_aquatic_veg_inchannel,
      overhanging_veg   = percent_cover_half_meter_overhead + percent_cover_more_than_half_meter_overhead
    ) |>
    mutate(
      across(c(cobble_substrate,boulder_substrate,small_woody,large_woody,
               aquatic_veg,undercut_bank,overhanging_veg),
             \(x) ifelse(x>=percent_threshold,1,0)),
      no_cover_overhead = ifelse(percent_no_cover_overhead>=percent_threshold,1,0)
    ) |>
    select(-contains("no_cover")) |>
    distinct() |>
    mutate(fl_mm=ifelse(is.na(fl_mm),0,fl_mm)) |>
    na.omit() |>
    select(-fl_mm) |>
    left_join(redd_summary, by="location") |>
    mutate(
      redd_total    = replace_na(redd_total,0),
      redd_presence = replace_na(redd_presence,0),
      month         = as.factor(month)
    )
  log_reg_data <- model_data |> mutate(presence=as.integer(count>0))
  list(raw=raw, model_data=model_data, log_reg_data=log_reg_data)
}

build_formula <- function(species_choice, random_effects=NULL) {
  extra  <- if (species_choice=="steelhead trout" && "surface_turbidity" %in% names(mini_fish_raw))
    "+ surface_turbidity" else ""
  re_str <- if (!is.null(random_effects)) paste("+",random_effects) else ""
  as.formula(paste(
    "presence ~ small_woody + depth + velocity + large_woody +",
    "aquatic_veg + overhanging_veg + cobble_substrate +",
    "boulder_substrate + undercut_bank + redd_total + redd_presence",
    extra, re_str
  ))
}

cover_vars_raw <- c(
  "percent_small_woody_cover_inchannel"     = "Small woody",
  "percent_large_woody_cover_inchannel"     = "Large woody",
  "percent_submerged_aquatic_veg_inchannel" = "Aquatic veg",
  "percent_undercut_bank"                   = "Undercut bank",
  "percent_cobble_substrate"                = "Cobble",
  "percent_boulder_substrate"               = "Boulder"
)

term_labels <- c(
  small_woody="Small woody debris", large_woody="Large woody debris",
  overhanging_veg="Overhanging vegetation", aquatic_veg="Aquatic vegetation",
  cobble_substrate="Cobble substrate", boulder_substrate="Boulder substrate",
  undercut_bank="Undercut bank", depth="Depth", velocity="Velocity",
  redd_total="Total redds nearby", redd_presence="Redd present",
  surface_turbidity="Surface turbidity"
)

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- page_navbar(
  title = span(
    style = "font-family: 'Georgia', serif; font-size: 1.05rem; letter-spacing: 0.02em;",
    "Feather River — Logistic Regression Analysis"
  ),
  theme = bs_theme(
    bootswatch   = "flatly",
    base_font    = font_google("Roboto"),
    heading_font = font_google("Roboto"),
    primary      = "black",
    secondary    = "#7294D4",
    success      = "#3A3A3C"
  ),
  bg      = "#9A8822",
  inverse = TRUE,
  fillable = FALSE,
  header = tags$head(tags$style(HTML("
    /* prevent bslib cards from clipping plot content */
    .card { overflow: visible !important; }
    .card-body { overflow: visible !important; }
    .bslib-card { overflow: visible !important; }
    .html-widget, .shiny-plot-output {
      overflow: visible !important;
    }
  "))),
  
  # ── sidebar species selector ──────────────────────────────────────────────
  sidebar = sidebar(
    width = 240,
    bg    = "#f8f9fa",
    # hr(),
    selectInput("species", label = strong("Species"),
                choices  = c("Chinook Salmon" = "chinook salmon",
                             "Steelhead Trout" = "steelhead trout"),
                selected = "chinook salmon"),
    hr(),
    p(
      em(
        "Data: ",
        tags$a("Feather River Mini Snorkel Survey (EDI, 2001–2002)",
               href   = "https://portal.edirepository.org/nis/metadataviewer?packageid=edi.1705.3",
               target = "_blank",
               style  = "color:#666;")
      ),
      style = "font-size:0.8rem; color:#666;"
    ),
    p(em("Model: Mixed-effects logistic regression"),
      style = "font-size:0.8rem;color:#666;"),
    hr(),
    div(style = "font-size:0.8rem; padding:8px; background-color:#e9ecef;
                 border-radius:4px; color:#495057;",
        icon("clock"),
        " Switching species refits all models — allow ~15 seconds.")
  ),
  
  # ══════════════════════════════════════════════════════════════════════════
  # TAB 1 · OVERVIEW
  # ══════════════════════════════════════════════════════════════════════════
  nav_panel("Overview",
            br(),
            navset_card_tab(
              nav_panel("Objective & Approach",
                        card(full_screen = FALSE, uiOutput("overview_objective"))
              ),
              nav_panel("Raw Data Glimpse",
                        card(plotOutput("overview_plot", height = "380px")),
                        br(),
                        card(DTOutput("overview_table"))
              ),
              nav_panel("Variables of Interest",
                        card(uiOutput("overview_vars"))
              )
            )
  ),
  
  # ══════════════════════════════════════════════════════════════════════════
  # TAB 2 · DATA EXPLORATION
  # ══════════════════════════════════════════════════════════════════════════
  nav_panel("Data Exploration",
            br(),
            navset_card_tab(
              nav_panel("HFC / LFC",
                        card(padding = 0, plotOutput("explore_hfc", height = "560px", width = "100%"))
              ),
              nav_panel("Redd Density Map",
                        card(leafletOutput("explore_map", height = "540px"))
              ),
              nav_panel("Site Explorer",
                        card(uiOutput("site_selector_ui")),
                        br(),
                        card(padding = 0, plotOutput("site_explorer", height = "480px", width = "100%"))
              )
            )
  ),
  
  # ══════════════════════════════════════════════════════════════════════════
  # TAB 3 · MODEL PERFORMANCE
  # ══════════════════════════════════════════════════════════════════════════
  nav_panel("Model Performance",
            br(),
            navset_card_tab(
              nav_panel("Model Comparison",
                        card(DTOutput("perf_table")),
                        br(),
                        card(plotOutput("perf_roc", height = "440px"))
              ),
              nav_panel("Effect Sizes",
                        card(padding = 0, plotOutput("perf_effects", height = "520px", width = "100%"))
              ),
              nav_panel("Month Effects",
                        card(padding = 0, plotOutput("perf_month", height = "440px", width = "100%"))
              ),
              nav_panel("Site Effects",
                        card(padding = 0, plotOutput("perf_sites", height = "680px", width = "100%"))
              ),
              nav_panel("Habitat Preference (HSI)",
                        card(padding = 0, plotOutput("perf_hsi", height = "540px", width = "100%"))
              )
            )
  ),
  
  # ══════════════════════════════════════════════════════════════════════════
  # TAB 4 · RESULTS / DISCUSSION
  # ══════════════════════════════════════════════════════════════════════════
  nav_panel("Results & Discussion",
            br(),
            uiOutput("discussion_full")
  )
)

# ── Server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  sp_label <- reactive({
    if (input$species == "chinook salmon") "Chinook Salmon" else "Steelhead Trout"
  })
  
  species_data <- reactive({
    prepare_species_data(input$species)
  })
  
  all_models <- reactive({
    d   <- species_data()
    lrd <- d$log_reg_data
    sp  <- input$species
    threshold <- 0.5
    
    lrd_sub <- if (sp == "steelhead trout") {
      lrd |> filter(month %in% c("3","4","5","6"))
    } else lrd
    
    m1 <- glm(build_formula(sp), data = lrd, family = binomial())
    m2 <- glmmTMB(build_formula(sp, "(1|location)"), data = lrd, family = binomial())
    m3 <- glmmTMB(build_formula(sp, "(1|location)+(1|month)"), data = lrd, family = binomial())
    m4 <- if (sp == "steelhead trout") {
      glmmTMB(build_formula(sp, "(1|location)+(1|month)"), data = lrd_sub, family = binomial())
    } else NULL
    
    make_row <- function(m, dat, label) {
      pp      <- predict(m, type = "response")
      obs     <- dat$presence
      roc_obj <- roc(obs, pp, quiet = TRUE)
      cm      <- table(Predicted = ifelse(pp > threshold, 1, 0), Observed = obs)
      list(model = m, roc = roc_obj, cm = cm, label = label, dat = dat)
    }
    
    rows <- list(
      make_row(m1, lrd, "Simple logistic regression"),
      make_row(m2, lrd, "RE: location"),
      make_row(m3, lrd, "RE: location + month")
    )
    if (!is.null(m4))
      rows[[4]] <- make_row(m4, lrd_sub, "RE: location + month (Mar–May)")
    rows
  })
  
  best_model_row <- reactive({
    mods <- all_models()
    mods[[length(mods)]]
  })
  
  # ── OVERVIEW ───────────────────────────────────────────────────────────────
  output$overview_objective <- renderUI({
    d          <- species_data()
    n_obs      <- nrow(d$log_reg_data)
    n_present  <- sum(d$log_reg_data$presence)
    prevalence <- round(n_present / n_obs * 100, 1)
    n_sites    <- length(unique(d$log_reg_data$location))
    months     <- sort(unique(as.integer(as.character(d$log_reg_data$month))))
    
    best_txt <- if (input$species == "chinook salmon")
      tags$p("Random effects for", strong("transect location"), "and",
             strong("month (all survey months, March–August)"), "— AUC ≈ 0.91.")
    else
      tags$p("Random effects for", strong("transect location"), "and",
             strong("month (March–May)"), "— AUC ≈ 0.91.")
    
    tagList(
      fluidRow(
        column(7,
               h4(paste("Objective —", sp_label())),
               p("Develop a model that reflects the significance of cover, substrate, depth, and
             velocity on", tolower(sp_label()), "presence and absence in the Feather River
             using Mini Snorkel Survey data (EDI, 2001–2002)."),
               hr(),
               h4("Modeling approach"),
               tags$ol(
                 tags$li(strong("Initial: Hurdle model"),
                         "— evaluated to separate zero/non-zero counts. Count component performed
                     poorly due to extreme zero-inflation and high variability. Analysis
                     refocused on presence/absence."),
                 tags$li(strong("Refined: Logistic regression"),
                         "— binary response (fish present/absent). Cover and substrate variables
                     binarized at a", strong(paste0(percent_threshold, "% threshold")), "."),
                 tags$li(strong("Mixed-effects structure"),
                         "— glmmTMB with random intercepts for transect location and month to
                     capture spatial heterogeneity and seasonal dynamics.")
               ),
               hr(), h5("Best model result"), best_txt
        ),
        column(5,
               h5("Dataset summary"),
               tags$table(
                 class = "table table-condensed table-bordered",
                 tags$tbody(
                   tags$tr(tags$th("Total observations"), tags$td(format(n_obs, big.mark = ","))),
                   tags$tr(tags$th("Presence records"),   tags$td(format(n_present, big.mark = ","))),
                   tags$tr(tags$th("Prevalence"),         tags$td(paste0(prevalence, "%"))),
                   tags$tr(tags$th("Sampling sites"),     tags$td(n_sites)),
                   tags$tr(tags$th("Survey months"),      tags$td(paste(month.abb[months], collapse = ", ")))
                 )
               ),
               br(), h5("Candidate models"),
               tags$ol(
                 tags$li("Simple logistic regression (no random effects)"),
                 tags$li("RE: transect location"),
                 tags$li("RE: location + month",
                         if (input$species == "chinook salmon") strong(" ← best") else NULL),
                 if (input$species == "steelhead trout")
                   tags$li("RE: location + month (March–May)", strong(" ← best")) else NULL
               )
        )
      )
    )
  })
  
  output$overview_plot <- renderPlot({
    d  <- species_data()
    p1 <- d$raw |> filter(count > 0) |>
      ggplot(aes(count, fill = channel_location)) +
      geom_histogram(binwidth = 50, color = "white") +
      scale_fill_manual(values = channel_colors, name = "Channel") +
      facet_grid(~channel_location) +
      labs(title = paste("Count distribution —", sp_label(), "(non-zero)"),
           x = "Fish count", y = "Frequency") +
      theme_minimal(base_size = 13) + theme(legend.position = "none")
    
    p2 <- d$raw |>
      group_by(channel_location, month = lubridate::month(date)) |>
      tally(count) |>
      ggplot(aes(x = as.factor(month), y = n, fill = channel_location)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = channel_colors, name = "Channel") +
      labs(title = paste(sp_label(), "— total counts by month and channel"),
           x = "Month", y = "Total count") +
      theme_minimal(base_size = 13)
    
    cowplot::plot_grid(p1, p2, nrow = 1)
  })
  
  output$overview_table <- renderDT({
    d <- species_data()
    d$log_reg_data |>
      select(location, channel_location, month, presence,
             depth, velocity, small_woody, large_woody,
             aquatic_veg, overhanging_veg, cobble_substrate,
             boulder_substrate, undercut_bank, redd_total, redd_presence) |>
      datatable(options = list(pageLength = 8, scrollX = TRUE), rownames = FALSE,
                caption = paste("Model input data — binary cover variables at",
                                percent_threshold, "% threshold"))
  }, server = TRUE)
  
  output$overview_vars <- renderUI({
    tagList(
      h4(paste("Predictor variables —", sp_label())),
      p("Cover and substrate variables are measured as percentages and converted to binary
         presence/absence using a", strong(paste0(percent_threshold, "% threshold")), ".
         Overhanging vegetation categories were combined."),
      hr(),
      fluidRow(
        column(4,
               h5("Continuous"),
               tags$ul(
                 tags$li(strong("Depth"),               " — numeric (m)"),
                 tags$li(strong("Velocity"),             " — numeric (m/s)"),
                 tags$li(strong("Total redds nearby"),   " — count"),
                 tags$li(strong("Surface Turbulence"),   " — numeric")
               )
        ),
        column(4,
               h5(paste0("Binary")),
               tags$ul(
                 tags$li(strong("Overhanging vegetation")),
                 tags$li(strong("Small woody debris")),
                 tags$li(strong("Large woody debris")),
                 tags$li(strong("Aquatic vegetation")),
                 tags$li(strong("Undercut bank")),
                 tags$li(strong("Boulder substrate")),
                 tags$li(strong("Cobble substrate")),
                 tags$li(strong("Redd present"), " — 0/1")
               )
        ),
        column(4,
               h5("Random effects"),
               tags$ul(
                 tags$li(strong("Location"), " — site-level spatial heterogeneity"),
                 tags$li(strong("Month"),    " — seasonal dynamics")
               ),
               br(), h5("Response"),
               tags$ul(tags$li(strong("Fish presence"), " — 1 if count > 0, else 0"))
        )
      )
    )
  })
  
  # ── DATA EXPLORATION ───────────────────────────────────────────────────────
  output$explore_hfc <- renderPlot(res = 96, {
    d  <- species_data()
    p1 <- d$raw |>
      mutate(month = factor(lubridate::month(date), levels = 1:12, labels = month.abb)) |>
      group_by(channel_location, month) |>
      tally(count) |>
      ggplot(aes(x = month, y = n, fill = channel_location)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = channel_colors, name = "Channel") +
      labs(title = paste(sp_label(), "— total counts by month and channel"),
           x = NULL, y = "Total count") +
      theme_minimal(base_size = 13)
    
    p2 <- d$raw |>
      mutate(month    = factor(lubridate::month(date), levels = 1:12, labels = month.abb),
             presence = as.integer(count > 0)) |>
      group_by(channel_location, month) |>
      summarise(pct_present = mean(presence) * 100, .groups = "drop") |>
      ggplot(aes(x = month, y = pct_present, fill = channel_location)) +
      geom_col(position = "dodge") +
      scale_fill_manual(values = channel_colors, name = "Channel") +
      labs(title = "% transects with fish present by month and channel",
           x = NULL, y = "% observations with fish") +
      theme_minimal(base_size = 13)
    
    p1 + p2
  })
  
  output$explore_map <- renderLeaflet({
    redd_summary <- if (input$species == "chinook salmon") chinook_redd_summary else steelhead_redd_summary
    location_coords <- mini_locations_raw |>
      distinct(location, longitude, latitude) |>
      filter(!is.na(longitude), !is.na(latitude)) |>
      group_by(location) |> slice(1) |> ungroup()
    locations_sf <- location_coords |>
      sf::st_as_sf(coords = c("longitude","latitude"), crs = 4326)
    redd_summary_sf <- redd_summary |>
      left_join(location_coords, by = "location") |>
      filter(!is.na(longitude), !is.na(latitude)) |>
      sf::st_as_sf(coords = c("longitude","latitude"), crs = 4326)
    leaflet() |>
      addProviderTiles(providers$Esri.WorldImagery, group = "Aerial Imagery") |>
      addProviderTiles(providers$OpenStreetMap,     group = "Street Map") |>
      addCircleMarkers(data = locations_sf, color = "#0072B2", radius = 5,
                       fillOpacity = 0.3, opacity = 0.7,
                       popup = ~paste0("Location: ", location)) |>
      addCircleMarkers(data = redd_summary_sf, color = "darkred",
                       radius = ~rescale(redd_total, to = c(3, 18)),
                       fillOpacity = 0.85, opacity = 1,
                       popup = ~paste0("Location: ", location, "<br>Total Redds: ", redd_total)) |>
      addLayersControl(baseGroups = c("Aerial Imagery","Street Map"), position = "topleft",
                       options = layersControlOptions(collapsed = FALSE)) |>
      addLegend(colors = c("#0072B2","darkred"),
                labels = c("Snorkel transects","Redd locations (size ∝ count)"))
  })
  
  output$site_selector_ui <- renderUI({
    d     <- species_data()
    sites <- sort(unique(d$raw$location))
    fluidRow(
      column(4, selectInput("selected_site", "Select a site:", choices = sites, selected = sites[1])),
      column(8, br(), p(em("Toggle between sites to see species presence patterns and cover composition.")))
    )
  })
  
  output$site_explorer <- renderPlot(res = 96, {
    req(input$selected_site)
    d <- species_data()
    site_monthly <- d$raw |>
      filter(location == input$selected_site) |>
      mutate(month    = factor(lubridate::month(date), levels = 1:12, labels = month.abb),
             presence = as.integer(count > 0)) |>
      group_by(month) |>
      summarise(pct_present = mean(presence) * 100, total_count = sum(count),
                n_obs = n(), .groups = "drop")
    
    p1 <- ggplot(site_monthly, aes(x = month, y = pct_present)) +
      geom_col(fill = "#DC863B", alpha = 0.85) +
      scale_y_continuous(limits = c(0, max(site_monthly$pct_present, 5) * 1.2)) +
      labs(title = paste(sp_label(), "presence rate —", tools::toTitleCase(input$selected_site)),
           x = NULL, y = "% observations with fish") +
      theme_minimal(base_size = 13) +
      theme(plot.margin = margin(t = 10, r = 10, b = 40, l = 10))
    
    cover_df <- d$raw |>
      filter(location == input$selected_site) |>
      mutate(overhanging_veg = percent_cover_half_meter_overhead +
               percent_cover_more_than_half_meter_overhead) |>
      select(all_of(names(cover_vars_raw)), overhanging_veg) |>
      rename(!!!setNames(names(cover_vars_raw), unname(cover_vars_raw)),
             `Overhanging veg` = overhanging_veg) |>
      pivot_longer(everything(), names_to = "feature", values_to = "pct") |>
      group_by(feature) |>
      summarise(mean_pct = mean(pct, na.rm = TRUE), .groups = "drop")
    
    p2 <- ggplot(cover_df, aes(x = mean_pct, y = reorder(feature, mean_pct))) +
      geom_col(fill = "#9A8822", alpha = 0.8) +
      labs(title = paste("Mean % cover —", tools::toTitleCase(input$selected_site)),
           x = "Mean % cover", y = NULL) +
      theme_minimal(base_size = 13)
    
    p1 + p2
  })
  
  # ── MODEL PERFORMANCE ──────────────────────────────────────────────────────
  output$perf_table <- renderDT({
    mods <- all_models()
    rows <- bind_rows(lapply(mods, function(m)
      metrics_from_cm(m$cm, m$label, round(auc(m$roc), 3))))
    datatable(rows, rownames = FALSE,
              options = list(scrollX = TRUE, dom = "t"),
              caption = "Model comparison — classification threshold = 0.5")
  })
  
  output$perf_roc <- renderPlot({
    mods <- all_models()
    roc_to_df <- function(m) data.frame(
      FPR   = 1 - m$roc$specificities,
      TPR   = m$roc$sensitivities,
      model = paste0(m$label, " (AUC = ", round(auc(m$roc), 3), ")")
    )
    df <- bind_rows(lapply(mods, roc_to_df))
    ggplot(df, aes(x = FPR, y = TPR, color = model)) +
      geom_line(linewidth = 1) +
      geom_abline(linetype = 2, color = "gray60") +
      scale_color_manual(values = custom_colors[seq_along(mods)]) +
      labs(title   = paste("ROC curves —", sp_label()),
           x       = "False positive rate (1 – Specificity)",
           y       = "True positive rate (Sensitivity)",
           color   = NULL,
           caption = "ROC curves for candidate models. AUC summarizes overall discrimination
                      ability; the dashed diagonal represents chance (AUC = 0.5).
                      All mixed-effects models outperform the simple logistic regression.") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", legend.text = element_text(size = 9))
  })
  
  output$perf_effects <- renderPlot(res = 96, {
    best       <- best_model_row()
    effects_df <- broom.mixed::tidy(best$model, conf.int = TRUE) |>
      filter(!term %in% c("(Intercept)","sd__(Intercept)")) |>
      mutate(sig        = !is.na(p.value) & p.value < 0.05,
             term_label = recode(term, !!!term_labels))
    ggplot(effects_df, aes(x = estimate, y = reorder(term_label, estimate),
                           color = sig, shape = sig)) +
      geom_vline(xintercept = 0, linetype = 2, color = "gray50") +
      geom_point(size = 2.8) +
      geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.25) +
      scale_color_manual(values = c(`FALSE` = "gray60", `TRUE` = "#D55E00"),
                         labels = c("p ≥ 0.05","p < 0.05"), name = NULL) +
      scale_shape_manual(values = c(`FALSE` = 1, `TRUE` = 16),
                         labels = c("p ≥ 0.05","p < 0.05"), name = NULL) +
      labs(title   = paste("Predictor effect sizes —", sp_label()),
           caption = paste("Best model:", best$label, "| filled = p < 0.05"),
           x = "Log odds ratio", y = NULL) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom",
            plot.margin     = margin(t = 10, r = 20, b = 10, l = 160))
  })
  
  output$perf_month <- renderPlot(res = 96, {
    best      <- best_model_row()
    month_df  <- broom.mixed::tidy(best$model, effects = "ran_vals", conf.int = TRUE) |>
      filter(group == "month") |>
      rename(unit = level, re = estimate) |>
      mutate(odds_ratio = exp(re), or_low = exp(conf.low), or_high = exp(conf.high),
             unit = paste("Month", unit)) |>
      arrange(odds_ratio) |>
      mutate(unit = factor(unit, levels = unit))
    ggplot(month_df, aes(x = odds_ratio, y = unit)) +
      geom_vline(xintercept = 1, linetype = 2, color = "gray50") +
      geom_point(size = 2.5, color = "#0072B2") +
      geom_errorbarh(aes(xmin = or_low, xmax = or_high), height = 0.2, color = "#0072B2") +
      scale_x_log10() +
      labs(title   = paste("Month random effects —", sp_label()),
           caption = "OR > 1: higher presence probability relative to global mean",
           x = "Random-effect odds ratio (log scale)", y = NULL) +
      theme_minimal(base_size = 13) +
      theme(plot.margin = margin(t = 10, r = 20, b = 10, l = 120))
  })
  
  output$perf_sites <- renderPlot(res = 96, {
    best   <- best_model_row()
    d      <- species_data()
    re_loc <- broom.mixed::tidy(best$model, effects = "ran_vals", conf.int = TRUE) |>
      filter(group == "location") |>
      rename(unit = level, re = estimate) |>
      left_join(d$raw |> select(unit = location, channel_location) |> distinct(), by = "unit") |>
      mutate(odds_ratio = exp(re), or_low = exp(conf.low), or_high = exp(conf.high)) |>
      arrange(odds_ratio) |>
      distinct(unit, .keep_all = TRUE) |>
      mutate(unit = factor(unit, levels = unit))
    ggplot(re_loc, aes(x = odds_ratio, y = unit, color = channel_location)) +
      geom_vline(xintercept = 1, linetype = 2, color = "gray50") +
      geom_point(size = 2.2) +
      geom_errorbarh(aes(xmin = or_low, xmax = or_high), height = 0.2) +
      scale_color_manual(values = channel_colors,
                         labels = c(HFC = "High-flow channel", LFC = "Low-flow channel"),
                         name   = "Channel type") +
      scale_x_log10() +
      labs(title   = paste("Site random effects —", sp_label()),
           caption = "OR > 1: higher baseline presence probability",
           x = "Random-effect odds ratio (log scale)", y = NULL) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom",
            axis.text.y     = element_text(size = 8),
            plot.margin     = margin(t = 10, r = 20, b = 10, l = 160))
  })
  
  output$perf_hsi <- renderPlot(res = 96, {
    d          <- species_data()
    cover_vars <- c("small_woody","large_woody","overhanging_veg",
                    "undercut_bank","aquatic_veg","boulder_substrate","cobble_substrate")
    df_long <- d$log_reg_data |>
      select(channel_location, presence, all_of(cover_vars)) |>
      mutate(across(all_of(cover_vars), \(x) as.integer(x > 0))) |>
      pivot_longer(all_of(cover_vars), names_to = "feature", values_to = "feature_present")
    feature_summary <- df_long |>
      group_by(channel_location, feature) |>
      summarise(n_all       = n(),
                n_feat      = sum(feature_present == 1, na.rm = TRUE),
                n_fish      = sum(presence == 1,        na.rm = TRUE),
                n_fish_feat = sum(presence == 1 & feature_present == 1, na.rm = TRUE),
                .groups = "drop") |>
      group_by(channel_location) |>
      mutate(HA      = n_feat / n_all,
             HU      = ifelse(n_fish > 0, n_fish_feat / n_fish, NA_real_),
             P       = HU / HA,
             HSI_raw = ifelse(is.finite(P), P / max(P, na.rm = TRUE), NA_real_)) |>
      ungroup()
    plot_df <- feature_summary |>
      select(channel_location, feature, HA, HU, HSI_raw) |>
      pivot_longer(c(HA, HU, HSI_raw), names_to = "panel", values_to = "value") |>
      mutate(panel   = recode(panel, HA = "HA (availability)",
                              HU = "HU (utilization)", HSI_raw = "HSI (preference)"),
             feature = str_replace_all(feature, "_", " "))
    ggplot(plot_df, aes(x = feature, y = value)) +
      geom_col(fill = "black", alpha = 0.65) +
      facet_grid(panel ~ channel_location, scales = "free_y") +
      labs(x       = NULL,
           y       = "Value (0–1)",
           title   = paste(sp_label(), "— habitat availability, utilization, and preference"),
           caption = "Figure based off of Conallin et al. 2014, Figure 5") +
      theme_minimal(base_size = 12) +
      theme(axis.text.x  = element_text(angle = 45, hjust = 1),
            strip.text.y = element_text(size = 9),
            plot.margin  = margin(t = 10, r = 20, b = 40, l = 100))
  })
  
  # ── RESULTS / DISCUSSION ───────────────────────────────────────────────────
  output$discussion_full <- renderUI({
    sp  <- sp_label()
    spc <- input$species
    
    cover_finding <- if (spc == "chinook salmon") {
      tagList(
        p(strong("Overhanging vegetation"), "was the strongest cover predictor (OR > 2, p < 0.05),
           consistent across all months and sites. Riparian structure is a primary habitat
           driver for juvenile Chinook in the Feather River."),
        p(strong("Small woody debris"), "showed a moderate positive association.",
          strong("Velocity"), "was strongly negative — fish avoid high-velocity microhabitats.",
          strong("Aquatic vegetation"), "was negatively associated, possibly reflecting
           reduced hydraulic complexity in vegetation-dominated areas."),
        p("Substrate types, large woody debris, and undercut banks were not significant
           independent predictors once overhanging cover and hydraulics were included.")
      )
    } else {
      tagList(
        p(strong("Overhanging vegetation"), ",", strong("aquatic vegetation"), ", and",
          strong("small woody debris"), "were all positively associated with juvenile steelhead
           presence — consistent with use of structurally complex microhabitats for predation
           risk reduction."),
        p(strong("Velocity"), "was negative. Multiple cover types contribute, rather than a
           single dominant predictor, suggesting steelhead use a broader range of cover features
           than Chinook.")
      )
    }
    
    d          <- species_data()
    n_obs      <- nrow(d$log_reg_data)
    n_present  <- sum(d$log_reg_data$presence)
    prevalence <- round(n_present / n_obs * 100, 1)
    
    div(style = "max-width:1100px;",
        
        # 1. Cover Is Important
        div(class = "card mb-4",
            div(class = "card-header bg-primary text-white",
                h4(style = "margin:0;", paste("1. Cover Is Important —", sp))),
            div(class = "card-body",
                p(class = "text-muted fst-italic",
                  "Finding: Cover increases the probability of juvenile fish presence,
             but its effect is modulated by spatial and temporal context."),
                cover_finding
            )
        ),
        
        # 2. Study Design
        div(class = "card mb-4",
            div(class = "card-header bg-secondary text-white",
                h4(style = "margin:0;", "2. Study Design & Data Skewness")),
            div(class = "card-body",
                fluidRow(
                  column(6,
                         h5("Zero-inflation and class imbalance"),
                         p(paste0("Fish presence records comprise only ", prevalence,
                                  "% of all observations (", format(n_present, big.mark = ","),
                                  " of ", format(n_obs, big.mark = ","), " total). ",
                                  "This extreme class imbalance means overall accuracy is misleading — a model
                       that predicts all absences would be highly accurate but useless.")),
                         tags$ul(
                           tags$li("AUC and balanced accuracy are the preferred performance metrics."),
                           tags$li("Sensitivity (correctly detecting true presences) is low at the
                         default 0.5 classification threshold."),
                           tags$li("A hurdle model was evaluated for count data but performed poorly —
                         count variability was too high and zero-inflation too severe.")
                         )
                  ),
                  column(6,
                         h5("Temporal mismatch"),
                         p("Mini Snorkel surveys were conducted in 2001–2002. Redd data span 2014–2023
                 (Chinook) and ongoing (Steelhead). The redd-fish spatial correlation is
                 interpreted as a", em("spatial pattern only"),
                           "— not a contemporaneous relationship."),
                         hr(),
                         h5("Binary cover variables"),
                         p("Cover and substrate variables measured as percentages were binarized at a",
                           strong(paste0(percent_threshold, "% threshold")), "for modeling. Key predictors
                 remain consistent across threshold values tested."),
                         hr(),
                         h5("Survey design"),
                         p("Fixed transect snorkel surveys across March–August. Not all sites were surveyed
                 in all months — random effects for month help account for this unbalanced
                 sampling structure.")
                  )
                )
            )
        ),
        
        # 3. Spatial Coupling
        div(class = "card mb-4",
            div(class = "card-header text-white", style = "background-color:#2c6e49;",
                h4(style = "margin:0;", paste("3. Spatial Coupling with Redds —", sp))),
            div(class = "card-body",
                p(class = "text-muted fst-italic",
                  "Finding: Juvenile fish presence is spatially associated with redd locations,
             but this coupling is not uniform across all sites and months."),
                fluidRow(
                  column(6,
                         h5("What the models show"),
                         tags$ul(
                           tags$li(strong("Total redd count (redd_total):"),
                                   "positive and significant — reaches with greater cumulative redd
                         activity tend to have higher juvenile presence probability."),
                           tags$li(strong("Binary redd presence (redd_presence):"),
                                   "positive but not always significant — redd", em("intensity"),
                                   "(count) is more informative than simple presence/absence of spawning.")
                         ),
                         br(), h5("Mechanisms"),
                         tags$ol(
                           tags$li(strong("Parent-offspring proximity:"),
                                   "Juveniles emerge and rear near where adults spawned. Reaches with
                         higher spawning intensity produce more juveniles locally."),
                           tags$li(strong("Shared habitat quality:"),
                                   "Reaches that attract spawning adults may also provide good rearing
                         habitat — the correlation partly reflects shared suitability rather
                         than a strict parent-offspring link.")
                         )
                  ),
                  column(6,
                         h5("When the coupling breaks down"),
                         p("The redd-juvenile coupling is not universal. Site random effects show high
                 variability in baseline presence probabilities", em("independent"),
                           "of redd counts."),
                         tags$ul(
                           tags$li("Thermal conditions (summer warming) may limit rearing suitability
                         in reaches that support cold-water spawning."),
                           tags$li("Downstream connectivity — juveniles may disperse from natal reaches
                         to better rearing habitat."),
                           tags$li("Competition and density dependence — high spawning-area density may
                         not translate proportionally to higher juvenile counts."),
                           tags$li("River size and project footprint — larger reaches have greater spatial
                         heterogeneity in redd-to-rearing habitat proximity.")
                         )
                  )
                )
            )
        )
    )
  })
}

shinyApp(ui, server)