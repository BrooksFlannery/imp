# Complex File Structure and Analysis System

## Overview

Create a comprehensive file organization system that processes multiple data sources, organizes them into structured directories, and generates summary reports. The system should handle concurrent processing of different data types while maintaining proper dependency management for cross-referenced analysis. This is really all mock data for our imp system to chew through so feel free to hallucinate text in the files and try to keep them short(100 words or less per file)

## File Structure

```
project/
├── data/
│   ├── financial/
│   │   ├── raw/
│   │   ├── processed/
│   │   └── validated/
│   ├── activity/
│   │   ├── raw/
│   │   ├── processed/
│   │   └── validated/
│   └── logs/
│       ├── raw/
│       ├── processed/
│       └── validated/
├── output/
│   ├── reports/
│   ├── summaries/
│   └── cross-references/
└── config/
    ├── processing/
    └── validation/
```

## Requirements

### Directory Structure Creation
- Create base project directory structure with data, output, and config folders
- Set up data ingestion directories for financial, activity, and log data
- Create processing pipeline directories with raw, processed, and validated subdirectories
- Establish output directories for reports, summaries, and cross-references
- Configure validation and error handling directories
- Set up configuration management structure
- Create temporary and cache directories
- Establish backup and archive directories

### Financial Data Infrastructure
- Create financial data raw directory with sample CSV files (transactions.csv, accounts.csv)
- Set up financial data processing subdirectories (raw, processed, validated)
- Create financial data validation structure with metadata files
- Populate with sample financial data files
- Create financial metadata files (schema.txt, validation_rules.txt)
- Set up financial data backup structure
- Create financial processing logs directory
- Establish financial data export directories

### Activity Data Infrastructure
- Create activity data raw directory with sample JSON files (user_sessions.json, page_views.json)
- Set up activity data processing subdirectories (raw, processed, validated)
- Create activity data validation structure with metadata files
- Populate with sample activity data files
- Create activity metadata files (schema.txt, validation_rules.txt)
- Set up activity data backup structure
- Create activity processing logs directory
- Establish activity data export directories

### Log Data Infrastructure
- Create log data raw directory with sample TXT files (system.log, error.log, access.log)
- Set up log data processing subdirectories (raw, processed, validated)
- Create log data validation structure with metadata files
- Populate with sample log data files
- Create log metadata files (schema.txt, validation_rules.txt)
- Set up log data backup structure
- Create log processing logs directory
- Establish log data export directories

### Data Processing Workflows
- Process transaction data files and validate account information
- Generate financial summaries and create data quality reports
- Process historical financial data and generate trend analysis
- Process user session data and analyze page view patterns
- Generate user behavior summaries and create activity data quality reports
- Process historical activity data and generate activity trend analysis
- Process system log files and analyze error patterns
- Generate log summaries and create log data quality reports
- Process historical log data and generate log trend analysis

### Cross-Reference Analysis
- Correlate financial and activity data from processed sources
- Analyze system logs with user activity patterns
- Generate cross-reference reports and data correlation summaries
- Identify data inconsistencies and generate data quality metrics
- Create cross-reference export files and update analysis status

### Report Generation
- Generate comprehensive summary reports from cross-reference analysis
- Create executive dashboard files and detailed analysis reports
- Create data quality assessment reports and trend analysis reports
- Generate recommendation documents and package all reports for distribution
- Update reporting status and finalize documentation
