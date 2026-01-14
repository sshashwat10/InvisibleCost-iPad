# Invisible Cost iPad App - V2 Experience Design

**For: Neeti**
**Date: January 2026**

---

## Overview

A data-driven, personalized cost calculator that shows executives their invisible costs with credible, sourced benchmarks.

---

## User Inputs

### Core Inputs (All Users)

| Input | Example |
|-------|---------|
| **Company Name** | Acme Corp |
| **Number of Employees** | 5,000 |
| **Number of Customers Served** | 500 |
| **Avg Size of Customer Orgs** | 1,000 employees |

### Departments

| Department | Key Process |
|------------|-------------|
| **P2P** | Procure-to-Pay / Invoice Processing |
| **O2C** | Order-to-Cash / Collections |
| **Customer Support** | Ticket Resolution |
| **ITSM** | IT Service Management |

### IT & Customer Support Formula

```
Invisible Cost = Customers Served × Avg Customer Org Size × Cost per Employee
```

**Example:** 500 customers × 1,000 employees × $22 = **$11,000,000**

---

## Screen Flow

### 1. Opening

```
+--------------------------------------------------+
|                                                  |
|                                                  |
|        "Every organization...                    |
|         carries a hidden cost."                  |
|                                                  |
|        "Most leaders... never see it."          |
|                                                  |
|                                                  |
+--------------------------------------------------+
```

---

### 2. Department Selection

```
+--------------------------------------------------+
|                                                  |
|     "Four processes. Four invisible costs."      |
|                                                  |
|   +----------+  +----------+  +----------+       |
|   |   P2P    |  |   O2C    |  | CUSTOMER |       |
|   | Procure  |  | Order    |  | SUPPORT  |       |
|   | to Pay   |  | to Cash  |  |          |       |
|   +----------+  +----------+  +----------+       |
|                                                  |
|                 +----------+                     |
|                 |   ITSM   |                     |
|                 | IT Service|                    |
|                 |   Mgmt   |                     |
|                 +----------+                     |
|                                                  |
+--------------------------------------------------+
```

---

### 3. Personal Input - Core

```
+--------------------------------------------------+
|                                                  |
|           "Let's get specific."                  |
|                                                  |
|  +--------------------------------------------+  |
|  | ABOUT YOUR ORGANIZATION                    |  |
|  |                                            |  |
|  | Company Name (optional):                   |  |
|  | [_______________]                          |  |
|  |                                            |  |
|  | Number of Employees:                       |  |
|  | [100] [500] [1K] [5K] [10K+]              |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|  +--------------------------------------------+  |
|  | CUSTOMERS YOU SERVE                        |  |
|  |                                            |  |
|  | Number of Customers:                       |  |
|  | [10] [50] [100] [500] [1K+]               |  |
|  |                                            |  |
|  | Avg Size of Customer Orgs (employees):     |  |
|  | [100] [500] [1K] [5K] [10K+]              |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|              [ Calculate My Cost ]               |
|                                                  |
+--------------------------------------------------+
```

---

### 4. Personal Input - P2P Additional

```
+--------------------------------------------------+
|  +--------------------------------------------+  |
|  | P2P DETAILS                                |  |
|  |                                            |  |
|  | Invoices per Month:                        |  |
|  | [1K] [5K] [10K] [25K] [50K+]               |  |
|  |                                            |  |
|  | AP Team Size: [___] FTEs                   |  |
|  |                                            |  |
|  | Current Automation Level:                  |  |
|  | [Manual] [Partial] [Automated]             |  |
|  |                                            |  |
|  +--------------------------------------------+  |
+--------------------------------------------------+
```

---

### 5. Building Tension

```
+--------------------------------------------------+
|                                                  |
|     "Let's take one process... reconciliation."  |
|                                                  |
|     "Based on your input..."                     |
|                                                  |
|     +--------------------------------------+     |
|     |                                      |     |
|     |   5,000 invoices/month               |     |
|     |   × 12 months                        |     |
|     |   = 60,000 invoices/year             |     |
|     |                                      |     |
|     |   @ $7.75 per invoice (median)       |     |
|     |   Source: APQC                       |     |
|     |                                      |     |
|     +--------------------------------------+     |
|                                                  |
+--------------------------------------------------+
```

---

### 6. Sucker Punch Reveal

