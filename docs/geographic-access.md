# United States-only website access

CloudFront permits only country code US for the entire website, including admin.html.
AWS WAF also blocks source IPs that do not match US at both the edge and regional API.
Unknown/unmapped source locations do not match US and are blocked by the WAF rule.
The regional rule prevents direct foreign requests to the execute-api endpoint.
Client-supplied X-Forwarded-For headers are not trusted for this decision.

This is IP geolocation, not citizenship or residency verification. A US VPN/proxy
can appear to be in the US. US visitors using a foreign VPN can be blocked.
The regional API sees a proxy source address when reached through CloudFront;
traffic routed through an edge outside the US can also be rejected there.
AWS-console services such as QuickSight and the Cognito hosted login are separate;
this setting restricts the website and its contact API, not the whole AWS account.

Outside-US requests receive HTTP 403. There is no public bypass or admin exception.
Health checks, SSM deployment and Terraform use separate control-plane paths.
DNS validation for the existing ACM certificate remains configured in Route 53.

To change the allowed countries, update both the CloudFront whitelist and WAF
country_codes in Terraform, review the plan and apply it. Do not edit only one layer.
