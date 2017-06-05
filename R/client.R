client <- NULL

#' Initialize a KMS Client
#' @keywords internal
#' @return the KMS Client is cached within the package namespace as \code{kms_client}
#' @note This is automatically called when the KMS Client is required and you probably will never have to run this manually, except if you have a very non-standard workflow.
kms_init <- function() {

    assignInMyNamespace('client', tryCatch(
        .jnew('com.amazonaws.services.kms.AWSKMSClientBuilder')$defaultClient(),
        error = function(e) e))

    ## fail on error
    if (inherits(client, 'SdkClientException')) {
        stop(paste(
            'There was an error while starting the KMS Client, probably due to no configured AWS Region',
            '(that you could fix eg in ~/.aws/config or via environment variables, then reload the package):',
            client$message))
    }

}


#' Return or init a KMS Client
#' @keywords internal
kms_client <- function() {

    ## create client on first use
    if (is.null(client) || inherits(client, 'SdkClientException')) {
        kms_init()
    }

    ## return already existing client
    invisible(client)

}
