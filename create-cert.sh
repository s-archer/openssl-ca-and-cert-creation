#!/bin/bash

#-----------------------------------------------------#
# MODIFY PARAMETERS ----------------------------------# 
cn="host.example.com/emailAddress=arch@example.com"
alt1="sni1.example.com"
shortname="example"
# set null if not using a passphrase (passphrase="") 
passphrase=""
#-----------------------------------------------------#

if [ -z "$passphrase" ]
then 
    passinCommand=""
    passoutCommand="-nodes"
else 
    passwordCommand="-password pass:${passphrase}"
    passinCommand="-passin pass:${passphrase}"
    passoutCommand="-passout pass:${passphrase}"
fi

# ## Create Directory

echo "Create Directory:"
mkdir ./${shortname}
cat > ./${shortname}/san.conf <<EOL
[ req ]
default_bits                = 2048
distinguished_name          = req_distinguished_name
req_extensions              = req_ext
[ req_distinguished_name ]
countryName                 = GB
stateOrProvinceName         = London
localityName                = London
organizationName            = Example
commonName                  = ${cn}
[ req_ext ]
extendedKeyUsage            = clientAuth, serverAuth
# subjectAltName            = @alt_names
# [ alt_names ]
# DNS.1                     = ${alt1}
EOL

# ## Create CSR and Key
echo "Create CSR and Key:"
openssl req -out ./${shortname}/${shortname}.csr -newkey rsa:2048 -keyout ./${shortname}/${shortname}.key ${passoutCommand} -config ./${shortname}/san.conf -subj "/C=GB/ST=London/L=London/O=F5/OU=Demo/CN=${cn}"

# ## Sign CSR
echo "Sign CSR:"
openssl x509 -req -in ./${shortname}/${shortname}.csr -out ./${shortname}/${shortname}.crt -CAkey ./ca/client-ca.key -CA ./ca/client-ca.crt -days 365 -CAcreateserial -CAserial serial -extensions req_ext -extfile ./${shortname}/san.conf

# ## Check the CSR or CRT details
echo " "
echo "Check the CSR:"
echo " "
openssl req -noout -text -in ./${shortname}/${shortname}.csr
echo " "
echo "Check the CERT:"
echo " "
openssl x509 -noout -text -in ./${shortname}/${shortname}.crt
echo " "
# # Add trusted CA to Apple Trust Store
# - Open the CA cert in the keychain
# - Doubleclick the cert to view it
# - Expand the 'Trust' section and select 'Always Trust'


# # [Optional] Convert to PKCS12
echo "Convert to PKCS12:"
openssl pkcs12 -export -in ./${shortname}/${shortname}.crt -inkey ./${shortname}/${shortname}.key ${passwordCommand} -out ./${shortname}/${shortname}.p12 -name "${shortname} pkcs12"

# # [Optional] Create a Single Line Version of PEM Certs/Keys
echo "Create single line versions:"
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ./${shortname}/${shortname}.crt > ./${shortname}/${shortname}-one-line.crt
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ./${shortname}/${shortname}.key > ./${shortname}/${shortname}-one-line.key

# # Create base64 encoded versions for XC
echo "Create b64 encoded versions:"
openssl base64 -e -A -in ./${shortname}/${shortname}.crt -out ./${shortname}/${shortname}-b64.crt
openssl base64 -e -A -in ./${shortname}/${shortname}.key -out ./${shortname}/${shortname}-b64.key

# # Output the CA cert also for XC 
echo "Output CA cert:"
openssl base64 -e -A -in ./ca/client-ca.crt -out ./${shortname}/${shortname}-CA.crt


echo "To test use: curl -k -v  --resolve ${cn}:443:< * IP * > https://${cn}/ --cacert ./ca/client-ca.crt --key ./${shortname}/${shortname}.key --cert ./${shortname}/${shortname}.crt"

# # Blinfold the private key using vesctl - uncomment below
# echo "Using VESCTL to BLINDFOLD the pem key"
# vesctl request secrets get-public-key > demo-api-pubkey
# vesctl request secrets get-policy-document --namespace shared --name ves-io-allow-volterra > demo-api-policy
# vesctl request secrets encrypt --policy-document demo-api-policy --public-key demo-api-pubkey ./${shortname}/${shortname}.key | sed -n '2p' | tr -d '\n' > ./${shortname}/${shortname}.key.blindfold
