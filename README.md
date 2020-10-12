# kubecf-charty

In this repository you will find several `charty` for running KubeCF tests.

## Requirements

- [charty](https://github.com/mudler/charty)
- A k8s cluster, kubectl, and helm (depends on the `charty` you want to run)

Test charts are under the `testcharts/` folder. If you clone this repository locally, they can be run individually with:

```charty run testcharts/<testchart>```

Each chart setting can be tweaked via cli with ```--set``` or ```--values```, see [charty](https://github.com/mudler/charty) docs for more examples on how to use it.


