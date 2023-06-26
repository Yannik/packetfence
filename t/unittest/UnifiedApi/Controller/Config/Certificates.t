#!/usr/bin/perl

=head1 NAME

Nodes

=cut

=head1 DESCRIPTION

unit test for Certificates

=cut

use strict;
use warnings;
#

BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use setup_test_config;
}

use File::Slurp qw(read_file);
use File::Copy;
use File::Temp;

my @TEMP_FILES;

sub use_temp_file {
    my ($name_ref) = @_;
    my ($fh, $filename) = File::Temp::tempfile( UNLINK => 1, DIR => '/usr/local/pf/conf');
    copy($$name_ref, $fh);
    $$name_ref = $filename;
    push @TEMP_FILES, $fh;
}

BEGIN {
    use_temp_file(\$pf::file_paths::server_cert);
    use_temp_file(\$pf::file_paths::server_key);
    use_temp_file(\$pf::file_paths::radius_server_cert);
    use_temp_file(\$pf::file_paths::radius_server_key);
    use_temp_file(\$pf::file_paths::radius_ca_cert);
}

use pf::file_paths qw(
    $server_cert
    $server_key
);

use pf::ConfigStore::Pf;
use Utils;
my ($fh, $filename) = Utils::tempfileForConfigStore("pf::ConfigStore::Pf");

#insert known data
#run tests
use Test::More tests => 34;
use Test::Mojo;
use Test::NoWarnings;

my $t = Test::Mojo->new('pf::UnifiedApi');

$t->get_ok('/api/v1/config/certificate/http/info')
  ->status_is(200)
  ->json_is('/certificate/subject', "C=CA, ST=QC, L=Montreal, O=Inverse, CN=127.0.0.1, emailAddress=support\@inverse.ca")
  ->json_is('/certificate/issuer', "C=CA, ST=QC, L=Montreal, O=Inverse, CN=127.0.0.1, emailAddress=support\@inverse.ca")
  ->json_is('/certificate/serial', '4EA79E85EEE8FDD9F59E21235DDEB940A13958A7')
  ->json_is('/chain_is_valid/success', 1)
  ->json_is('/cert_key_match/success', 1)
  ->json_is('/certificate/not_before', "Jul 20 14:00:12 2021 GMT")
  ->json_is('/certificate/not_after', "Jul 18 14:00:12 2031 GMT");


my $cert = read_file($server_cert);
my $key = read_file($server_key);

# Replacing by the valid existing ones should work fine
$t->put_ok("/api/v1/config/certificate/http" => json => { certificate => $cert, private_key => $key })
  ->status_is(200);

