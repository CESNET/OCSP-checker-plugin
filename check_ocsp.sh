#!/bin/bash

# Copyright (c) 2022 CESNET, z.s.p.o.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


VER=1.0

SERVICE_OK=0
SERVICE_WARNING=1
SERVICE_CRITICAL=2
SERVICE_UNKNOWN=3


print_help() {

echo << END
$0 ver. $VER

Checks an OCSP server health

Usage: $0 [--ca ca_cert] [--issuer issuer_cert] [--responder responder_cert]
       [--serial serial_number] [--url URL] [--debug] [--help]

Parameters:

--ca ca_cert: File or pathname containing trusted CA certificates.
These are used to verify the signature on the OCSP response

--issuer issuer_cert: This specifies the current issuer certificate.
The certificate specified in filename must be in PEM format.

--responder responder_cert: File containing explicitly trusted responder
certificates.

--serial serial_number: Serial number of the tested certificate.

-url URL: URL address of the OCSP responder

--debug: Print debugging information.

--help: Prints usage and exits.

END

}


debug () {
    if [ -n "$DEBUG" ]; then
        echo "DEBUG: $1"
    fi
}


error () {
    echo "ERROR: $1"
}


config_error () {
    error "$1"
    exit $SERVICE_UNKNOWN
}



while [ $# -gt 0 ]
do
  case $1 in

    --help)
        print_help
        shift 1
        exit $OK
        ;;

    --ca)
        CA=$2
        shift 2
        ;;

    --issuer)
        ISSUER=$2
        shift 2
        ;;

    --responder)
        RESPONDER=$2
        shift 2
        ;;

    --url)
        URL=$2
        shift 2
        ;;

    --serial)
        SERIAL=$2
        shift 2
        ;;

    --debug)
        DEBUG=yes
        shift 1
        ;;

    *)
        echo "Unknown parameter: $1"
        print_help
        exit $SERVICE_UNKNOWN
        ;;

  esac
done


# # # # # # # # # # #
#  CA certificate   #
# # # # # # # # # # #

# CA certificatece was not specified
if [[ -z $CA ]]; then
  config_error "CA certificate (parameter --ca) was not specified."
fi

# CA certificate file does not exist
if [[ ! -f $CA ]]; then
    config_error "CA certificate file not found: $CA"
fi


# # # # # # # # # # # # #
#  Issuer certificate   #
# # # # # # # # # # # # #

# Issuer certificatece was not specified
if [[ -z $ISSUER ]]; then
  config_error "Issuer certificate (parameter --issuer) was not specified."
fi

# Issuer file does not exist
if [[ ! -f $ISSUER ]]; then
    config_error "Issuer certificate file not found: $ISSUER"
fi


# # # # # # # # # # # # #
# Responder certificate #
# # # # # # # # # # # # #

# Responder certificate was not specified
if [[ -z "$RESPONDER" ]]; then
  config_error "Responder certificate (parameter --responder) not specified."
fi

# Responder certificate file does not exist
if [[ ! -f $RESPONDER ]]; then
    config_error "Responder certificate file not found: $RESPONDER"
fi


# #  # # # #
# OCSP URL #
# #  # # # #

# URL was not specified
if [[ -z $URL ]]; then
  config_error "URL (parameter --url) was not specified."
fi


# #  # # # # # # #
# Serial number  #
# #  # # # # # # #

# Certificate serial number was not specified
if [[ -z $SERIAL ]]; then
  config_error "Serial number of the certificate (parameter --serial) not specified."
fi



COMMAND="openssl ocsp -CAfile $CA -issuer $CA -serial $SERIAL -url $URL -VAfile $RESPONDER"
debug "Executing command: $COMMAND"

RESPONSE=$($COMMAND)
RET=$?

debug "Response: $RESPONSE"
debug "Return value: $RET"

if [ $RET -ne 0 ]; then
    error "OCSP check failed on ${URL}."
    exit $SERVICE_CRITICAL
fi

echo "OCSP server is up and running."
exit $SERVICE_OK
