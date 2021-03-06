.onAttach <- function(...) {

	# find M2 on a Mac or Linux
	if(is.mac() || is.linux()){
		unix_search_and_set("M2", "Macaulay2", "m2_path")
	}

	# find M2 on a PC - directs to cloud immediately
	if(is.win()){

		# if(!any(stringr::str_detect(tolower(list.files("C:\\")), "cygwin"))){
		# 	psm("Cygwin is required to run m2 on a Windows platform.")
		# 	psm("  It needs to be in your C:\\ drive, but wasn't found.")
		# 	return(invisible())
		# }

		# if(!whereis_is_accessible()){ # check for whereis, return if not found
		# 	psm(
		# 		"The whereis function was not found, so algstat can't find the required exe's.\n",
		# 		"  Try setting the path with set_m2_path()."
		# 	)
		# 	return()
		# }

		win_search_and_set("m2")
	}

	# check that the programs were found
	startup_check_for_program()

	# return
	invisible(TRUE)
}




.onDetach <- function(...) {
	stop_m2()
  options(m2r = NULL)
}
# restart R
# library(m2r)
# m2("1+1")
# getOption("m2r")
# detach("package:m2r")
# getOption("m2r")




# unix_find looks for a specific executable in a specific directory
# (or its children)
# however, we don't just use this on / because it'd take forever
# so unix_search_and_set uses unix_find to search specific directories
unix_find <- function(exec, where){

	# query the system and clean attributes
	query <- sprintf("find %s -name %s", where, exec)
	finding <- suppressWarnings(system(query, intern = TRUE, ignore.stderr = TRUE))
	attributes(finding) <- NULL

	# get the bin first
	path <- finding[stringr::str_detect(finding, paste0("bin/", exec))][1]

	# bertini isn't in a bin directory
	if(is.na(path)) path <- finding[1]

	# return
	path
}




startup_check_for_program <- function(){

	if(!is.null(get_m2_path())){
		psms("  M2 found in %s", get_m2_path())
		return(invisible(FALSE))
	}

	if(is.null(get_m2_path())){
		psms("  M2 not found; defaulting to cloud.")
	  psms("  Use set_m2r_path(\"/path/to/m2\") to run M2 locally.")
		return(invisible(FALSE))
	}

	invisible(TRUE)

}




psm  <- packageStartupMessage
psms <- function(fmt, ...) packageStartupMessage(sprintf(fmt, ...))


setOption <- function(optionName, value){
  eval(parse(text = sprintf('options("%s" = "%s")', optionName, value)))
}


unix_search_and_set <- function(exec, baseName, optionName){

  # grab path and parse
  profile_to_look_for <-
  	if(file.exists("~/.bash_profile")){
      ".bash_profile"
  	} else if(file.exists("~/.bashrc")){
      ".bashrc"
  	} else if(file.exists("~/.profile")){
      ".profile"
  	}

  # PATH <- system(sprintf("source ~/%s; echo $PATH", profile_to_look_for), intern = TRUE)
  # the above doesn't work on ubuntu, which uses the dash shell (which doesn't have source)
  PATH <- system(sprintf("echo 'source ~/%s; echo $PATH' | /bin/bash", profile_to_look_for), intern = TRUE)
  dirs_to_check <- stringr::str_split(PATH, ":")[[1]]

  # check for main dir name
  ndx_with_baseName_dir  <- which(stringr::str_detect(tolower(dirs_to_check), baseName))
  baseName_path <- dirs_to_check[ndx_with_baseName_dir]

  # seek and find
  for(path in dirs_to_check){
    found_path <- unix_find(exec, path)
    if(!is.na(found_path)) break
  }

  # break in a failure
  if(is.na(found_path)) return()

  # set option and exit
  set_m2r_option(m2_path = dirname(found_path))

  # invisibly return path
  invisible(dirname(found_path))
}





whereis_is_accessible <- function() unname(Sys.which("whereis")) != ""

win_find <- function(s){
  wexe <- unname(Sys.which("whereis"))
  x <- system(paste(wexe, s), intern = TRUE)
  str_sub(x, nchar(s)+2)
}

win_search_and_set <- function(optionName){

  # search
  # x <- win_find("m2")
  # if(stringr::str_detect(x, "/")) {
  #   set_m2r_option(m2_path = dirname(x))
  # }

  # set_m2r_option(m2_path = "C:\\cygwin\\bin")

  set_m2r_option(m2_path = NULL)

}





# set_m2r_option both sets options for m2r in the list m2r in options
# and initialized the list when m2r is attached to the search path
# (search())
set_m2r_option <- function(...) {

  # if there is no m2r option (package is being initialized)
  # create the list with the arguments and return
  if ("m2r" %notin% names(options())) {
    options(m2r = list(...))
    return(invisible())
  }

  # otherwise, go through arguments sequentially and add/update
  # them in the list m2r in options
  m2r <- getOption("m2r")
  arg_list <- lapply(as.list(match.call())[-1], eval, envir = parent.frame())
  for (k in seq_along(arg_list)) {
    if (names(arg_list)[k] %in% names(m2r)) {
      m2r[names(arg_list)[k]] <- arg_list[k]
    } else {
      m2r <- c(m2r, arg_list[k])
    }
  }

  # set new m2r
  options(m2r = m2r)

  # return
  invisible()
}
# (l <- list(a = 1, b = 2, c = 3))
# l[d] <- 5
# l