```
+--------------------------------------------------+
|                                                  |
|                                                  |
|                                                  |
|                  $2,400,000                      |
|                                                  |
|              YOUR INVISIBLE COST                 |
|                   per year                       |
|                                                  |
|                                                  |
|  +--------------------------------------------+  |
|  |                                            |  |
|  |   40,000 hours    →   $480,000 direct     |  |
|  |                   →   $720,000 indirect    |  |
|  |                   →   $1,200,000 invisible |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|     Source: APQC, Ardent Partners 2024           |
|                                                  |
+--------------------------------------------------+
```

---

### 7. IT/Support Calculation Display

```
+--------------------------------------------------+
|                                                  |
|           YOUR INVISIBLE COST                    |
|                                                  |
|              $11,000,000                         |
|                 per year                         |
|                                                  |
|  +--------------------------------------------+  |
|  | CALCULATION                                |  |
|  |                                            |  |
|  | Customers Served:        500               |  |
|  | × Avg Org Size:          1,000 employees   |  |
|  | = Total Supported:       500,000           |  |
|  |                                            |  |
|  | × Cost per Employee:     $22               |  |
|  | = Base Cost:             $11,000,000       |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|     Source: HDI, MetricNet                       |
|                                                  |
+--------------------------------------------------+
```

---

### 8. Comparison Carousel

```
+--------------------------------------------------+
|                                                  |
|        "Let's put that in perspective..."        |
|                                                  |
|  +--------------------------------------------+  |
|  |                                            |  |
|  |              12 FTEs                       |  |
|  |                                            |  |
|  |   full-time employees doing nothing        |  |
|  |   but processing invoices all year         |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|              ● ○ ○                               |
|                                                  |
+--------------------------------------------------+
```

---

### 9. Automation Anywhere Value

```
+--------------------------------------------------+
|                                                  |
|           AUTOMATION ANYWHERE                    |
|                                                  |
|  +--------------------------------------------+  |
|  |                                            |  |
|  |   BEFORE          →         AFTER          |  |
|  |                                            |  |
|  |   $12/invoice              $2/invoice      |  |
|  |   17.4 days                3.1 days        |  |
|  |                                            |  |
|  |         78% COST REDUCTION                 |  |
|  |         82% FASTER PROCESSING              |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|     Source: Ardent Partners 2024 ePayables       |
|                                                  |
|  +--------------------------------------------+  |
|  |                                            |  |
|  |   262% ROI over 3 years                    |  |
|  |   Payback in under 12 months               |  |
|  |                                            |  |
|  |   Source: Forrester TEI Study              |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
+--------------------------------------------------+
```

---

### 10. Human Return

```
+--------------------------------------------------+
|                                                  |
|                                                  |
|        "Strategy... not spreadsheets."           |
|                                                  |
|        "Innovation... not administration."       |
|                                                  |
|        "Leading... not chasing."                 |
|                                                  |
|                                                  |
+--------------------------------------------------+
```

---

### 11. Call to Action

```
+--------------------------------------------------+
|                                                  |
|                                                  |
|        "The invisible cost ends now."            |
|                                                  |
|        "The choice is yours."                    |
|                                                  |
|                                                  |
|     +----------------+  +----------------+       |
|     |    RESTART     |  |  REQUEST DEMO  |       |
|     +----------------+  +----------------+       |
|                                                  |
|                                                  |
+--------------------------------------------------+
```

---

## Narration Scripts

### Opening
```
"Every organization... carries a hidden cost."

"Most leaders... never see it."
```

### Department Selection
```
"Four processes. Four invisible costs.
Choose the one that matters most."
```

### Personal Input
```
"Now... let's get specific.
Your numbers. Your reality."
```

### Building Tension - P2P
```
"Let's take one process... invoice reconciliation.

Based on your input... industry data reveals
the hidden hours.

Hours that could be building your future."
```

### Building Tension - O2C
```
"Consider your order-to-cash cycle.

Days of revenue... sitting idle.
Working capital... tied up in waiting.

Every day matters."
```

### Building Tension - Customer Support
```
"Look at your support operation.

Agents handling routine inquiries...
when they could be building loyalty.

The gap is measurable."
```

### Building Tension - ITSM
```
"Your IT service desk.

Password resets. Basic tickets.
Engineers reduced to firefighters...
when they should be architects."
```

