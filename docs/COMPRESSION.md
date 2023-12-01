# Compression

## Site

| Site       | Encoding |
| ---------- | -------- |
| UNKNOWN    | 000      |
| grenoble   | 001      |
| paris      | 010      |
| lille      | 011      |
| saclay     | 100      |
| strasbourg | 101      |

### Sensor read data

We first multiply data by 100 to remove fraction bits. This is done at the sensor node it self

- 33.2, 34.5, 32.2 ,33.0

- 332,  345,  322,  330
  
  - multiplied by 10

- 329, 3, 16, -7,1
  
  - choose base value as '329'
  
  - show the values as difference to base value
  
  - tolerance is -128 to +128

- So the value is 16 bit and difference will be 8 bit, 2's complement

- differences can be run length encoded


