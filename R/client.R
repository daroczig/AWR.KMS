#' Return or init a KMS Client
#' @keywords internal
kms_client <- function() {

    client <- .jnew('com.amazonaws.services.kms.AWSKMSClientBuilder')$defaultClient()

    ## fail on error
    if (inherits(client, 'SdkClientException')) {
        stop(paste(
            'There was an error while starting the KMS Client, probably due to no configured AWS Region',
            '(that you could fix eg in ~/.aws/config or via environment variables, then reload the package):',
            client$message))
    }

    ## return
    invisible(client)

}
