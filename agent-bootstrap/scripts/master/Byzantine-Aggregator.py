# C:/Skills/agent-bootstrap/scripts/master/Byzantine-Aggregator.py
# Implements the Multi-Krum Byzantine-robust aggregation algorithm.

import numpy as np

def multi_krum(weights_list, f, m):
    """
    Multi-Krum aggregation to filter poisoned gradients from compromised edge nodes.
    
    :param weights_list: List of numpy arrays representing the flattened model weights from each edge node.
    :param f: Expected number of Byzantine (hostile) nodes.
    :param m: Number of vectors to select and average (usually N - f).
    :return: A single numpy array representing the aggregated, safe global model weights.
    """
    N = len(weights_list)
    if N <= f + 2:
        raise ValueError("Multi-Krum requires N > f + 2.")
    
    scores = []
    
    # Calculate pairwise squared Euclidean distances
    for i in range(N):
        distances = []
        for j in range(N):
            if i == j:
                continue
            dist = np.linalg.norm(weights_list[i] - weights_list[j]) ** 2
            distances.append(dist)
        
        # Sort distances and sum the (N - f - 2) closest neighbors
        distances.sort()
        score = sum(distances[:(N - f - 2)])
        scores.append((score, i))
    
    # Sort nodes by their Krum score
    scores.sort(key=lambda x: x[0])
    
    # Select the m vectors with the lowest scores
    selected_indices = [idx for _, idx in scores[:m]]
    print(f"[MULTI-KRUM] Selected nodes for aggregation: {selected_indices}")
    print(f"[MULTI-KRUM] Filtered (potentially hostile) nodes: {[i for i in range(N) if i not in selected_indices]}")
    
    # Average the selected safe vectors
    selected_weights = [weights_list[i] for i in selected_indices]
    global_weights = np.mean(selected_weights, axis=0)
    
    return global_weights, selected_indices

if __name__ == "__main__":
    # Example execution
    print("Multi-Krum initialized. Waiting for Master Orchestrator invocation.")
