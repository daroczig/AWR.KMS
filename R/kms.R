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
kms_encrypt <- function(key, text) {

    ## prepare the request
    req <- .jnew("com.amazonaws.services.kms.model.EncryptRequest")
    req$setKeyId(key)
    req$setPlaintext(J('java.nio.ByteBuffer')$wrap(.jbyte(charToRaw(as.character(text)))))

    ## send to AWS
    client <- .jnew("com.amazonaws.services.kms.AWSKMSClient")
    cipher <- client$encrypt(req)$getCiphertextBlob()$array()

    ## encode and return
    base64_enc(cipher)

}


#' Decrypt cipher into plain text via KMS
#' @param cipher Base64-encoded ciphertext
#' @return decrypted text
#' @export
#' @references \url{http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kms/AWSKMSClient.html#decrypt-com.amazonaws.services.kms.model.DecryptRequest-}
#' @seealso kms_encrypt
kms_decrypt <- function(cipher) {

    ## prepare the request
    req <- .jnew("com.amazonaws.services.kms.model.DecryptRequest")
    req$setCiphertextBlob(J('java.nio.ByteBuffer')$wrap(.jbyte(base64_dec(cipher))))

    ## send to AWS
    client <- .jnew("com.amazonaws.services.kms.AWSKMSClient")
    rawToChar(client$decrypt(req)$getPlaintext()$array())

}