my $new_cert = <<EOT;
-----BEGIN CERTIFICATE-----
MIIEvDCCA6SgAwIBAgIUcYjeqGSuqVvjD6AG0VFvgCiNuEwwDQYJKoZIhvcNAQEL
BQAwdjELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAlFDMREwDwYDVQQHEwhNb250cmVh
bDEQMA4GA1UEChMHSW52ZXJzZTESMBAGA1UEAxMJMTI3LjAuMC4xMSEwHwYJKoZI
hvcNAQkBFhJzdXBwb3J0QGludmVyc2UuY2EwHhcNMjEwNzIwMTQwMjM0WhcNMzEw
NzE4MTQwMjM0WjB2MQswCQYDVQQGEwJDQTELMAkGA1UECBMCUUMxETAPBgNVBAcT
CE1vbnRyZWFsMRAwDgYDVQQKEwdJbnZlcnNlMRIwEAYDVQQDEwkxMjcuMC4wLjEx
ITAfBgkqhkiG9w0BCQEWEnN1cHBvcnRAaW52ZXJzZS5jYTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAMjafJt9cM1EM8ysf0pkPYdPDc6fIK94LrrOTDcI
qqFadqcHIhoBAoc3IJ8Qwo3CXW9+CBtpXJ0CtOWbhLZPyTwIGRn0wk2JSYPgkQf/
qXaebcMi/qERVvUJzi/7W9UhASCvkMipMxI5jH1c8CaZKg3QYpBIUCsQRBaZQCaW
cPYCeQ8f+Lq9rTMqJEeQaAluz3n/mZ7LO6opnVFNbAnb4p6ZNgkFg5INBv36xEaS
UiNbXIKUqRpqhL1++HnZp+cdOxIC3bF6YcIU4gzlKR3BGRzovQvaR/6LgrVxS2/T
FrL3UDTWXl1lal32KJt16XdqEOQBLG3ag5pBfffwMGegav8CAwEAAaOCAUAwggE8
MB0GA1UdDgQWBBSoOYdAIhcTFBqCAmTWjV0mi42P3TCBswYDVR0jBIGrMIGogBSo
OYdAIhcTFBqCAmTWjV0mi42P3aF6pHgwdjELMAkGA1UEBhMCQ0ExCzAJBgNVBAgT
AlFDMREwDwYDVQQHEwhNb250cmVhbDEQMA4GA1UEChMHSW52ZXJzZTESMBAGA1UE
AxMJMTI3LjAuMC4xMSEwHwYJKoZIhvcNAQkBFhJzdXBwb3J0QGludmVyc2UuY2GC
FHGI3qhkrqlb4w+gBtFRb4AojbhMMAwGA1UdEwEB/wQCMAAwCQYDVR0SBAIwADAL
BgNVHQ8EBAMCAuQwEwYDVR0lBAwwCgYIKwYBBQUHAwEwEQYJYIZIAYb4QgEBBAQD
AgZAMBcGA1UdEQQQMA6CASqCCTE5Mi4wLjIuMTANBgkqhkiG9w0BAQsFAAOCAQEA
oM1TGHLkUCOV3saiTMjuH6TU4FUuSJDu7Wu8uGwI1NQiyaBYiLlp+maZmdodwRbx
9iKwloCpRWY/DFXUpNIFbqlsEAkiJ8Ea4b/zPjmiKBoe4xZazhARPK89pGujuy14
sl1M22aDCKVx0m5tmxLzKXO4NSNjAZNHtGcDfpsNC1J5IrF3b8ulOv+/eST774Jj
gqXPEmjeLUzr4YXVnggRfLuDR1F4VQy5XXnkFitj9cm3a+v+wGIO/PQIyrcDGj62
QLJhJVn1WzugOPf5zb1ciR2qxNuXziq+iyYOp214aeh3bpbQtNHtHM5RQe+c2CVR
6DE7uAoOmgNe+6GU2nKVJQ==
-----END CERTIFICATE-----
EOT

my $new_key = <<EOT;
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAyNp8m31wzUQzzKx/SmQ9h08Nzp8gr3guus5MNwiqoVp2pwci
GgEChzcgnxDCjcJdb34IG2lcnQK05ZuEtk/JPAgZGfTCTYlJg+CRB/+pdp5twyL+
oRFW9QnOL/tb1SEBIK+QyKkzEjmMfVzwJpkqDdBikEhQKxBEFplAJpZw9gJ5Dx/4
ur2tMyokR5BoCW7Pef+Znss7qimdUU1sCdvinpk2CQWDkg0G/frERpJSI1tcgpSp
GmqEvX74edmn5x07EgLdsXphwhTiDOUpHcEZHOi9C9pH/ouCtXFLb9MWsvdQNNZe
XWVqXfYom3Xpd2oQ5AEsbdqDmkF99/AwZ6Bq/wIDAQABAoIBAAIVgkV6v7jhhEgT
Yh67e4fz4gjKzeQEMzfs/A12IY8bCTAietAaQpR0lfoQinQ+GAoYHK1sInHenVHk
kzPxD/13eAs05u83BXRA2EBk/rUkX68upcW2EFjqiSEmUoWbmg9kwvPSDZ2ay0Jh
vHwqCq2qA9vLZEmOGabCYFAGL5Xd2/vosgfvFT/Vb3W366GIJxNMVddPvfOfZ3co
AlvPHi9duU+boy2wW2cL4QpM+uigEYZghDhxPNoyHonc4b/fHX1DmU29HlN5nmRM
5dJkfWOAHFGHO/797cza5h1WZxKTwfF0RgHCODRnUsyMkUdYY5n/SK5oxhbCvRoi
0WaddAECgYEA88MVIH4/TbV6yaLrDxm9DzP3fco8nKZstpY0qHl6ZrvzrMPyG2oT
4axCK5G5tZxbSpeTPs97hXWvhKZHM5JGf/I4HLLsDuZbTIEObd3qWwzl0aI6Hvcb
b+8fHp+dS8FmbELJBjTW+NKXso9noSdZYXbUOsqpxFVXfZuH6H9nuL8CgYEA0u/t
gKh/bvUlFC9rnaj/1A6JL4osQ2UcHXwMJYPHIhpmCMS4AUG/guiUbDcY6LkUV8YY
iAykuLeh/+FX3vcmB8gKikdurPzgCMbV7rdwbL+inH1e1V4N5IzVkx/TwYoZutSb
Gab3Hbu8IEKBjBw8wJlEB5aYdyl/Iqq+SmEfncECgYEAthfsJ1rH9Uf1kr0GdUBX
8Ax0/F3gC3FzUq5AZf5hRm9vJ4c0y+/hLDsfLybsINPNippSX6Bk+JyiYihIlijW
S2vpKN8r4jGI0Ey0N7SIBj5LS9+xJUKZF3P8vkakHVw7I/J78wvz7up6ceQYmNUp
OtqmzchpK4ZJFkbiLvdFx0cCgYEAm7jgv0Clg0abLwGrEuN2qhhpEp2Q+9gjH2k6
ll9onTab6RFBPjxJo90L5a/vRa+M4xeteJLM8Ekw4XR8qHAQtWHq1hbSEAdHZXNU
8DygVMhMxfaQEjizTOzjpw+yBolrYVAfiJqIiHzV74LpnIQkHZOIc4mr2RzbbL5c
aRC2hIECgYBIoOXW3olhd6Kt6V3LXu3mO/pB0X2IZ47+OR2rvmfhDSsT38xWw6VE
n61QRhBqEMOFDMjt4zynyoIN0pJiHZCDkP41joe0IByUeMq5X3KYC/FB50gasu/e
X1l9tlAkxFEeHfW2Er7Whj5x6X35irHGRFb/L1bdcXQqBtwHrG4pIQ==
-----END RSA PRIVATE KEY-----
EOT

