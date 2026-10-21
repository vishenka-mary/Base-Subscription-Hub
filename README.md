# Zenith Subscription Hub

A decentralized SaaS and content subscription protocol deployed on the Base L2 network. This hub allows verified creators to offer time-locked access tiers, enabling users to purchase block-timestamped subscriptions with native asset routing.

## Core Mechanics
* **Time-Stacking Logic:** If a user renews an active subscription, the protocol calculates the remaining `block.timestamp` differential and stacks the new duration seamlessly on top of the existing expiry.
* **Automated Revenue Splits:** Subscription payments are trustlessly divided, routing the creator's share directly to their wallet while retaining a micro-fee for the protocol treasury.
* **Tier Management:** Creators retain sovereign control over their active tiers, allowing them to instantly deprecate legacy pricing models without affecting users' currently active durations.

## Architecture
Built with Solidity `0.8.37`. The protocol optimizes mapping reads to ensure gas-efficient expiry validation for external dApp gating mechanisms.
