# KubeCF Upgrades Charty

This is a `charty` chart which tests KubeCF upgrades.

Run it with:

```bash

$> charty start testcharts/upgrades

```

## Examples

1) Change cap version: 
```charty start testcharts/external-db --set 'cap.kubecf.from.version=foo' --set 'cap.quarks.from.version=faa' --set 'cap.kubecf.to.version=bar' --set 'cap.quarks.to.version=baz'``` 

See the `values.yaml` file for all the available testchart settings.