# Replacing by a new cert for a different key shouldn't be valid
$t->put_ok("/api/v1/config/certificate/http" => json => { certificate => $new_cert, private_key => $key })
    ->status_is(422);

# Replacing by a new key that doesn't match the cert shouldn't be valid
$t->put_ok("/api/v1/config/certificate/http" => json => { certificate => $cert, private_key => $new_key })
    ->status_is(422);

# Replacing with a new self-signed should be valid
$t->put_ok("/api/v1/config/certificate/http" => json => { certificate => $new_cert, private_key => $new_key })
    ->status_is(200);

my $radius_cert = <<EOT;
-----BEGIN CERTIFICATE-----
MIID2jCCAsKgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBkzELMAkGA1UEBhMCRlIx
DzANBgNVBAgMBlJhZGl1czESMBAGA1UEBwwJU29tZXdoZXJlMRUwEwYDVQQKDAxF
eGFtcGxlIEluYy4xIDAeBgkqhkiG9w0BCQEWEWFkbWluQGV4YW1wbGUub3JnMSYw
JAYDVQQDDB1FeGFtcGxlIENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0yMTA5MDYw
ODA5MjZaFw0yNjA5MDUwODA5MjZaMHwxCzAJBgNVBAYTAkZSMQ8wDQYDVQQIDAZS
YWRpdXMxFTATBgNVBAoMDEV4YW1wbGUgSW5jLjEjMCEGA1UEAwwaRXhhbXBsZSBT
ZXJ2ZXIgQ2VydGlmaWNhdGUxIDAeBgkqhkiG9w0BCQEWEWFkbWluQGV4YW1wbGUu
b3JnMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1QdPxaniWPX1nkf0
WMV0i5/0EtCrBUJNnL50CMl0lhZWt00leTKPbNZQupLWd+cYcUrjgCFkGBO4kiw6
fznkRIfHEglWzpU8pArzAVY7OxKT1DOH3mxO0nwoDxBHGo6usB8oa58suwG0nvEs
1ug4v3RVDcYC74UljPMwRqTswUIABQIsMcqiOr2zFxh+EYqgF+zU6DmvYj58d7hg
e/RRvVDFzfEMIL+emjMjhhPZyo3uS/BVD8vxcSXcg4QEeowy9KdWsY8E4kYK7T5W
1GLYvsvl+uPIy+UGeEsPSeJ3tKrExf63QAyi1ugZNIefzm78IYRMkebSKPDGqWq4
REl1sQIDAQABo08wTTATBgNVHSUEDDAKBggrBgEFBQcDATA2BgNVHR8ELzAtMCug
KaAnhiVodHRwOi8vd3d3LmV4YW1wbGUuY29tL2V4YW1wbGVfY2EuY3JsMA0GCSqG
SIb3DQEBCwUAA4IBAQCsRAYFF4CnpwfVhgZwQzSVgvZ694X6AOSwScUbVR+CyWwf
8e4LGh2UPg1kETx3h8Pn4AUppKkP6eJqy/XOtfEVkZ2zfX0RNpw2wwq7V+UMO8jE
ybQGzOzL3Od0yImGd/i044lh4Pjdy9yMPUrTyqok89HOOpSHacuFK8jolw57U/2s
2XCCcA7aLt8Auk1n2uTHR/dDCygwIUKMr2vCfqpDpD3Z1/+jDr+lGfj53WvVXpGC
5iLT/VRFlbF3diz1kaJID9NgbCbI12CgFEtgYgoqUrsuTy/ReCNHeftfh5/DOgaS
3PEPL06fEGfvXy9vJPg+dj4jDOhQN3oDdJBTfc20
-----END CERTIFICATE-----
EOT

