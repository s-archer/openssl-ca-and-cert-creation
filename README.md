# Create a CA

## Generate a random
openssl rand -out ./ca/.rand 2048

## Create a key
openssl genrsa -rand ./ca/.rand -out ./ca/client-ca.key 2048

## Create the crt
openssl req -x509 -new -key ./ca/client-ca.key -out ./ca/client-ca.crt -days 825

# Create a Key and Client Cert signed by the CA

The script [create-cert.sh](./create-cert.sh) will perform the folliwng tasks:

- Create a subfolder named ${shortname} and inside:
- Create CSR and Key inn PEM format (*.csr and *.key)
- Sign CSR with your CA in PEM format (*.crt)
- Check the CSR or CRT details
- Create PKCS12 versions (*.p12)
- Create 'single line' versions of PEMs (*-one-line.crt *-one-line.key)
- For XC - create Base64 encoded versions of the PEMs (*-b64.crt *-b64.key)
- For XC - create Base64 encoded versions of the CA cert PEM (*-CA.crt)

## Blinfold the private key using vesctl 

The last 4 lines are commented out, but if you want to use the F5 XC vesctl CLI 
to blindfold the certificates before sending to the API, install and configure 
the vesctl cli tool and uncomment the last 4 lines.

https://gitlab.com/volterra.io/vesctl/blob/main/README.md

Some examples of creating a load-balancer using blindfolded certs can be found here:

https://github.com/s-archer/xc-lb-examples/blob/main/lb.tf