### Vignettes (Quick Punches)
```
P2P:     "Hours... lost... to matching invoices
          machines were built to handle."

O2C:     "Cash flow... delayed...
          by processes that should be instant."

Support: "Agents... drowning...
          in tickets AI could resolve in seconds."

ITSM:    "Engineers... reduced...
          to password reset specialists."
```

### Pattern Break
```
"But what if... you could see the real number?"
```

### Sucker Punch Reveal
```
"Direct costs. Indirect costs.
And the invisible cost you never see on a spreadsheet.

This is real money. Your money. Every single year."
```

### Automation Anywhere Value - P2P
```
"From twelve dollars an invoice... to two.

From seventeen days... to three.

Seventy-eight percent lower costs.
Eighty-two percent faster."
```

### Automation Anywhere Value - O2C
```
"Collections accelerated by over a week.

Up to seven million dollars in benefits
for mid-size firms."
```

### Automation Anywhere Value - Support
```
"Eighty billion dollars in service costs...
reduced by twenty twenty-six.

AI is changing everything."
```

### Automation Anywhere Value - ITSM
```
"Ticket volume reduced by sixty percent.

Resolution fifty-two percent faster."
```

### Automation Anywhere ROI
```
"Two hundred sixty-two percent ROI...
over three years.

Payback in under twelve months."
```

### Human Return
```
"The chains dissolve... one by one."

"Breathe... this is what's possible."

"Strategy... not spreadsheets.
Innovation... not administration.
Leading... not chasing."
```

### Final CTA
```
"The invisible cost... ends now.

The choice is yours."
```

---

## Sourced Benchmark Data

### P2P (Procure-to-Pay)

| Metric | Value | Source |
|--------|-------|--------|
| Cost per invoice (top performers) | $4.98 | APQC |
| Cost per invoice (median) | $7.75 | APQC |
| Cost per invoice (bottom) | $12.44 | APQC |
| Cost per invoice (best-in-class) | $2.78 | Ardent Partners 2024 |
| Cost per invoice (automated) | $2.02 | Stampli |
| Invoices/FTE/year (manual) | 6,082 | Stampli |
| Invoices/FTE/year (automated) | 23,333 | Stampli |
| Cycle time (top performers) | 3.1 days | Ardent Partners 2024 |
| Cycle time (average) | 17.4 days | Ardent Partners 2024 |
| Exception rate (best-in-class) | 9% | Forrester/Basware |
| Exception rate (average) | 22% | Forrester/Basware |
| **Cost reduction with automation** | **78-81%** | **Ardent Partners 2024** |
| **Processing speed improvement** | **82% faster** | **Ardent Partners 2024** |

### O2C (Order-to-Cash)

| Metric | Value | Source |
|--------|-------|--------|
| DSO (median) | 38 days | APQC |
| DSO (top performers) | <30 days | APQC |
| AI-driven DSO reduction | 8.4 days | Hackett Group |
| AI benefits (mid-size firms) | Up to $7M | Hackett Group |
| Cost reduction (automated vs manual) | 3× lower | APQC |
| Electronic invoicing (top performers) | 80% | APQC |
| Auto-applied payments (top performers) | 94% | APQC |
| **Cycle time improvement** | **30-50% faster** | **APQC, Hackett** |
| **Invoice cost reduction** | **79%** | **Auxis** |

### Customer Support

| Metric | Value | Source |
|--------|-------|--------|
| Cost per ticket (NA average) | $22 | HDI/ServiceNow |
| Cost per ticket (range) | $6 - $40 | HDI |
| Average handle time | 7-10 min | Plivo |
| First Contact Resolution (average) | 70-79% | Plivo |
| FCR (world-class) | ≥80% | Plivo |
| **Gartner AI cost savings by 2026** | **$80B** | **Gartner** |
| **Chatbot cost savings** | **30-50%** | **Industry** |
| **Response speed improvement** | **50-60% faster** | **Pylon** |

### ITSM

| Metric | Value | Source |
|--------|-------|--------|
| Cost per Tier-1 ticket | $22 | MetricNet |
| Cost per Tier-3 ticket | $104 | MetricNet |
| General range | $15-40 | Gartner |
| IT leaders increasing automation spend | 64% | Netfor |
| **AI ticket volume reduction** | **Up to 60%** | **ServiceNow** |
| **Ticket handling speed (automated)** | **37-52% faster** | **ServiceNow** |