my $radius_key = <<EOT;
-----BEGIN PRIVATE KEY-----
MIIEwAIBADANBgkqhkiG9w0BAQEFAASCBKowggSmAgEAAoIBAQDVB0/FqeJY9fWe
R/RYxXSLn/QS0KsFQk2cvnQIyXSWFla3TSV5Mo9s1lC6ktZ35xhxSuOAIWQYE7iS
LDp/OeREh8cSCVbOlTykCvMBVjs7EpPUM4febE7SfCgPEEcajq6wHyhrnyy7AbSe
8SzW6Di/dFUNxgLvhSWM8zBGpOzBQgAFAiwxyqI6vbMXGH4RiqAX7NToOa9iPnx3
uGB79FG9UMXN8Qwgv56aMyOGE9nKje5L8FUPy/FxJdyDhAR6jDL0p1axjwTiRgrt
PlbUYti+y+X648jL5QZ4Sw9J4ne0qsTF/rdADKLW6Bk0h5/ObvwhhEyR5tIo8Map
arhESXWxAgMBAAECggEBAIFtwc/smbNHLQYP3auZvGegtWBBG8dEM3eKV2GHVKhj
xif0XVI3n+CWjdHtqRSMedNLltGgd/oQ8VEOQjRObhwdCpwwxGcbUQ6yAFbNl4sa
jGqfLGu9Dl7gRE5yq2C9U/F53MsWmMy+ComPKpkf2mqoOYz2w43XLatnjes+BQKd
BRykqosfeFdx9Oeo6MuzMZUUIjmza7LQBOtKHnC2GZdzNEjP3x2gsoJROJeuotUC
RwR2qmuZCZ8tumkE0t9ycOTs76P8A1EoqAgFGZxYc9tzqCZx4dYPfWkTrV/LzWm5
mWE3dNDRp28oUSmnD0d9iuilooVK5Ul+gJHeLksBrmECgYEA75m1Cbe6EqmXl0ir
JxLaBrNcRus2Tu7fyV2JYdhvXIGeS/SAUQli9fxV4lYMBcWhCUH6l9uT30MqGofG
3zprdrhTeqLOERRxeUisZe9+FfmgQ+61coHFbGjTCSGzxP1ht0yabZnrgddZ3Z74
FEduUIU8uHGJISQ0HULzlRSpqm0CgYEA45wCwOHR5FMKVP2X4ry5zDHuAHtF7GNm
xse9szsrSytjMS+UF5k764aa34jI8mFliHPxF2rlmgCsmnorKeC43/yDC/McM2hT
UgcIgvuw+nK5jg1MqyFdxq0BF8N+JJ6hDJTqm4Eh6WFIJt6OmbGi2iTpHM5vcgJi
nPn/wg7frdUCgYEAgIz9XtteUAkBtj9c5Lfulk3BIqOsHal4E/fFb+PJy94XajUi
a1gX6laaVbdI+AfSoL7vjm5W5iCJBHb4smgLpES9NT0IRo2rXCErrf1SrsOhwxDd
9TO/Eq0jHPEiHHy94rSM3mUIwD8kjg1umKLCgx0ZOPRhWJCuDU0Ql1ngtfkCgYEA
ksTDMcVsJyM1AmEUU+0GkhmQM1dKW4gtefjK5ow8+pfbupfHkwAIl3OQ4pu9mC4d
3sOEr2kK7SeKJYKp2rNCA408o7P8d1nKgJZwcqYCFT1tUaBZ0/AMHFTq43v4F30C
tK5CKkw2pdtJP2c75Pea37f1adHkI0xOcpLyzRvyOJECgYEAiPuliNX4+PNH67Qe
sPtzt+i3pHFBkRY6Opjdnd5is2oGyUaD9GzYHDm5Qmu7m7zpQSYXGerG5djSSXgJ
mqQDYX8dcGfc7L7M94SjqbvkeEK7yy+X8Y/eSHI8EWasTetlAfaSAEFiLd+aA0xK
ZO87PsLqYGne7mG+7DpUuTuSMc4=
-----END PRIVATE KEY-----
EOT

