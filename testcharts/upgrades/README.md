# KubeCF Upgrades Charty

This is a `charty` chart which tests KubeCF upgrades.

Run it with:

```bash

$> charty start testcharts/upgrades

```

## Examples

See the `values.yaml` file for all the available testchart settings.

### Change cap version: 
```charty start testcharts/external-db --set 'cap.kubecf.from.version=foo' --set 'cap.quarks.from.version=faa' --set 'cap.kubecf.to.version=bar' --set 'cap.quarks.to.version=baz'``` 

### Test upgrade switch (from Diego to Eirini)
```charty start testcharts/external-db --set 'settings.switch_upgrade=true'``` 
