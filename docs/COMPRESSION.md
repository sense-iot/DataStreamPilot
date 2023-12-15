# Sensor Data Compression and Encoding

## Overview

This document details the compression and encoding methodology employed for transmitting sensor data within a data transmission system. The primary objectives are to efficiently represent sensor readings and incorporate error-checking mechanisms.

## Site Encoding

Sensor nodes are associated with specific sites, and a 3-bit encoding scheme is utilized:

| Site       | Encoding |
| ---------- | -------- |
| UNKNOWN    | 000      |
| grenoble   | 001      |
| paris      | 010      |
| lille      | 011      |
| saclay     | 100      |
| strasbourg | 101      |

## Sensor Reading Representation

### Base Value Selection

- Choose a base value as a reference for encoding subsequent readings.
- Example: For readings 

```
3321, 3455, 3224, 3306
```

- set the base value to `3321`.

### Encoding Differences

- Represent readings as differences from the base value.
- Example: For base value `3321` and readings `3455, 3224, 3306`, encode differences as 

```bash
3321, 134, -97, -15
```

### 8-bit Two's Complement Representation

- Constrain differences to an 8-bit range using two's complement representation.
- Tolerance: -128 to +128.

### Run-Length Encoding

- Further compress encoded differences using run-length encoding.
- Replace consecutive occurrences of the same difference value with a count and the difference value.
- Example: `[-97, -97, -97]` becomes `[(3, -97)]`.

## Error-Checking and Parity Bit

- Add an odd parity bit to all payload values, including site encoding and encoded differences.
- Parity bit aids in error-checking during transmission.
- The server checks parity bits; if they don't match the expected odd parity, it interpolates values using the previous and next readings.
