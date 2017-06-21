#' Retry the query up to 3 times on failure and if AWS reports it's a retryable error
#' @param cmd expression
#' @param retries number of previous retries
#' @keywords internal
#' @importFrom futile.logger flog.error
retry <- function(cmd, retries = 0) {

    cmd <- substitute(cmd)
    res <- tryCatch(eval(cmd, envir = parent.frame()), error = function(e) e)

    mc <- match.call()
    if (is.null(mc$retries)) mc$retries <- 0
    mc$retries <- mc$retries + 1
    if (mc$retries > 10) {
        stop('Giving up')
    }

    if (inherits(res, 'error') && res$isRetryable()) {
        flog.error('Retrying query due to temporary AWS error: %s', res$message)
        Sys.sleep(2 + (mc$retries - 1) * 10)
        res <- eval(mc, envir = parent.frame())
    }

    res

}


#' Encrypt plain text via KMS
#' @param key the KMS customer master key identifier as a fully specified Amazon Resource Name (eg \code{arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012}) or an alias with the \code{alias/} prefix (eg \code{alias/foobar})
#' @param text max 4096 bytes long character vector, eg an RSA key, a database password, or other sensitive customer information
#' @return Base64-encoded text
#' @export
#' @references \url{http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kms/AWSKMSClient.html#encrypt-com.amazonaws.services.kms.model.EncryptRequest-}
#' @examples \dontrun{
#' kms_encrypt('alias/mykey', 'foobar')
#' }
#' @seealso kms_decrypt
#'
kms_encrypt <- function(key, text) {

    ## prepare the request
    req <- .jnew('com.amazonaws.services.kms.model.EncryptRequest')
    req$setKeyId(key)
    req$setPlaintext(J('java.nio.ByteBuffer')$wrap(.jbyte(charToRaw(as.character(text)))))

    ## send to AWS
    cipher <- retry(kms_client()$encrypt(req))$getCiphertextBlob()$array()

    ## encode and return
    base64_enc(cipher)

}


#' Decrypt cipher into plain text via KMS
#' @param cipher Base64-encoded ciphertext
#' @param return return format
#' @return decrypted text as string or raw
#' @export
#' @references \url{http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kms/AWSKMSClient.html#decrypt-com.amazonaws.services.kms.model.DecryptRequest-}
#' @seealso kms_encrypt
kms_decrypt <- function(cipher, return = c('string', 'raw')) {

    return <- match.arg(return)

    ## prepare the request
    req <- .jnew('com.amazonaws.services.kms.model.DecryptRequest')
    req$setCiphertextBlob(J('java.nio.ByteBuffer')$wrap(.jbyte(base64_dec(cipher))))

    ## send to AWS
    res <- retry(kms_client()$decrypt(req))$getPlaintext()$array()

    ## return as requested
    if (return == 'string') {
        res <- rawToChar(res)
    }
    res

}


#' Generate a data encryption key for envelope encryption
#' @param bytes the required length of the data encryption key in bytes (so provide eg \code{64L} for a 512-bit key)
#' @return \code{list} of the Base64-encoded encrypted version of the data encryption key (to be stored on disk), the \code{raw} object of the encryption key and the KMS customer master key used to generate this object
#' @inheritParams kms_encrypt
#' @export
#' @references \url{http://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKey.html}
kms_generate_data_key <- function(key, bytes = 64L) {

    ## prepare the request
    req <- .jnew('com.amazonaws.services.kms.model.GenerateDataKeyRequest')
    req$setKeyId(key)
    req$setNumberOfBytes(.jnew('java/lang/Integer', bytes))

    ## send to AWS
    res <- retry(kms_client()$generateDataKey(req))

    ## return cypher + plain text
    list(
        cipher = base64_enc(res$getCiphertextBlob()$array()),
        key    = res$getKeyId(),
        text   = res$getPlaintext()$array())

}


#' Encrypt file via KMS
#' @param key the KMS customer master key identifier as a fully specified Amazon Resource Name (eg \code{arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012}) or an alias with the \code{alias/} prefix (eg \code{alias/foobar})
#' @param file file path
#' @return two files created with \code{enc} (encrypted data) and \code{key} (encrypted key) extensions
#' @export
#' @seealso kms_encrypt kms_decrypt_file
#' @importFrom digest AES
kms_encrypt_file <- function(key, file) {

    if (!file.exists(file)) {
        stop(paste('File does not exist:', file))
    }

    ## load the file to be encrypted
    msg <- readBin(file, 'raw', n = file.size(file))
    ## the text length must be a multiple of 16 bytes
    ## so let's Base64-encode just in case
    msg <- charToRaw(base64_enc(msg))
    msg <- c(msg, as.raw(rep(as.raw(0), 16 - length(msg) %% 16)))

    ## generate encryption key
    key <- kms_generate_data_key(key, bytes = 32L)

    ## encrypt file using the encryption key
    aes <- AES(key$text, mode = 'ECB')
    writeBin(aes$encrypt(msg), paste0(file, '.enc'))

    ## store encrypted key
    cat(key$cipher, file = paste0(file, '.key'))

    ## return file paths
    list(
        file = file,
        encrypted = paste0(file, '.enc'),
        key = paste0(file, '.key')
    )

}


#' Decrypt file via KMS
#' @param file base file path (without the \code{enc} or \code{key} suffix)
#' @param return where to place the encrypted file (defaults to \code{file})
#' @return decrypted file path
#' @export
#' @seealso kms_encrypt kms_encrypt_file
#' @importFrom digest AES
kms_decrypt_file <- function(file, return = file) {

    if (!file.exists(paste0(file, '.enc'))) {
        stop(paste('Encrypted file does not exist:', paste0(file, '.enc')))
    }
    if (!file.exists(paste0(file, '.key'))) {
        stop(paste('Encryption key does not exist:', paste0(file, '.key')))
    }
    if (file.exists(return)) {
        stop(paste('Encrypted file already exists:', return))
    }

    ## load the encryption key
    key <- kms_decrypt(readLines(paste0(file, '.key'), warn = FALSE), return = 'raw')

    ## load the encrypted file
    msg <- readBin(paste0(file, '.enc'), 'raw', n = file.size(paste0(file, '.enc')))

    ## decrypt the file using the encryption key
    aes <- AES(key, mode = 'ECB')
    msg <- aes$decrypt(msg, raw = TRUE)
    msg <- base64_dec(msg)

    ## Base64-decode and return
    writeBin(msg, return)

    ## return file paths
    return

}
