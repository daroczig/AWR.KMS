# AWS.KMS

This an R client to interact with the [AWS Key Management Service](https://aws.amazon.com/kms), including wrapper functions around the [KMS Java client](http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kms/AWSKMSClient.html) to encrypt plain text and decrypt cipher using Customer Master Keys stored in KMS.

## Installation

![CRAN version](http://www.r-pkg.org/badges/version-ago/AWR.KMS)

The package is hosted on [CRAN](https://cran.r-project.org/package=AWR.KMS), so installation is as easy as:

```r
install.packages('AWR.KMS')
```

But you can similarly easily install the most recent development version of the R package as well:

```r
devtools::install_github('cardcorp/AWS.KMS')
```

This R package relies on the `jar` files bundled with the [AWR package](https://cran.r-project.org/package=AWR).

## What is it good for?

Currently, only three basic, but very important features are supported:

* you can encrypt up to 4 KB of arbitrary data such as an RSA key, a database password, or other sensitive customer information and Base64-encode it to be stored somewhere:

```r
> library(kmR)
> kms_encrypt('alias/mykey', 'foobar')
[1] "Base-64 encoded ciphertext"
```

* decrypt such Base-64 encoded ciphertext back to plaintext:

```r
> kms_encrypt('Base-64 encoded ciphertext')
[1] "foobar"
```

* generate a data encryption key (see below for a use case):

```r
> kms_generate_data_key('alias/mykey')
$cipher
[1] "Base-64 encoded, encrypted data encryption key"

$key
[1] "alias/mykey"

$text
[1] "Base-64 encoded data encryption key"

```

## How can I encrypt data larger than 4KB?

Use [envelope encryption](http://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#enveloping). In short, you can:

* generate a new (data) encryption key (eg with `kms_generate_data_key`) and store it only in memory for the next 2 steps
* use this new encryption key to encrypt the data locally (eg using the `sodium` package or the `AES` function from the `digest` package)
* encrypt the encryption key via KMS and store the encrypted (data encryption) key on disk along with the encrypted data
* clean up the encryption key from memory
* if you want to decrypt the data, decrypt the encrypted (data encryption) key via KMS, than decrypt the data with the decrypted (data encryption) key stored in memory

A simple implementation:

```r
## let's say we want to encrypt the mtcars dataset stored in JSON
library(jsonlite)
data <- toJSON(mtcars)

## generate a 256-bit data encryption key (that's supported by digest::AES)
library(AWR.KMS)
key <- kms_generate_data_key('alias/mykey', byte = 32L)

## convert the JSON to raw so that we can use that with digest::AES
raw <- charToRaw(data)
## the text length must be a multiple of 16 bytes
## https://github.com/sdoyen/r_password_crypt/blob/master/crypt.R
raw <- c(raw, as.raw(rep(0, 16 - length(raw) %% 16)))

## encrypt the raw object with the new key + digest::AES
## the resulting text and the encrypted key can be stored on disk
library(digest)
aes <- AES(key$text)
base64_enc(aes$encrypt(raw))

## decrypt the above returned ciphertext using the decrypted key
rawToChar(aes$decrypt(base64_dec(...), raw = TRUE))
```

## What if I want to do other cool things with KMS and R?

Writing wrapper functions around the Java SDK is very easy. Please open a ticket on the feature request, or even better, submit a pull request :)

## It doesn't work here!

To be able to use this package, you need to have an [AWS account](https://aws.amazon.com/free) and a [KMS Encryption Key](https://console.aws.amazon.com/iam/home#encryptionKeys). If you do not have one already, you can register for free at Amazon and do 20K free requests per month, although keys do cost 1 USD per month.

Once you have an AWS account, make sure your default AWS Credentials are available via the [DefaultAWSCredentialsProviderChain ](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html). In short, you either provide a default credential profiles file at `~/.aws/credentials`, use the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables or if using `AWR.KMS` on AWS, you can also rely on the EC2 instance profile credentials or ECS Task Role as well.
