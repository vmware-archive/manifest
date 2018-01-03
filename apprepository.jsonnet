local kube = import "kube.libsonnet";
local kubecfg = import "kubecfg.libsonnet";

local labels = {
  app: "apprepository-controller",
};

{
  namespace:: {metadata+: {namespace: "kubeapps"}},

  crd: kube.CustomResourceDefinition("apprepositories.kubeapps.com") {
    spec+: {
      group: "kubeapps.com",
      version: "v1alpha1",
      names: {
        kind: "AppRepository",
        plural: "apprepositories",
        shortNames: ["apprepos"],
      },
    },
  },

  serviceaccount: kube.ServiceAccount("apprepository-controller") + $.namespace,

  role: kube.Role("apprepository-controller") + $.namespace {
    rules: [
      {
        apiGroups: [""],
        resources: ["events"],
        verbs: ["create"],
      },
      {
        apiGroups: ["batch"],
        resources: ["cronjobs"],
        verbs: ["create", "get", "list", "update", "watch"],
      },
      {
        apiGroups: ["batch"],
        resources: ["jobs"],
        verbs: ["create"],
      },
      {
        apiGroups: ["kubeapps.com"],
        resources: ["apprepositories"],
        verbs: ["get", "list", "update", "watch"],
      },
    ]
  },

  rolebinding: kube.RoleBinding("apprepository-controller") + $.namespace {
    roleRef_: $.role,
    subjects_: [$.serviceaccount],
  },

  deployment: kube.Deployment("apprepository-controller") + $.namespace {
    metadata+: {labels+: labels},
    spec+: {
      template+: {
        spec+: {
          serviceAccountName: $.serviceaccount.metadata.name,
          containers_+: {
            default: kube.Container("controller") {
              image: "kubeapps/apprepository-controller@sha256:e3b1fdff556ba25466a2dc1fc886580f553a2b3f6a547171ccf2c25616106b5f",
              command: ["/apprepository-controller"],
              args: ["-logtostderr"],
            },
          },
        },
      },
    },
  },

  _apprepo(name, url):: kube._Object("kubeapps.com/v1alpha1", "AppRepository", name) + $.namespace {
    spec: {
      url: url,
      type: "helm"
    },
  },

  apprepos: {
    stable: $._apprepo("stable", "https://kubernetes-charts.storage.googleapis.com"),
    incubator: $._apprepo("incubator", "https://kubernetes-charts-incubator.storage.googleapis.com"),
  },
}
