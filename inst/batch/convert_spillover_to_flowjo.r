# Required Libraries
library(stringr)
library(uuid)

# Translation of characters required by flowjo
dye_forbidden_chars <- '/'
dye_substitution_char <- '_'

# Substitutes the value of an attribute in an xml line
substitute_value <- function(line, attribute, new_value) {
  marker_left <- paste0(attribute, '="')
  marker_right <- '"'
  pos_left <- str_locate(line, marker_left)[2]
  pos_right <- str_locate(substr(line, pos_left + 1, nchar(line)), marker_right)[1] + pos_left
  paste0(substr(line, 1, pos_left), new_value, substr(line, pos_right, nchar(line)))
}

# Check input arguments
#args <- commandArgs(trailingOnly = TRUE)
#if(length(args) != 3) {
#  stop("Usage: generate_flowjo_spillover.R spillover_matrix_name input_spillover_file.csv output_flowjo_file.mtx")
#}

spillover_matrix_name <- "autospill_comp"
spillover_file_name <- "./table_spillover/autospill_spillover.csv"
flowjo_file_name <- "autospill_comp_matrix.mtx"

# Read spillover matrix

spillover_file <- read.csv(spillover_file_name, row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)

dyes <- colnames(spillover_file)
spillover <- spillover_file

if(!identical(sort(rownames(spillover)), sort(dyes))) {
  stop(paste("generate_flowjo_spillover.R: wrong dyes in spillover file", spillover_file_name))
}

# Define flowjo format for spillover matrix
flowjo_main_header <- '<?xml version="1.0" encoding="UTF-8"?>\n<gating:gatingML>'
flowjo_main_footer <- '</gating:gatingML>'

flowjo_matrix_header <- '  <transforms:spilloverMatrix prefix="Comp-" name="" editable="1" status="FINALIZED" transforms:id="">'
flowjo_matrix_footer <- '  </transforms:spilloverMatrix>'

flowjo_parameter_header <- '    <data-type:parameters>'
flowjo_parameter_body   <- '      <data-type:parameter data-type:name=""/>'
flowjo_parameter_footer <- '    </data-type:parameters>'

flowjo_coefficient_header <- '    <transforms:spillover data-type:parameter="">'
flowjo_coefficient_body   <- '      <transforms:coefficient data-type:parameter="" transforms:value=""/>'
flowjo_coefficient_footer <- '    </transforms:spillover>'

# Write flowjo file

dye_substitution_table <- chartr(dye_forbidden_chars, dye_substitution_char, dyes)
names(dye_substitution_table) <- dyes

flowjo_file <- file(flowjo_file_name, open = "wt")

cat(flowjo_main_header, file = flowjo_file, sep = "\n")

matrix_header <- substitute_value(flowjo_matrix_header, 'name', spillover_matrix_name)
matrix_header <- substitute_value(matrix_header, 'transforms:id', UUIDgenerate(use.time = NA))
cat(matrix_header, file = flowjo_file, sep = "\n")

cat(flowjo_parameter_header, file = flowjo_file, sep = "\n")

for(d in dyes) {
  cat(substitute_value(flowjo_parameter_body, 'data-type:name', dye_substitution_table[d]), file = flowjo_file, sep = "\n")
}

cat(flowjo_parameter_footer, file = flowjo_file, sep = "\n")

for(d in dyes) {
  cat(substitute_value(flowjo_coefficient_header, 'data-type:parameter', dye_substitution_table[d]), file = flowjo_file, sep = "\n")
  
  for(d2 in dyes) {
    coefficient_body <- flowjo_coefficient_body
    coefficient_body <- substitute_value(coefficient_body, 'data-type:parameter', dye_substitution_table[d2])
    coefficient_body <- substitute_value(coefficient_body, 'transforms:value', as.character(spillover[d, d2]))
    cat(coefficient_body, file = flowjo_file, sep = "\n")
  }
  
  cat(flowjo_coefficient_footer, file = flowjo_file, sep = "\n")
}

cat(flowjo_matrix_footer, file = flowjo_file, sep = "\n")

cat(flowjo_main_footer, file = flowjo_file, sep = "\n")

close(flowjo_file)