### Automation Anywhere (Forrester TEI Study)

| Metric | Value |
|--------|-------|
| **ROI (3-year)** | **262%** |
| **Payback period** | **<12 months** |
| **Total benefits (3-year)** | **$13.2 million** |
| Staff redeployment savings | $8.3 million |
| Compliance/audit savings | $2.7 million |
| Error reduction savings | $1.1 million |

---

## Full Source Citations

| # | Publisher | Article/Study | URL |
|---|-----------|---------------|-----|
| 1 | APQC | 5 Steps to Lowering AP Processing Cost | https://transformious.com/accounts-payable/5-steps-to-lowering-the-cost-of-ap-processing-and-reducing-transaction-processing-time/ |
| 2 | Ardent Partners | 2024 ePayables Study | https://www.bottomline.com/resources/blog/ardent-2024-epayables-study-automation-ai-earning-ap-a-seat-at-the-strategy-table |
| 3 | Stampli | P2P KPIs Guide | https://www.stampli.com/blog/accounts-payable/procure-to-pay-kpis/ |
| 4 | Forrester/Basware | TEI of AP Automation | https://tei.forrester.com/go/basware/apautomation/ |
| 5 | Ardent Partners | AP Metrics That Matter 2024 | https://www.basware.com/en/resources/ardent-partners-accounts-payable-metrics-that-matter-in-2024 |
| 6 | Auxis | AR Automation Benefits | https://www.auxis.com/accounts-receivable-automation-benefits-and-best-practices/ |
| 7 | MetricNet | IT Service Desk Cost | https://www.ghdsi.com/blog/evaluate-reduce-it-service-desk-cost-per-ticket/ |
| 8 | ServiceNow | Help Desk Statistics 2024 | https://www.servicenow.com/products/itsm/help-desk-statistics.html |
| 9 | Plivo | Contact Center Benchmarks 2025 | https://www.plivo.com/blog/contact-center-statistics-benchmarks-2025/ |
| 10 | HDI | State of Tech Support 2025 | https://www.thinkhdi.com/library/supportworld/2025/5-insights-hdi-state-of-tech-support-2025 |
| 11 | Pylon | AI Customer Support Guide | https://www.usepylon.com/blog/ai-powered-customer-support-guide |
| 12 | Netfor | IT Help Desk Value | https://www.netfor.com/2025/04/02/it-help-desk-support-2/ |
| 13 | Forrester | Automation Anywhere TEI | https://www.automationanywhere.com/company/blog/company-news/forrester-study-huge-rpa-return-in-short-time-frame |

---

## Audio Files Needed

| File | Script | Duration |
|------|--------|----------|
| opening_1 | "Every organization... carries a hidden cost." | ~3s |
| opening_2 | "Most leaders... never see it." | ~2s |
| choose_department | "Four processes. Four invisible costs..." | ~4s |
| personal_input | "Now... let's get specific..." | ~4s |
| building_p2p | "Let's take one process... reconciliation..." | ~8s |
| building_o2c | "Consider your order-to-cash cycle..." | ~8s |
| building_cs | "Look at your support operation..." | ~8s |
| building_itsm | "Your IT service desk..." | ~8s |
| vignette_p2p | "Hours... lost... to matching invoices..." | ~3s |
| vignette_o2c | "Cash flow... delayed..." | ~3s |
| vignette_cs | "Agents... drowning..." | ~3s |
| vignette_itsm | "Engineers... reduced..." | ~3s |
| pattern_break | "But what if... you could see the real number?" | ~3s |
| sucker_punch | "Direct costs. Indirect costs..." | ~6s |
| aa_value_p2p | "From twelve dollars an invoice... to two..." | ~6s |
| aa_value_o2c | "Collections accelerated by over a week..." | ~5s |
| aa_value_cs | "Eighty billion dollars in service costs..." | ~4s |
| aa_value_itsm | "Ticket volume reduced by sixty percent..." | ~4s |
| aa_roi | "Two hundred sixty-two percent ROI..." | ~5s |
| restoration | "The chains dissolve... one by one." | ~3s |
| breathe | "Breathe... this is what's possible." | ~3s |
| purpose | "Strategy... not spreadsheets..." | ~6s |
| final_cta | "The invisible cost... ends now..." | ~4s |

---

**End of Document**
