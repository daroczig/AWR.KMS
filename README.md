# kmR

This R package includes wrapper functions around [Amazon's KMS Java client](http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/kms/AWSKMSClient.html) to encrypt plain text and decrypt cipher using the Customer Master Keys stored in KMS.

## Why the name?

This is an R client to KMS and S is so 1992.

## What is it good for?

Currently, only two basic, but very important features are supported:

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

## What if I want to do other cool things with KMS and R?

Writing wrapper functions around the Java SDK is very easy. Please open a ticket on the feature request, or even better, submit a pull request :)

## It doesn't work here!

To be able to use this package, you need to have an [AWS account](https://aws.amazon.com/free) and a [KMS Encryption Key](https://console.aws.amazon.com/iam/home#encryptionKeys). If you do not have one already, you can register for free at Amazon and do 20K free requests per month, although keys do cost 1 USD per month.

Once you have an AWS account, make sure your default AWS Credentials are available via the [DefaultAWSCredentialsProviderChain ](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html). In short, you either provide a default credential profiles file at `~/.aws/credentials`, use the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables or if using `kmR` on AWS, you can also rely on the instance profile credentials as well.
