# The NS and DS records for ssb, ssb-staging, and ssb-dev are all actually
# commented out here. They are managed in the data.gov zone, which we modify by
# submitting requests to GSA IT's DNS group.

# However, the expected values are recorded here for completeness and for
# checking against the live values in the data.gov domain.

# production

# resource "aws_route53_record" "ssb-ns" {
#   allow_overwrite = true
#   name            = "ssb"
#   ttl             = 1800
#   type            = "NS"
#   zone_id         = "Z2QMRHTV5AP7G6"
#   records = [
#     "ns-1147.awsdns-15.org",
#     "ns-1786.awsdns-31.co.uk",
#     "ns-28.awsdns-03.com",
#     "ns-658.awsdns-18.net",
#   ]
# }

# resource "aws_route53_record" "ssb-ds" {
#   allow_overwrite = true
#   name            = "ssb"
#   ttl             = 1800
#   type            = "DS"
#   zone_id         = "Z2QMRHTV5AP7G6"
# 
#  records = ["4862 13 2 F9C2CD8A4F6AF7EFE48A630EE4AD53431636310D1306A7608D27C7B011CA20B9"]
# }

# staging

# resource "aws_route53_record" "ssb-staging-ns" {
#   allow_overwrite = true
#   name            = "ssb-staging"
#   ttl             = 1800
#   type            = "NS"
#   zone_id         = "Z2QMRHTV5AP7G6"
#   records = [
#     "ns-1148.awsdns-15.org",
#     "ns-1937.awsdns-50.co.uk",
#     "ns-377.awsdns-47.com",
#     "ns-965.awsdns-56.net",
#   ]
# }

# resource "aws_route53_record" "ssb-staging-ds" {
#   allow_overwrite = true
#   name            = "ssb-staging"
#   ttl             = 1800
#   type            = "DS"
#   zone_id         = "Z2QMRHTV5AP7G6"
# 
#   records = ["28358 13 2 7D70709ECEEA84A93A19277C126F2747AB5655A285731F7D31F39E24F4DD5040"]
# }


# development - actually managed in the data.gov domain, but recorded here

# resource "aws_route53_record" "ssb-dev-ns" {
#   allow_overwrite = true
#   name            = "ssb-dev"
#   ttl             = 1800
#   type            = "NS"
#   zone_id         = "Z2QMRHTV5AP7G6"

#   records = [
#     "ns-1422.awsdns-49.org", 
#     "ns-1839.awsdns-37.co.uk", 
#     "ns-297.awsdns-37.com", 
#     "ns-673.awsdns-20.net"
#   ]
# }

# resource "aws_route53_record" "ssb_dev-ds" {
#   allow_overwrite = true
#   name            = "ssb-dev"
#   ttl             = 1800
#   type            = "DS"
#   zone_id         = "Z2QMRHTV5AP7G6"

#   records = ["46864 13 2 B834DCEE0727D7864D11E31276F3BDE5B35F7D9744F3BEFF042F21B9FF864E1D"]
# }

