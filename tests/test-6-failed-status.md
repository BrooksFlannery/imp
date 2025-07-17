flowchart TD
  Phase1[Phase 1: Setup]:::complete --> Phase2[Phase 2: Build]:::failed
  Phase1 --> Phase3[Phase 3: Alternative]:::incomplete
  Phase2 --> Phase4[Phase 4: Deploy]:::incomplete
  Phase3 --> Phase4

  %% Class Definitions
  classDef incomplete fill:#fefcbf,stroke:#b7791f,stroke-width:2px,color:#744210
  classDef inProgress fill:#bee3f8,stroke:#2b6cb0,stroke-width:2px,color:#2c5282
  classDef complete fill:#c6f6d5,stroke:#2f855a,stroke-width:2px,color:#22543d
  classDef failed fill:#fed7d7,stroke:#c53030,stroke-width:2px,color:#742a2a 