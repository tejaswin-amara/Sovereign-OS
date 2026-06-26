# Zero-Knowledge eBPF Prometheus Exporter Schema

This schema details how the `cloudflare/ebpf_exporter` safely accesses the Sovereign OS XDP kernel maps without violating the Singularity Doctrine's read-only invariants.

## 1. Map Pinning (BPF File System)
When the XDP program (`mcp_network_policy.c`) is loaded via `ip link set dev eth0 xdp obj`, the BPF maps are pinned to the `/sys/fs/bpf` file system.

```bash
# Pinning the drop-counter map during XDP load
bpftool map pin name xdp_drop_counter /sys/fs/bpf/sovereign/xdp_drop_counter
```

## 2. The Exporter Configuration (`ebpf-config.yaml`)
The Cloudflare exporter reads metrics directly from the pinned maps or via attached kprobes/tracepoints. We define the prometheus metrics mapping.

```yaml
programs:
  - name: mcp_network_policy
    metrics:
      counters:
        - name: sovereign_xdp_drop_total
          help: Total packets dropped by the XDP zero-trust kernel firewall.
          table: xdp_drop_counter
          labels:
            - name: protocol
              size: 4
              decoders:
                - name: uint
```

## 3. Read-Only Mounting Strategy
By mounting `/sys/fs/bpf` as `ro` inside the `ebpf_exporter` docker container, the exporter can execute the `bpf()` syscall strictly for `BPF_MAP_LOOKUP_ELEM`. 
It absolutely cannot execute `BPF_MAP_UPDATE_ELEM` or load new BPF programs, completely eliminating the risk of a hostile container altering the kernel firewall policy.

## 4. Capability Dropping
The `ebpf_exporter` container is stripped of `privileged: true`. It is explicitly granted only `CAP_BPF` and `CAP_PERFMON`, conforming to the principle of least privilege.
