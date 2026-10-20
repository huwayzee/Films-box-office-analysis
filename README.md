# Films Box Office Analysis

**Question:** What makes a film earn back its budget, and where should a studio put its money?

Analysis of 4,846 films (1916–2016), focused on 3,087 US releases from 1980 onward with reliable box office figures. Built in Excel (formula-driven dashboard) and reproduced in SQL.

**Interactive dashboard:** [Films Box Office Dashboard](https://claude.ai/artifact/Mw26UubSorZ8cjo72u25r3)

## Files

| File | What it is |
|---|---|
| `Films_Box_Office_Analysis.xlsx` | Dashboard, insights, segment analysis, data quality log and cleaned data |
| `films_clean.csv` | Cleaned dataset used by the SQL script |
| `films_analysis.sql` | The same analysis in SQL (SQLite) |

Run the SQL:

```bash
sqlite3 films.db < films_analysis.sql
```

## Key findings

1. **Only about half of films earn back their budget.** 55% of films grossed at least their production budget, and the median film returned $1.14 per $1 spent before marketing costs.
2. **Returns depend on a few big hits.** The top 10% of films took 41% of all box office gross.
3. **Smaller budgets give better returns.** Films under $5M had a median return of 1.71x and a 59% hit rate. Films over $50M returned about 1.0x, and the biggest losses (John Carter: –$191M) all come from this group.
4. **Family ratings are the most reliable.** G and PG films earned back their budget 63–66% of the time, compared with 53–54% for PG-13 and R.
5. **Low-budget horror is the standout.** Paranormal Activity ($15K budget → $108M gross) and The Blair Witch Project ($60K → $141M) are the biggest return outliers.

## Recommendations

- Treat releases as a portfolio: fund several low-budget films (under $5M) for each tentpole.
- Set a higher approval bar for $100M+ projects, requiring proven IP and international pre-sales.
- Target PG/PG-13 where the story allows. Use R mainly for low-budget genres such as horror.
- Spend on event-style marketing that builds word of mouth, rather than on production scale.

## Data cleaning

| Issue found | Action |
|---|---|
| Header row overwritten by a garbled record | Restored headers and the record |
| 122 duplicate title + year rows (dashboard showed "0 removed") | Removed, keeping the first occurrence |
| 790 gross values filled with the median (25,529,689.5) | Flagged and excluded from revenue analysis |
| Missing values stored as the text `"nan"` | Converted to real blanks |
| Non-US budgets in local currency (e.g. The Host: 12.2B KRW) | Analysis limited to US films |

## Limitations

- Gross is box office only. Marketing, streaming and home video revenue are not included, so "hit" is a generous definition.
- Some source values are wrong. For example, The Polar Express shows $0.67M gross, while the actual US gross was over $180M.
- The findings show correlation, not causation. Longer films do better partly because prestige and franchise projects tend to run long.
- The 1980s look unusually strong partly because of survivorship: mostly well-known films from that decade are in the dataset.

## Tools

Excel (COUNTIFS, AVERAGEIFS, SUMIFS, array MEDIAN, charts), SQL (CTEs, views, CASE, window functions with NTILE), Python/pandas for cleaning.
