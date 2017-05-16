#' An R client to Amazon Key Management Service
#'
#' This is a simple wrapper around the most important features of the related Java SDK.
#' @references \url{http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kms/AWSKMSClient.html}
#' @docType package
#' @importFrom jsonlite base64_dec base64_enc
#' @importFrom rJava .jnew J .jbyte
#' @import AWR
#' @name AWR.KMS-package
NULL

kms_client <- NULL
.onLoad <- function(libname, pkgname) {

    ## try to create the KMS Client
    client <- tryCatch(
        .jnew('com.amazonaws.services.kms.AWSKMSClientBuilder')$defaultClient(),
        error = function(e) e)

    ## let the user know it was not successful and to reload the package
    if (inherits(client, 'SdkClientException')) {
        warning(paste(
            'There was an error while starting the KMS Client, probably due to no configured AWS Region',
            '(that you could fix eg in ~/.aws/config or via environment variables, then reload the package):',
            client$message))
    }

    assignInMyNamespace('kms_client', client)

}
