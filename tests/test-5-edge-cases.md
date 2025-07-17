flowchart TD
  Phase1[Phase 1: Start]:::incomplete --> Phase2
  Phase2 --> Phase3[Phase 3: Middle]:::incomplete
  Phase3 --> Phase4
  Phase4 --> Phase5[Phase 5: End]:::complete

  %% Class Definitions
  classDef incomplete fill:#fefcbf,stroke:#b7791f,stroke-width:2px,color:#744210
  classDef inProgress fill:#bee3f8,stroke:#2b6cb0,stroke-width:2px,color:#2c5282
  classDef complete fill:#c6f6d5,stroke:#2f855a,stroke-width:2px,color:#22543d 