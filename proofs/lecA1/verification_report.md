# Proof Export

## Node 1

**Statement:** The covariant distributional energy-momentum tensor T^{αβ}, defined as a proper-time integral of p^α (dγ^β/dτ) δ^{(4)}(x − γ(τ)) along timelike worldlines, satisfies four rigorous properties:
(1) Well-definedness: T^{αβ} is a distribution of order zero (tensor-valued Radon measure) on R^4.
(2) Equivalence of forms: Via the one-dimensional coarea formula (Federer 3.2.12), the covariant form reduces to the 3+1 coordinate-time expression T^{αβ}(x) = Σ_j p_j^α (dγ_j^β/dt) δ^{(3)}(x − γ_j(t)) in the distributional sense.
(3) Lorentz covariance: T^{αβ} transforms as a rank-2 contravariant tensor under Lorentz transformations.
(4) Conservation: For free particles (dp^α/dτ = 0), ∂_β T^{αβ} = 0 in the distributional sense, proved via integration by parts on test functions without manipulating derivatives of delta functions.
Additionally, the construction generalises to slicing by arbitrary spacelike hypersurfaces via the slicing theorem for currents (Federer 4.3.2).

**Type:** claim

**Inference:** assumption

**Status:** pending

**Taint:** unresolved

### Node 1.1

**Statement:** REFERENCE VERIFICATION: All citations to Federer 1969 and Weinberg 1972 in lecA1.tex must be string-matched against primary sources. Specifically: a. Theorem 3.2.12 of Federer is the coarea formula, b. Theorem 4.3.2 is the slicing theorem, c. Section 4.1 discusses currents, d. Weinberg Section 2.8 discusses conservation with delta functions. Each citation must match the actual theorem number, section, and mathematical content.

**Type:** claim

**Inference:** assumption

**Status:** pending

**Taint:** unresolved

### Node 1.2

**Statement:** WELL-DEFINEDNESS: The functional T-action-on-phi = Sum_j Integral p_j-alpha times gamma-dot_j-beta times phi-of-gamma_j-of-tau d-tau defines a distribution of order zero on R4. Proof requires: timelike future-directed implies gamma-zero-of-tau is a diffeomorphism implies gamma is proper; integrand has compact support in gamma-inverse-of-K; bound by C_K times sup-norm of phi.

**Type:** claim

**Inference:** assumption

**Status:** pending

**Taint:** unresolved

### Node 1.3

**Statement:** COAREA FORMULA STATEMENT: States Federer 3.2.12 for f Lipschitz from Rn to Rm with m leq n. Then gives 1D corollary. CRITICAL: Federer 3.2.12 requires m strictly greater than n. The 1D case m=n=1 does NOT satisfy this hypothesis. The 1D formula is actually the area formula or elementary substitution, not coarea proper. The attribution to 3.2.12 for the 1D case is incorrect.

**Type:** claim

**Inference:** assumption

**Status:** pending

**Taint:** unresolved

### Node 1.4

**Statement:** EQUIVALENCE THEOREM: The covariant form equals the 3+1 form distributionally. Proof: Step 1 factor out f-prime = d-gamma-zero/d-tau via chain rule; Step 2 apply change of variables for the diffeomorphism f; Step 3 identify spatial delta function via sifting property. Each step must be verified for distributional rigour.

**Type:** claim

**Inference:** assumption

**Status:** pending

**Taint:** unresolved

### Node 1.5

**Statement:** LORENTZ COVARIANCE: Under Lorentz transformation, T transforms as a rank-2 contravariant tensor. Proof: p-alpha is a 4-vector, gamma-dot-beta is a 4-vector, phi is scalar, d-tau is Lorentz-invariant, abs-det-Lambda = 1. Verify that the distributional definition makes this manifest.

**Type:** claim

**Inference:** assumption

**Status:** pending

**Taint:** unresolved

### Node 1.6

**Statement:** CONSERVATION LAW: For free particles, partial-beta T-alpha-beta = 0 distributionally. Proof uses distributional derivative, chain rule on test functions, integration by parts. Boundary terms vanish by compact support of phi and properness of worldline. Verify each step and the treatment of boundary terms.

**Type:** claim

**Inference:** assumption

**Status:** pending

**Taint:** unresolved

### Node 1.7

**Statement:** GENERAL SLICING THEOREM: For Sigma = level set of f with grad-f timelike, T restricted to Sigma has the Jacobian factor from coarea of f-composed-gamma. Proof sketch cites Federer 4.3.2. CHECK: 4.3.2 is about flat chains in Euclidean space. Does the Lorentzian setting require additional justification? Also verify the reverse Cauchy-Schwarz claim for transversality.

**Type:** claim

**Inference:** assumption

**Status:** pending

**Taint:** unresolved

