flowchart TD
  Phase1[Phase 1: Foundation]:::incomplete --> Phase2[Phase 2: Core]:::incomplete
  Phase1 --> Phase3[Phase 3: UI]:::incomplete
  Phase2 --> Phase4[Phase 4: API]:::incomplete
  Phase3 --> Phase5[Phase 5: Components]:::incomplete
  Phase4 --> Phase6[Phase 6: Integration]:::incomplete
  Phase5 --> Phase6
  Phase6 --> Phase7[Phase 7: Testing]:::incomplete
  Phase7 --> Phase8[Phase 8: Deploy]:::incomplete

  %% Class Definitions
  classDef incomplete fill:#fefcbf,stroke:#b7791f,stroke-width:2px,color:#744210
  classDef inProgress fill:#bee3f8,stroke:#2b6cb0,stroke-width:2px,color:#2c5282
  classDef complete fill:#c6f6d5,stroke:#2f855a,stroke-width:2px,color:#22543d 