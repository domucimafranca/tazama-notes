# Interacting with the Tazama Beta

These are notes to help you get started with the Tazama Beta installation; they should apply to other Tazama instances as well.

Important to note that you will be interacting with Tazama as a *user*, therefore your primary interface will be the admin service, the transaction management service, and other authenticated endpoints.  As a user, you shouldn't have to be dealing with the Tazama deployment itself, not should you access the database directly.

For this guide, we'll be using shell commands with curl on Linux as they are illustrative of the actions that we take when dealing with Tazama.

These API calls are also documented in https://admin.beta.tazama.org/documentation.  However this guide presents directly executable commands. 

## Prerequisite: Getting the Token

To work with the Tazama Beta, you should have received your credentials from the Tazama Organization.  The main one we need for these steps is the username and password for generating the bearer token.

To get the token and set it as an environment variable on your session:

```
export KEYCLOAK_TOKEN=$(curl -X POST https://auth.beta.tazama.org/v1/auth/login -H "Content-type: application/json" -d '{"username": "tazama-api-client@my_org", "password": "my_org_password"}')
```

Make sure KEYCLOAK_TOKEN is properly set in your session.  Other scripts will be using this regularly for bearer authentication.

## Getting the network map

This command gets the entire network map.
```
curl -X GET https://admin.beta.tazama.org/v1/admin/configuration/network_map -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-type: application/json"
```


## Getting the rules

To retrieve the rules of a Tazama deployment
```
curl -X GET 'https://admin.beta.tazama.org/v1/admin/configuration/rule' -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-type: application/json"
```

This returns all the rules, but paginated, with the default at 20 results per page.  To get more than 20 results, set the `limit`
```
curl -X GET 'https://admin.beta.tazama.org/v1/admin/configuration/rule?limit=100' -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-type: application/json"
```

To filter for specific rules, use keys and values.  You may need to use percent-encoded characters. 
```
curl -g -X GET 'https://admin.beta.tazama.org/v1/admin/configuration/rule?keys[0][id]=002%401.0.0&keys[0][cfg]=1.0.0' \
  -H "Authorization: Bearer $KEYCLOAK_TOKEN" \
  -H 'accept: application/json'
```

It is also possible to get multiple rules
```
curl -g -X GET 'https://admin.beta.tazama.org/v1/admin/configuration/rule?keys[0][id]=002%401.0.0&keys[0][cfg]=1.0.0&keys[1][id]=017%401.0.0&keys[1][cfg]=1.0.0' \
  -H "Authorization: Bearer $KEYCLOAK_TOKEN" \
  -H 'accept: application/json'
```

## Getting a specific rule
More properly, to get the details of a single rule, use the invocation `/v1/admin/configuration/rule/{id}/{cfg}`. For example

```
curl -X GET 'https://admin.beta.tazama.org/v1/admin/configuration/rule/002@1.0.0/1.0.0' -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-type: application/json"
```

## TODO
- add the section on getting the typologies
- add links to documents explaining the rules and typologies that were set by default
