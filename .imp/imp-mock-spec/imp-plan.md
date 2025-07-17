```mermaid
flowchart TD
  Phase1[Phase 1: Project Setup and Infrastructure]:::inProgress --> Phase2[Phase 2: Backend API Foundation]:::incomplete
  Phase1 --> Phase6[Phase 6: Frontend Foundation]:::incomplete
  Phase2 --> Phase3[Phase 3: Authentication System]:::incomplete
  Phase3 --> Phase4[Phase 4: Task Management API]:::incomplete
  Phase4 --> Phase5[Phase 5: WebSocket Real-time System]:::incomplete
  Phase3 --> Phase7[Phase 7: Authentication UI]:::incomplete
  Phase6 --> Phase7
  Phase4 --> Phase8[Phase 8: Task Management UI]:::incomplete
  Phase7 --> Phase8
  Phase5 --> Phase9[Phase 9: Real-time UI Integration]:::incomplete
  Phase8 --> Phase9
  Phase9 --> Phase10[Phase 10: Testing and Quality Assurance]:::incomplete
  Phase10 --> Phase11[Phase 11: Deployment and CI/CD]:::incomplete
  Phase11 --> Phase12[Phase 12: Documentation and Finalization]:::incomplete

  %% Class Definitions
  classDef incomplete fill:#fefcbf,stroke:#b7791f,stroke-width:2px,color:#744210
  classDef inProgress fill:#bee3f8,stroke:#2b6cb0,stroke-width:2px,color:#2c5282
  classDef complete fill:#c6f6d5,stroke:#2f855a,stroke-width:2px,color:#22543d
``` 