# ZK-SNARK Payload Integration Schema for Sovereign Edge

This schema defines how a constrained Edge node generates a Zero-Knowledge Proof (ZK-SNARK) to attest to the statistical bounds of its proprietary agricultural training data, bundling it into the payload for the Central Orchestrator.

## 1. Circuit Definition (Circom)
The circuit defines the bounds for valid training inputs (e.g., Soil pH must be between 0 and 14).

```circom
pragma circom 2.0.0;

template InBounds(minVal, maxVal) {
    signal input x;
    signal output out;
    
    // Constraint logic to ensure x is within [minVal, maxVal]
    // ...
    out <== 1;
}

component main = InBounds(0, 14);
```

## 2. Compilation & Proving (snarkjs)
1. **Setup**: The Master Orchestrator performs a trusted setup, generating a proving key (`proving_key.zkey`) and verification key (`verification_key.json`). The proving key is deployed to the Edge.
2. **Witness Generation**: The Edge node computes the witness using its private data inputs.
3. **Proving**: The Edge node uses `snarkjs groth16 prove` to generate `proof.json` and `public_signals.json`.

## 3. Payload Bundling Structure
The output payload directory `C:/workspace/weights` will contain:
- `model_weights.pt`: The federated model updates (PyTorch/ONNX).
- `proof.json`: The ZK-SNARK proof.
- `public_signals.json`: The public signals corresponding to the proof.

## 4. Algorand Layer-1 Cryptographic Signature
The `Sign-EdgeState.ps1` script hashes the entirety of the payload bundle (including the `proof.json`). The resulting hash is committed to the Algorand blockchain.

1. Master fetches the transaction Note from Algorand.
2. Master downloads the payload via the `mcp-federated-tunnel`.
3. Master verifies the payload hash against the Algorand Note.
4. Master runs `snarkjs groth16 verify` against the `proof.json`.
5. Only if the proof is mathematically sound does the payload proceed to the Multi-Krum aggregation phase.
