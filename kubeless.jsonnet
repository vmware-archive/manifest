local k = import "ksonnet.beta.1/k.libsonnet";
local kube = import "kube.libsonnet";
local container = k.core.v1.container;

local kubeless = import "vendor/kubeless/kubeless-rbac.jsonnet";

kubeless {
  ns: kube.Namespace("kubeless"),
  controller+: {spec+: {template+: {spec+: { containers: kubeless.controller.spec.template.spec.containers[0] + { image: "bitnami/kubeless-controller@sha:6547d4e088ad5171dff69da4c9e52e77e6d0b00cf25f8b57c3260de816587266" } } } } },
}