my $radius_ca_cert = <<EOT;
-----BEGIN CERTIFICATE-----
MIIE+jCCA+KgAwIBAgIUD/HDoiLKZeBrForMLnsrr1RrhtowDQYJKoZIhvcNAQEL
BQAwgZMxCzAJBgNVBAYTAkZSMQ8wDQYDVQQIDAZSYWRpdXMxEjAQBgNVBAcMCVNv
bWV3aGVyZTEVMBMGA1UECgwMRXhhbXBsZSBJbmMuMSAwHgYJKoZIhvcNAQkBFhFh
ZG1pbkBleGFtcGxlLm9yZzEmMCQGA1UEAwwdRXhhbXBsZSBDZXJ0aWZpY2F0ZSBB
dXRob3JpdHkwHhcNMjEwOTA2MDgwOTI2WhcNMjYwOTA1MDgwOTI2WjCBkzELMAkG
A1UEBhMCRlIxDzANBgNVBAgMBlJhZGl1czESMBAGA1UEBwwJU29tZXdoZXJlMRUw
EwYDVQQKDAxFeGFtcGxlIEluYy4xIDAeBgkqhkiG9w0BCQEWEWFkbWluQGV4YW1w
bGUub3JnMSYwJAYDVQQDDB1FeGFtcGxlIENlcnRpZmljYXRlIEF1dGhvcml0eTCC
ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOyJFEiScMsOM5Y91E1jEpc+
jJZMhx/6z+G8RmOwM5FXdCed1rb0f6kHtw4wWnUdvJ6hN5pbLgXKe0mPTDw8quE5
BXUT3BRNdYHATw8ZlHbf5FoxQ1nqI8En6ORDPjt4x0RyJsCueBbsZku0m6eyV9zb
vNEcx4aRMFcIFxHFs/2ai9EVloVxD/5BcloYxWPp1STYtsmLBPJrtxBGG+qoFvYl
eTAJH11s0447qHq+KU7PeyDp+McEzlm2QaeauoC9d0nTkt0fzfYGgI60MCC/GZDV
F9ezhpXojOJNOH3dkln47EsEvypdL7XA1ALE20iqf79dTBQHBbVjJY9NpSdFC9UC
AwEAAaOCAUIwggE+MB0GA1UdDgQWBBRuYmWCYEg30hNGn2GAlkq5tCdi9TCB0wYD
VR0jBIHLMIHIgBRuYmWCYEg30hNGn2GAlkq5tCdi9aGBmaSBljCBkzELMAkGA1UE
BhMCRlIxDzANBgNVBAgMBlJhZGl1czESMBAGA1UEBwwJU29tZXdoZXJlMRUwEwYD
VQQKDAxFeGFtcGxlIEluYy4xIDAeBgkqhkiG9w0BCQEWEWFkbWluQGV4YW1wbGUu
b3JnMSYwJAYDVQQDDB1FeGFtcGxlIENlcnRpZmljYXRlIEF1dGhvcml0eYIUD/HD
oiLKZeBrForMLnsrr1RrhtowDwYDVR0TAQH/BAUwAwEB/zA2BgNVHR8ELzAtMCug
KaAnhiVodHRwOi8vd3d3LmV4YW1wbGUub3JnL2V4YW1wbGVfY2EuY3JsMA0GCSqG
SIb3DQEBCwUAA4IBAQCc9Jd89nzOmdkYdRPsaQBGJSoWO1AIQz1sbHNVxpuMu+9e
i070jfP6LVcf+XKQUFJFGw2o6cOiDG9sxWNe5UM72QoenH2bBrjUxw7J5aA2u3Ap
bdJ5vhHENWPxkKGtv7CZOuqlWq0ThRcy0XEAzfqi42tEaGCQlxocfkJYAL4YlFfo
2pFYM18d68EPxKiPOJNJmatqqRoQfhpda7QovUo/FFIBeg/QlwDmqx1OeC7j+m2F
xvUqFefN8kWzUGXts4Okz53z18q2GhhJKS8NKua/8bOhI7jSWoJ4BaDiz5aqEq4B
b6eY3BSmAxkBiwX6V7JRn/Z+KKYAO/3HYpNBHfqE
-----END CERTIFICATE-----
EOT

