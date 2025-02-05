program define GMD
    version 14.0
    syntax [anything] [, clear Version(string) Country(string)]
	
	* Determine current version for display purposes only
    local current_date = date(c(current_date), "DMY")
    local current_year = year(date(c(current_date), "DMY"))
    local current_month = month(date(c(current_date), "DMY"))
    
    * Determine quarter based on current month (for display only)
    if `current_month' <= 3 {
        local quarter "01"
    }
    else if `current_month' <= 6 {
        local quarter "04"
    }
    else if `current_month' <= 9 {
        local quarter "07"
    }
    else {
        local quarter "10"
    }
    
    local current_version "`current_year'_`quarter'"
    
    * Set default version if not specified
    if "`version'" == "" {
        local version "current"  // Default to current version
    }
    
    * Validate version format if not current
    if "`version'" != "current" {
        if !regexm("`version'", "^20[0-9]{2}_(01|04|07|10)$") {
            display as error "Invalid version format. Use YYYY_QQ format (e.g., 2024_04) or 'current'"
            display as error "Valid quarters are: 01, 04, 07, 10"
            exit 198
        }
    }
    
    * Display package information
    display as text "Global Macro Data by Müller et. al (2025)"
    display as text "Version: `current_version'"
    display as text "Website: https://www.globalmacrodata.com/"
    display as text ""
    
    * Define paths
    local personal_dir = c(sysdir_personal)
    local base_dir "`personal_dir'/GMD/"
    local vintages_dir "`base_dir'vintages/"
    
    * Create base and vintages directories if they don't exist
    capture mkdir "`base_dir'"
    capture mkdir "`vintages_dir'"
    
    * Set data path and download file name based on version
    if "`version'" == "current" {
        local data_path "`base_dir'GMD.dta"
        local download_file "GMD.dta"
        local download_url "https://github.com/mlhb-mr/test/raw/refs/heads/main/`download_file'"
    }
    else {
        local data_path "`vintages_dir'GMD_`version'.dta"
        local download_file "GMD_`version'.dta"
        local download_url "https://github.com/mlhb-mr/test/raw/refs/heads/main/vintages/`download_file'"
    }
    
    * Check if dataset exists, if not, try to download it
    capture confirm file "`data_path'"
    if _rc {
        display as text "Dataset `download_file' not found locally. Attempting to download..."
        
        * Try to download the dataset
        capture copy "`download_url'" "`data_path'", replace
        if _rc {
            display as error "Failed to download dataset `download_file'"
            display as error "Please check if the version exists and your internet connection"
            exit _rc
        }
        display as text "Download complete."
    }
    
    * Load the dataset
    use "`data_path'", clear
    
    * Check if ISO3 and year variables exist
    foreach var in ISO3 year {
        capture confirm variable `var'
        if _rc {
            display as error "`var' variable not found in the dataset"
            exit 498
        }
    }
    
    * If country option is specified, filter for that country
    if "`country'" != "" {
        * Convert country code to uppercase for consistency
        local country = upper("`country'")
        
        * Check if the country exists in the dataset
        quietly: levelsof ISO3, local(countries)
        if !`: list country in countries' {
            display as error "Country code `country' not found in the dataset"
            display as text "Available country codes are: `countries'"
            exit 498
        }
        
        * Keep only specified country
        keep if ISO3 == "`country'"
        display as text "Filtered data for country: `country'"
    }
    
    * If user specified variables, keep only those plus ISO3 and year
    if "`anything'" != "" {
        * Create a local macro with all variables to keep
        local keepvars "ISO3 year `anything'"
        
        * Check if specified variables exist
        foreach var of local anything {
            capture confirm variable `var'
            if _rc {
                display as error "Variable `var' not found in the dataset"
                exit 498
            }
        }
        
        * Keep only specified variables plus ISO3 and year
        keep `keepvars'
        
        * Display success message with kept variables
        display as text "Dataset loaded with variables: `keepvars'"
    }
    else {
        display as text "Dataset loaded with all variables"
    }
    
    * Display final dataset dimensions
    quietly: describe
    display as text "Final dataset: `r(N)' observations of `r(k)' variables"
end
