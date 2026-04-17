# Database Migration Plan: MySQL to PostgreSQL

## Overview

This document outlines a structured plan for migrating our database from MySQL to PostgreSQL. The migration covers schema conversion, data migration, application layer updates, testing, and cutover strategy.

---

## 1. Goals and Motivation

- Leverage PostgreSQL's advanced features (JSONB, window functions, CTEs, full-text search)
- Improve standards compliance and long-term vendor support
- Gain access to better extension ecosystem (PostGIS, pg_trgm, etc.)
- Address known MySQL limitations in our current setup

---

## 2. Scope

- All production MySQL databases and schemas
- Application code that issues SQL queries or uses an ORM
- CI/CD pipelines and infrastructure configuration
- Backup and monitoring tooling

---

## 3. Pre-Migration Assessment

### 3.1 Inventory
- [ ] Document all MySQL databases, schemas, tables, views, stored procedures, triggers, and functions
- [ ] Identify all application services that connect to MySQL
- [ ] Record current database size, row counts, and growth rates
- [ ] Identify any MySQL-specific SQL syntax, functions, or data types in use

### 3.2 Compatibility Analysis
| MySQL Feature | PostgreSQL Equivalent | Notes |
|---|---|---|
| `AUTO_INCREMENT` | `SERIAL` / `GENERATED ALWAYS AS IDENTITY` | Update DDL |
| `TINYINT(1)` (boolean) | `BOOLEAN` | Requires type conversion |
| `DATETIME` | `TIMESTAMP` | Timezone handling differs |
| `ENUM` types | `ENUM` or `TEXT` + `CHECK` constraint | Evaluate case by case |
| `GROUP BY` (loose mode) | Strict standard | Queries may need rewriting |
| `LIMIT x, y` | `LIMIT y OFFSET x` | Update application queries |
| Backtick quoting | Double-quote quoting | Update DDL and raw SQL |
| `IFNULL()` | `COALESCE()` | Find and replace |
| `NOW()` | `NOW()` / `CURRENT_TIMESTAMP` | Compatible |
| Stored procedures | PL/pgSQL procedures | Manual rewrite required |
| Full-text search | `tsvector` / `tsquery` | Rewrite FTS queries |

### 3.3 Risk Assessment
- **High risk:** Stored procedures and triggers — require manual rewrite
- **Medium risk:** Implicit type coercions MySQL permits but PostgreSQL rejects
- **Low risk:** Standard CRUD queries with no MySQL-specific syntax

---

## 4. Environment Setup

- [ ] Provision PostgreSQL server (version 16+) matching or exceeding MySQL server specs
- [ ] Configure connection pooling (PgBouncer recommended)
- [ ] Set up SSL/TLS, authentication, and role-based access control
- [ ] Install required extensions (`uuid-ossp`, `pg_trgm`, `postgis` as needed)
- [ ] Configure WAL archiving and PITR backups
- [ ] Set up monitoring (pg_stat_statements, Prometheus + postgres_exporter)

---

## 5. Schema Migration

### 5.1 Tooling
Use **pgLoader** or **AWS Schema Conversion Tool (SCT)** for automated schema conversion, followed by manual review and correction.

### 5.2 Steps
1. Export MySQL schema DDL
2. Run automated conversion tool to produce PostgreSQL DDL
3. Manually review and fix:
   - Data type mappings
   - Index definitions (MySQL prefix indexes, FULLTEXT indexes)
   - Constraints and foreign keys
   - Stored procedures, functions, and triggers
4. Apply schema to PostgreSQL staging environment
5. Validate schema with application team

### 5.3 Naming Conventions
PostgreSQL lowercases unquoted identifiers and is case-sensitive with quoted ones. Audit all identifier names and update application queries accordingly.

---

## 6. Data Migration

### 6.1 Strategy: Full Dump + Incremental Sync

For minimal downtime, use a two-phase approach:

**Phase 1 — Bulk Load (offline or low-traffic window)**
1. Take a consistent MySQL snapshot (`mysqldump` or `mydumper`)
2. Transform and load data into PostgreSQL using `pgLoader` or a custom ETL script
3. Validate row counts and spot-check data integrity

**Phase 2 — Incremental Sync (until cutover)**
1. Enable MySQL binary log (binlog) replication if not already active
2. Use a CDC (Change Data Capture) tool such as **Debezium** to stream changes from MySQL binlog to PostgreSQL
3. Monitor replication lag; target < 1 second before cutover

### 6.2 Data Validation
- [ ] Compare row counts per table between MySQL and PostgreSQL
- [ ] Hash-check a sample of rows per table
- [ ] Validate foreign key integrity
- [ ] Verify no truncation of string or numeric fields

---

## 7. Application Layer Updates