my $new_radius_cert = <<EOT;
-----BEGIN CERTIFICATE-----
MIID2jCCAsKgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBkzELMAkGA1UEBhMCRlIx
DzANBgNVBAgMBlJhZGl1czESMBAGA1UEBwwJU29tZXdoZXJlMRUwEwYDVQQKDAxF
eGFtcGxlIEluYy4xIDAeBgkqhkiG9w0BCQEWEWFkbWluQGV4YW1wbGUub3JnMSYw
JAYDVQQDDB1FeGFtcGxlIENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0xOTAxMDkx
OTMyMTdaFw0yNDAxMDgxOTMyMTdaMHwxCzAJBgNVBAYTAkZSMQ8wDQYDVQQIDAZS
YWRpdXMxFTATBgNVBAoMDEV4YW1wbGUgSW5jLjEjMCEGA1UEAwwaRXhhbXBsZSBT
ZXJ2ZXIgQ2VydGlmaWNhdGUxIDAeBgkqhkiG9w0BCQEWEWFkbWluQGV4YW1wbGUu
b3JnMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAy+miYZFdBYI22KwG
aBbDf7a4bcCFnpgMKllIoPXRD3XSSc/+F0M8jbai4dUcUmdyf8BkWQAkEcA0rFSq
1IlDep4GWWDjrIGhAtJMxM1lsj/6YHeMJSnvZGcNz7eo8e2ZId3m9P7LjzVOFtay
CnSZAwDvYKLB5sYoH9AVPv2Un15HBjTbKRb9aNlRdV9MZekOG0SzE+CNp3jQRhyG
fTsmh49BqbgvVO7UA+Ryg5O6lv+pib2b0S/0GgIfsrtTlt99248dEX7kXEZksSwX
AgVaGHKkYeC+YX+gY2S/u1BXz0WJJWtgusDvGtHDV/7FR3uuL6zjQoT5Ehh2kXn2
XpuT5wIDAQABo08wTTATBgNVHSUEDDAKBggrBgEFBQcDATA2BgNVHR8ELzAtMCug
KaAnhiVodHRwOi8vd3d3LmV4YW1wbGUuY29tL2V4YW1wbGVfY2EuY3JsMA0GCSqG
SIb3DQEBCwUAA4IBAQAK+yTKrnuzAHNDIp+/+24PkfowWmZjvyD2/QZzBQ3ZQKYv
vr0H+ZfwKUyFuONNpk6+/cTyZ5hcZmTkt0Vz03/NGijU4dZz95VfBgN2FHJctAAW
UMTmUoSbQDuIPBb2tDHSYdH1DLQc/4PYtBs5cemZifW71pDxExd6BUFSDb+FBplx
2ztuFzrhlkjV8RjpFwl9BuWzLErujkNFcQ9e6G3U7GzUqvm5lrryMXlx8UpDIG1M
E1xs+U8OHyvkI2LC1qC2OANcvFagDvEnUfgoFFJH4hzkUDaA9OnUFX0Yvb/ueibh
t10PDs55riv8WXJlBU0wGcd42kk2yWdLx8wQpMRZ
-----END CERTIFICATE-----
EOT

