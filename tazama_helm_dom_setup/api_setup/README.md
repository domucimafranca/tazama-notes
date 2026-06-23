# Populating the Tazama configuration via API

...unfortunately this does not work properly...

For instance, updating the rules via the API, when checking on the result
in the database, it shows that config->parameters does not carry the 
maxQueryRange parameter.

So in the meantime, populate the configuration using sql.
