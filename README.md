# Using the script

The script [create-cert.sh](/create-cert.sh) has a pre-requisite that you must first create a CA using the three commands in the [Create a CA](#Create-a-CA) section below.  The commands will create your CA cert and key inside the `./ca` folder.

One you have created your CA, you can use the script to create certificates and keys signed by your CA.

Before running the script, make sure to update the parameters `cn` (the CN for certificate you create ), `alt1` (additional SAN for your cert) and `shortname` (this is primarily used to create a subfolder iside which the new certs/keys are created).

Note that most of the addiional steps in the [Create a Client Cert signed by the CA](#Create-a-Client-Cert-signed-by-the-CA) and the additional optional steps are iuncluded in the script, so mainly here for information.

# Create a CA

## Generate a random
openssl rand -out ./ca/.rand 2048

## Create a key
openssl genrsa -rand ./ca/.rand -out ./ca/client-ca.key 2048

## Create the crt
openssl req -x509 -new -key ./ca/client-ca.key -out ./ca/client-ca.crt -days 825

# Create a Client Cert signed by the CA

## Create CSR & KEY
Create a san.conf file like so, but just modify the last two DNS* lines:

    [ req ]
    default_bits       = 2048
    distinguished_name = req_distinguished_name
    req_extensions     = req_ext
    [ req_distinguished_name ]
    countryName                 = Country Name (2 letter code)
    stateOrProvinceName         = State or Province Name (full name)
    localityName               = Locality Name (eg, city)
    organizationName           = Organization Name (eg, company)
    commonName                 = Common Name (e.g. server FQDN or YOUR name)
    [ req_ext ]
    subjectAltName = @alt_names
    [ alt_names ]
    DNS.1   = sni1.example.com
    DNS.2   = sni2.example.com

openssl req -out ./ca-signed/client1.csr -newkey rsa:2048 -nodes -keyout ./ca-signed/client1.key -config ./ca-signed/san.conf

## Sign CSR
openssl x509 -req -in ./ca-signed/client1.csr -out ./ca-signed/client1.crt -CAkey ./ca/client-ca.key -CA ./ca/client-ca.crt -days 365 -CAcreateserial -CAserial serial -extensions req_ext -extfile ./ca-signed/san.conf

## Check the CSR or CRT details
openssl req -noout -text -in ./ca-signed/client1.csr
openssl x509 -noout -text -in ./ca-signed/client1.crt 

# Add trusted CA to Apple Trust Store
- Open the CA cert in the keychain
- Doubleclick the cert to view it
- Expand the 'Trust' section and select 'Always Trust'


# [Optional] Convert to PKCS12
openssl pkcs12 -export -in ./ca-signed/client1.crt -inkey ./ca-signed/client1.key -out ./ca-signed/client1.p12 -name "client1 pkcs12"

# [Optional] Create a Self-Signed Key and Certificate

openssl req -newkey rsa:2048 -nodes -keyout  app1-key.pem -x509 -days 365 -out  app1-cert.pem -subj "/C=GB/ST=LONDON/L=LONDON/O=Example/OU=Example/CN=host.example.com/emailAddress=arch@example.com"

# [Optional] Create a Single Line Version of PEM Certs/Keys
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ./ca-signed/auth.internal.crt  