my $new_radius_key = <<EOT;
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDL6aJhkV0FgjbY
rAZoFsN/trhtwIWemAwqWUig9dEPddJJz/4XQzyNtqLh1RxSZ3J/wGRZACQRwDSs
VKrUiUN6ngZZYOOsgaEC0kzEzWWyP/pgd4wlKe9kZw3Pt6jx7Zkh3eb0/suPNU4W
1rIKdJkDAO9gosHmxigf0BU+/ZSfXkcGNNspFv1o2VF1X0xl6Q4bRLMT4I2neNBG
HIZ9OyaHj0GpuC9U7tQD5HKDk7qW/6mJvZvRL/QaAh+yu1OW333bjx0RfuRcRmSx
LBcCBVoYcqRh4L5hf6BjZL+7UFfPRYkla2C6wO8a0cNX/sVHe64vrONChPkSGHaR
efZem5PnAgMBAAECggEBAIFCsTS4OQds6+ed5NHG3FbxNSgdipZmPA/8WRXvvX7X
aV5xAtksPg53X/lYZoO2H9br1rC0bijydnFnmoLwIF5yHgQ6bxjDc5WeShvXOEgu
VkEghy5nzuEOkqrB+c6ilxfo2qcjfVZirAW+Q05tazGEPjo78j6gDn9cIJu1k6kR
rzPJq6fYiFEHb832YaWmW14lpXvpMX1+CKMEdyxW+M31wH2Q6d7zVx+GqDrC1j5+
fogI2RgzByUdx5rI7fW8wVWTbWyceXJsST6avEfhLTiLJEvElrT+kG0kWDaCAA80
yhiYhR7TVakuYbVwxfUnO0vo3eeP3rHAua/kT78b0EECgYEA/R+BDwGk7cmvBwX3
Kko2D6owNPckdB/Wg5cKZTTGzTK9cFLpBi5XoI52nADOmISLDuy4f+bwDiwzhxeJ
M5wrOwPejAyBgv0hzq0odhuIqfo7t7JMcgb6nIfcTQXiii+IYYGajFj48CVP04uW
imw90C3IrISGIRNTl912Ts1I2IsCgYEAzjryHMt7CDexKZ6LxwgUM5sGkYaVd3+N
XBt+OaF/HQKzENzW52OjPcsfA2lplQZZNoybmzGbP/HRrDkXWhvdSDOZehiZK9d9
ve21FJWnyqEYoFTRXLXiTRcalMFk/OR6f0HMAzfgOPQzcBhodJib+QC7YndRLkFS
369xJU23AZUCgYEAryC/60EI+lhDF8nh00mbE8V9KvgfKZTplwvGbnVQYqKLfQ5w
GQ2xJO3MVG0eg1mY2I+hqyR9zGB6mioHjEStiFxJ+n2gkZ9PZ65YQzcTm/78mEDt
MStw8yHwov3CWjc+1a+U3SuluIkoLMX0Nvti3QkAQZRDNNkpSfY4p5bSorcCgYAl
oQ/IPUCHsVG8HFe4yzqUZ/b82qevFDEA22terJ769iEiNIlp0v5YKhXQk41WScBB
ecpyuMxxEHiHiis+n9Lyd6fLZW2dWEZzP0pJJT1mdZp+trs0xWMzWcHZ3qfElRPc
4G6PL8TT34r7Kxj0HVxoRL/sKYVAgV7TvblRayq3OQKBgEL2yHVP6vhr8IqGmlN0
+0605/GpnAODBU6W32zSzpw/3sE7TunTGkXqeVimPjUdkGJmAXr6HwfaaeYfCn4x
AI7JqfyX5HWLrqa4Ja6YtC9IKFQ9HIt8HO1AmTIq0NpyuuX04QAOpYkhrkOq7LSz
wq6IWJCpe1N0QBxucRkbu0ll
-----END PRIVATE KEY-----
EOT

