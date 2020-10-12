# KubeCF External-DB Charty

This is a `charty` chart which deploys KubeCF with External db enabled and runs smoke tests on top.

Run it with:

```bash

$> charty start testcharts/external-db

```

## Examples

1) Run only smoke tests (by overriding runtime  options): 
```charty start testcharts/external-db --run 'commands[0].run=bash deps.sh' --run 'commands[1].run=bash login.sh' --run 'commands[2].run=bash smoke.sh'```

2) Enable/Disable HA: 
```charty start testcharts/external-db --set 'ha=false'```

See the `values.yaml` file for all the available testchart settings.