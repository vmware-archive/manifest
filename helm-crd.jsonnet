// CRD and tiller, with controller running as a sidecar

local kube = import "kube.libsonnet";

// Run CRD controller as a sidecar, and restrict tiller port to pod-only
local controllerOverlay = {
  spec+: {
    template+: {
      spec+: {
        volumes+: [
          // Used as temporary space while downloading charts, etc.
          {name: "home", emptyDir: {}},
        ],
        containers+: [
          kube.Container("controller") {
            name: "controller",
            image: "bitnami/helm-crd-controller:v0.2.0",
            securityContext: {
              readOnlyRootFilesystem: true,
            },
            command: ["/controller"],
            args_: {
              home: "/helm",
              host: "localhost:44134",
            },
            env_: {
              TMPDIR: "/helm",
            },
            volumeMounts_: {
              home: {mountPath: "/helm"},
            },
          },
        ],
      },
    },
  },
};

{
  crd: kube.CustomResourceDefinition("helm.bitnami.com", "v1", "HelmRelease"),

  controllerSidecar:: controllerOverlay,
}
