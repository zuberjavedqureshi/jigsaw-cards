# Open Questions

Questions that must be answered before the related work can be finalised. When resolved, record the answer, date and (if technical) the ADR.

| ID | Question | Blocks | Owner | Status |
| --- | --- | --- | --- | --- |
| Q-001 | Who is the primary target audience (age range, player profile)? Is the game directed at children? | Art direction, monetization, data collection, store compliance, MVP | Product | Open |
| Q-002 | World unlock rules: how many puzzles/collections per world, and what unlocks the next world? (Collection completion is proposed, PRD WP-03; the exact mechanism is open) | Progression, content plan | Product | Open |
| Q-003 | What are coins used for (hints, preview, unlocks, cosmetics)? | Economy, UI | Product | Open |
| Q-004 | Monetization model (premium, ads, IAP, none)? | Economy, Firebase need, compliance | Product | Open |
| Q-005 | MVP success KPIs and targets? | MVP definition | Product | Open |
| Q-006 | Mascot design, name and personality? | Visual identity, onboarding | Art / Product | Open |
| Q-007 | Card details: rarity tiers and their effect (rarity itself is confirmed); what is shown or awarded when a designated puzzle's card is already collected (it does not count as new progress, CC-06); card detail view? | Collection design, data model | Product | Open |
| Q-008 | Reference preview interaction (hold-to-peek, toggle, thumbnail)? Any limit on use? | Gameplay UI | Product / Design | Open |
| Q-009 | Rectangular partition generation (confirmed, PS-08): which algorithm; allowed piece sizes and piece-count range for 4×4; seeded/deterministic; runtime or build time; are authored layouts also supported? | Puzzle engine (TD-02) | Tech / Design | Open |
| Q-010 | Placement rule: strict (only correct position accepted) or free? Do correct pieces lock? What is the precise incorrect-drop behaviour? (Return to previous position is proposed, PRD GP-06) | Puzzle engine | Product / Tech | Open — working assumption: strict |
| Q-011 | Tray behaviour when pieces don't fit (scroll, page, scale)? | Layout, Flame | Design | Open |
| Q-012 | Background music in prototype/MVP? | Audio | Product | Open |
| Q-013 | Minimum Android version and target devices? | Performance validation | Tech | Open |
| Q-014 | Local persistence technology? | Save/restore (TD-01) | Tech | Open — Phase 1 |
| Q-015 | Rive fallback if validation fails? | Character reveal | Tech / Art | Open |
| Q-016 | Final license / publishing entity name for copyright notice? | LICENSE | Owner | Open |
| Q-017 | Card acquisition rules | Progression, rewards | Product | **Resolved 2026-11-23**: designated puzzles guarantee their card; non-designated award coins and progression rewards; collected cards are not new progress; prototype puzzle is designated (PRD CC-04 to CC-07). Designation counts per collection fall under Q-002 |
| Q-018 | Hybrid puzzle system meaning | Puzzle engine scope | Product | **Resolved 2026-11-23**: two separate styles (rectangular tile now, irregular jigsaw future), not necessarily combined in one puzzle; shared session, configuration, interaction contracts, progress/completion reporting and rewards; separate geometry and rendering (PRD PS-04 to PS-18) |
| Q-019 | Supply the approved PRD v1.0 text for sections marked [Source text needed]: USP statement, development phases and exit criteria, technical requirements and quality gates, persistence requirements | PRD completeness, roadmap | Owner | Open |
| Q-020 | What do "progression rewards" for non-designated puzzles consist of? | Rewards, progression, data model | Product | Open |
| Q-021 | Final world names (working names: Enchanted Forest, Ocean Kingdom, Fantasy Kingdom, Cosmic Adventures; PRD WP-02 proposed)? | Content, art, store listing | Product | Open |
