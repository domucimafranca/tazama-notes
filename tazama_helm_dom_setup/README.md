# Configuring Tazama Helm Testbed

This set of configuration scripts pertains to the Tazama Helm chart
in https://github.com/domucimafranca/tazama-helm-dom.

This in turn is based from https://github.com/tazama-lf/Full-Stack-Docker-Tazama.

For now the best way to populate the configuration is directly via SQL.

`psql -h localhost -p 5432 -U postgres -d configuration -f test_config.sql`
