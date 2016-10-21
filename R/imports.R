#' An R client to Amazon Key Management Service
#'
#' This is a simple wrapper around the most important features of the related Java SDK.
#' @docType package
#' @importFrom jsonlite base64_dec base64_enc
#' @importFrom rJava .jnew J .jbyte
#' @name kmR-package
NULL

.onLoad <- function(libname, pkgname) {
    rJava::.jpackage(pkgname, lib.loc = libname,
                     morePaths = list.files(system.file('inst/java', package = pkgname), full.names = TRUE))
}