my $new_radius_ca_cert = <<EOT;
-----BEGIN CERTIFICATE-----
MIIE5DCCA8ygAwIBAgIJAOOFxlLSB8QIMA0GCSqGSIb3DQEBCwUAMIGTMQswCQYD
VQQGEwJGUjEPMA0GA1UECAwGUmFkaXVzMRIwEAYDVQQHDAlTb21ld2hlcmUxFTAT
BgNVBAoMDEV4YW1wbGUgSW5jLjEgMB4GCSqGSIb3DQEJARYRYWRtaW5AZXhhbXBs
ZS5vcmcxJjAkBgNVBAMMHUV4YW1wbGUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4X
DTE5MDEwOTE5MzIxN1oXDTI0MDEwODE5MzIxN1owgZMxCzAJBgNVBAYTAkZSMQ8w
DQYDVQQIDAZSYWRpdXMxEjAQBgNVBAcMCVNvbWV3aGVyZTEVMBMGA1UECgwMRXhh
bXBsZSBJbmMuMSAwHgYJKoZIhvcNAQkBFhFhZG1pbkBleGFtcGxlLm9yZzEmMCQG
A1UEAwwdRXhhbXBsZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQC4I76eNx3PEX9GGivyiSbBEjnlyQZ2heG/EwC6
Xa3j0nOvT5EQBHiGKZCsjLxxsedHRjEfb5iFdh1vgbqksMTa6zh2dR6XUsEx7k5y
4k2d9lmrgLPye+bMjFjWJazKYSgDuIPYt/7xcVbVnSdZyeHHhg+UEHfeUZlQD3Ca
MlW3gCXC1rfNWiOi5cxvrAomc1wh6UGY4wyRh7ZtqhgDOGYrhZDzW9rfaXcm3dJI
FlFohzQPc48k7vVjm95q1v6c8P8yXu0l8bE1tC7JI/HMMjW91gXnD4GHthS0W7vN
4iJxjOEJliVpwE4iRmH7Stc55WqoQ/21z8s2OabUWuhJEaVzAgMBAAGjggE3MIIB
MzAdBgNVHQ4EFgQUk2Kcoim0WMIpRC37TCOwvhINFW8wgcgGA1UdIwSBwDCBvYAU
k2Kcoim0WMIpRC37TCOwvhINFW+hgZmkgZYwgZMxCzAJBgNVBAYTAkZSMQ8wDQYD
VQQIDAZSYWRpdXMxEjAQBgNVBAcMCVNvbWV3aGVyZTEVMBMGA1UECgwMRXhhbXBs
ZSBJbmMuMSAwHgYJKoZIhvcNAQkBFhFhZG1pbkBleGFtcGxlLm9yZzEmMCQGA1UE
AwwdRXhhbXBsZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmCCQDjhcZS0gfECDAPBgNV
HRMBAf8EBTADAQH/MDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly93d3cuZXhhbXBs
ZS5vcmcvZXhhbXBsZV9jYS5jcmwwDQYJKoZIhvcNAQELBQADggEBAJWYhQFlvbGR
H+Cf112EB7aeABXjiiIDbtrU1jxHytRGSqNf2JOjikHrjTSsJeZCNdve5tPAkW7m
+1fxx4Ba5P/aTRwmmk0nzgakqHh6nw6WpO6WuIY0wXnG5HnhJbvNJ/FHUKt7gUNZ
yFp4aqwaTji9jUqbGzqpQlqFWwmqVnsvm2Yq/8PGUzbbMcZ6BBHjTl7UgtW+oRKT
Dx5o7pL8v9UIExHulivegGBS0Bee9lLcZ05mWeYyJIQ4p7KqLFGu/Jd/2cGYk97o
m8ZbKzanpO0Edoe9qddtxT/Ei+fNcPZgCN+X/0D5m/JuGcHE7fFWlkXmxUzNXsCa
AONIqvjkLq0=
-----END CERTIFICATE-----
EOT

# Replacing by the valid existing ones should work fine
$t->put_ok("/api/v1/config/certificate/radius" => json => { certificate => $radius_cert, private_key => $radius_key, ca => $radius_ca_cert })
  ->status_is(200);

# Provide cert from another CA without chain check ignore flag
$t->put_ok("/api/v1/config/certificate/radius" => json => { certificate => $new_radius_cert, private_key => $new_radius_key, ca => $radius_ca_cert })
  ->status_is(422);

# Provide cert from another CA with the chain check ignore flag set to false
$t->put_ok("/api/v1/config/certificate/radius?check_chain=false" => json => { certificate => $new_radius_cert, private_key => $new_radius_key, ca => $radius_ca_cert })
  ->status_is(200);

# Provide cert from another CA with the chain check ignore flag set to true
$t->put_ok("/api/v1/config/certificate/radius?check_chain=true" => json => { certificate => $new_radius_cert, private_key => $new_radius_key, ca => $radius_ca_cert })
  ->status_is(422);

# Provide cert from another CA with the new CA
$t->put_ok("/api/v1/config/certificate/radius" => json => { certificate => $new_radius_cert, private_key => $new_radius_key, ca => $new_radius_ca_cert })
  ->status_is(200);

# test CSR with missing information
$t->post_ok("/api/v1/config/certificate/radius/generate_csr" => json => {})
  ->status_is(422);

# test CSR with valid information
$t->post_ok("/api/v1/config/certificate/radius/generate_csr" => json => {
        "country" => "CA", 
        "state" => "Quebec", 
        "locality" => "Montreal", 
        "organization_name" => "Inverse Inc.", 
        "common_name" => "csrtest.inverse.ca",
    })
  ->status_is(200);

# test CSR with extra information
$t->post_ok("/api/v1/config/certificate/radius/generate_csr" => json => {
        "country" => "CA",
        "state" => "Quebec",
        "locality" => "Montreal",
        "organization_name" => "Inverse Inc.",
        "common_name" => "csrtest.inverse.ca",
        "subject_alt_names" => "csrtest1.inverse.ca,csrtest2.inverse.ca",
    })
  ->status_is(200);

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2023 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;