### 7.1 ORM / Query Builder
- Update ORM configuration to point to PostgreSQL (connection strings, driver)
- Replace MySQL-specific dialect settings with PostgreSQL equivalents
- Run ORM schema sync in non-destructive mode and review generated DDL

### 7.2 Raw SQL Queries
- [ ] Search codebase for raw SQL strings and MySQL-specific syntax
- [ ] Replace `LIMIT offset, count` with `LIMIT count OFFSET offset`
- [ ] Replace backtick quoting with double-quote quoting or remove quoting where unnecessary
- [ ] Replace `IFNULL` with `COALESCE`, `YEAR()` / `MONTH()` with `EXTRACT()`
- [ ] Update `INSERT ... ON DUPLICATE KEY UPDATE` to `INSERT ... ON CONFLICT DO UPDATE`
- [ ] Update `LAST_INSERT_ID()` to `RETURNING id` or sequence functions

### 7.3 Connection Configuration
- Update all environment variables and secrets for PostgreSQL DSN format
- Update connection pool settings (max connections, timeouts)

---

## 8. Testing Plan

### 8.1 Unit Tests
- Run existing unit tests against PostgreSQL; fix any failures

### 8.2 Integration Tests
- [ ] Run full integration test suite against PostgreSQL staging database
- [ ] Test all CRUD operations
- [ ] Test transactions and rollback behavior
- [ ] Test edge cases: empty strings, NULLs, large text fields, binary data

### 8.3 Performance Testing
- [ ] Run query benchmarks on representative production queries
- [ ] Identify missing indexes and optimize query plans with `EXPLAIN ANALYZE`
- [ ] Load test with production-volume data (use production snapshot)

### 8.4 User Acceptance Testing
- [ ] Run QA suite in staging environment connected to PostgreSQL
- [ ] Involve key stakeholders in sign-off before cutover

---

## 9. Cutover Plan

### 9.1 Pre-Cutover Checklist
- [ ] All tests passing on PostgreSQL staging
- [ ] Replication lag < 1 second and stable for 24+ hours
- [ ] Runbook reviewed and rehearsed
- [ ] Rollback plan confirmed and tested
- [ ] Stakeholder sign-off obtained
- [ ] Maintenance window scheduled and communicated

### 9.2 Cutover Steps
1. Announce maintenance window; enable read-only mode or take application offline
2. Wait for CDC replication to reach zero lag
3. Stop CDC replication connector
4. Perform final validation (row counts, spot checks)
5. Update application configuration to point to PostgreSQL
6. Re-enable application; smoke test critical paths
7. Monitor error rates, query latency, and connection counts for 30 minutes
8. Declare cutover complete; notify stakeholders

### 9.3 Rollback Plan
If a critical issue is detected within the first 2 hours post-cutover:
1. Re-enable read-only mode on application
2. Switch application configuration back to MySQL
3. Re-enable MySQL as primary
4. Investigate and fix the issue before scheduling a new cutover window

---

## 10. Post-Migration Tasks

- [ ] Decommission MySQL server (after a 2-week hold period)
- [ ] Update all documentation, runbooks, and architecture diagrams
- [ ] Remove MySQL drivers and dependencies from application
- [ ] Configure PostgreSQL-native backup strategy (pg_dump, WAL-G, or pgBackRest)
- [ ] Set up PostgreSQL-specific monitoring dashboards and alerts
- [ ] Conduct a post-migration retrospective

---

## 11. Timeline

| Phase | Duration | Owner |
|---|---|---|
| Pre-migration assessment | 1 week | DBA + Lead Engineer |
| Environment setup | 3 days | Infrastructure team |
| Schema migration + review | 1 week | DBA + Backend team |
| Data migration (bulk load) | 2–3 days | DBA |
| Application layer updates | 2 weeks | Backend team |
| Testing (all phases) | 2 weeks | QA + Backend team |
| CDC sync + pre-cutover validation | Ongoing (parallel) | DBA |
| Cutover | 2–4 hour window | All teams |
| Post-migration cleanup | 2 weeks | DBA + Infrastructure |

**Total estimated duration: 6–8 weeks**

---

## 12. Responsible Parties

| Role | Responsibility |
|---|---|
| DBA | Schema conversion, data migration, replication, validation |
| Backend team | Application query updates, ORM changes, integration tests |
| Infrastructure | PostgreSQL provisioning, networking, backups, monitoring |
| QA | Test plan execution, UAT coordination |
| Project Lead | Timeline management, stakeholder communication, sign-offs |

---

## Appendix: Useful Tools

- **pgLoader** — automated MySQL to PostgreSQL migration (schema + data)
- **Debezium** — CDC / binlog streaming for real-time replication
- **pgBadger** — PostgreSQL log analyzer for query optimization
- **pgBouncer** — connection pooler for PostgreSQL
- **pg_activity** — real-time monitoring of PostgreSQL activity
- **WAL-G / pgBackRest** — PostgreSQL backup and PITR solutions
