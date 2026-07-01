# Message Report for an Alert Scenario

What does a message report for an alert scenario look like?  We can trigger an alert
by using the `trigger_send.sh` script of `test_rule_901_902`.  This test was for
the Full Stack Docker setup, but does just as well for the Tazama Beta.  Tazama Beta
does not utilize Rule 901 and 902, however; but the transactions in the script 
will trigger another typology.

## Analysis of the Result

Typology 095 was the primary typology triggered.  This is described as "Duplication of payments from a single account", which is essentially
what the script does.

This also triggered a secondary typology, Typology 124.  This is described as "Large/frequent cash deposits into accounts.  This risk
can also occur when there are rapid deposits of the same amount into the account."

