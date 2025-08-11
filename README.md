# Google Consent Parser

A Google Tag Manager Server-side variable template that decodes Google Consent Mode v2 strings from the `gcd` parameter into a readable format.

## Overview

This template automatically parses Google's encoded consent strings and returns the consent states for various categories (ad_storage, analytics_storage, ad_user_data, ad_personalization) in either object or string format.

## Features

- ✅ Parses Google Consent Mode v2 `gcd` parameter
- ✅ Supports all 4 consent categories
- ✅ Returns data in object or string format
- ✅ Works with server-side Google Tag Manager
- ✅ Handles missing consent parameters gracefully

## Installation

1. Download the template file
2. In your GTM Server container, go to **Templates**
3. Click **New** > **Variable Template**
4. Import the template file
5. Save and publish

## Usage

### Create a Variable

1. Go to **Variables** in your GTM Server container
2. Click **New** > **User-Defined Variables**
3. Select **Google Consent Parser**
4. Configure the template parameters

### Template Parameters

| Parameter | Description | Options |
|-----------|-------------|---------|
| **Consent Category** | Which consent category to return | `ad_storage`, `analytics_storage`, `ad_user_data`, `ad_personalization`, `all` |
| **Output Format** | How to format the response | `object`, `string` |

### Example Configurations

#### Get All Consent States (Object Format)
```
Consent Category: All
Output Format: Object
```

**Returns:**
```javascript
{
  ad_storage: { default: "denied", update: "granted" },
  analytics_storage: { default: "denied", update: "granted" },
  ad_user_data: { default: "denied", update: "granted" },
  ad_personalization: { default: "denied", update: "granted" }
}
```

#### Get Single Category (String Format)
```
Consent Category: ad_storage
Output Format: String
```

**Returns:**
```
"default:denied|update:granted"
```

## How It Works

The template:

1. **Reads** the `gcd` parameter from incoming requests
2. **Parses** the base64url-encoded consent string
3. **Extracts** consent states using bitwise operations
4. **Returns** formatted consent information

# Google Consent String Structure - Corrected

## Actual Format Pattern

Based on your example: `13r3r3r3r5l1`

```
┌───┬─────────┬─────────┬─────────┬─────────┬─────────────┬─────────────────────┐
│ 1 │( 3 | r )│( 3 | r )│( 3 | r )│( 3 | r )│     (5)     │       ( 1 | l )     │
└───┴─────────┴─────────┴─────────┴─────────┴─────────────┴─────────────────────┘
 Ver  ad_storage analytics ad_user_data ad_personal Global Privacy Container Scoped
      ↑       ↑   ↑       ↑   ↑        ↑   ↑        ↑    Controls      Defaults
   impl   expl impl   expl impl    expl impl    expl
```

## Position Breakdown

```
Position:  1   2  3   4  5   6  7   8  9  10       11 12
String:    1   3  r   3  r   3  r   3  r   5        1  l
          ┌─┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌─────┐ ┌───────┐
          │V│ │I│E│ │I│E│ │I│E│ │I│E│ │ GPC │ │ CSD │
          └─┘ └───┘ └───┘ └───┘ └───┘ └─────┘ └───────┘
           │   │ │   │ │   │ │   │ │      │       │ │
        Version│ │   │ │   │ │   │ │   Global   │ │
               │ └─→ │ └─→ │ └─→ │ └─→ Privacy  │ │
               │  r  │  r  │  r  │  r  Controls │ l
               │     │     │     │              │
            ad_storage  analytics  ad_user   Container
                                  ad_personal Scoped
                                              Defaults
```

## Parsing Logic for Your Template

```javascript

consentString.substring(1, 3) → "3r" → pair[1] = 'r'  // ad_storage
consentString.substring(3, 5) → "3r" → pair[1] = 'r'  // analytics_storage  
consentString.substring(5, 7) → "3r" → pair[1] = 'r'  // ad_user_data
consentString.substring(7, 9) → "3r" → pair[1] = 'r'  // ad_personalization
```

## String Components Legend

```
┌─────────────────┬─────────────────────────────────────────────┐
│ Component       │ Description                                 │
├─────────────────┼─────────────────────────────────────────────┤
│ 1               │ Version marker                              │
│ (3│r)           │ Consent pair: Implicit│Explicit             │
│ 5               │ Global Privacy Controls marker              │
│ (1│l)           │ Container Scoped Defaults (optional)        │
└─────────────────┴─────────────────────────────────────────────┘
```

### Consent Values

| Value | Meaning |
|-------|---------|
| `granted` | User has granted consent |
| `denied` | User has denied consent |
| `-` | Consent state not defined |

## Use Cases

### Tag Firing Logic
```javascript
// Fire tag only if analytics consent granted
if ({{Consent Parser}}.analytics_storage.update === "granted") {
  // Fire analytics tag
}
```

### Server-Side Processing
```javascript
// Process data based on consent
const consent = {{Consent Parser}};
if (consent.ad_personalization.update === "granted") {
  // Enable personalized features
}
```

### Debugging & Monitoring
```javascript
// Log consent states for debugging
console.log("Current consent:", {{Consent Parser}});
```

## API Reference

### Return Values

#### When `consentCategory: "all"`
Returns object with all consent categories:
```javascript
{
  ad_storage: { default: string, update: string },
  analytics_storage: { default: string, update: string },
  ad_user_data: { default: string, update: string },
  ad_personalization: { default: string, update: string }
}
```

#### When specific category selected
Returns single category data in chosen format:

**Object format:**
```javascript
{ default: string, update: string }
```

**String format:**
```
"default:value|update:value"
```

#### Error Cases
- Returns `false` when no `gcd` parameter exists
- Returns `null` for invalid output format

## Testing

The template includes comprehensive tests covering:
- ✅ Valid consent strings with all categories
- ✅ Single category extraction
- ✅ Missing parameter handling
- ✅ Object vs string format consistency

Run tests in GTM's template editor before deploying.

## Troubleshooting

### Common Issues

**Returns `false`**
- Check that `gcd` parameter exists in request
- Verify Consent Mode v2 is properly implemented

**Returns `null` values**
- Check `outputFormat` parameter is valid (`object` or `string`)
- Verify template configuration

**Unexpected consent values**
- Ensure Consent Mode v2 is correctly configured on client-side
- Check consent string format in browser network tab

### Debugging

1. Check browser network requests for `gcd` parameter
2. Use GTM Preview mode to inspect variable values
3. Enable debug logging in server container

## Technical Details

### Base64url Decoding

The template uses a custom base64url (Safe) alphabet for decoding:
```
0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_
```

### Bitwise Operations

For each consent category, the template:
1. Extracts the second character from each 2-character pair
2. Gets the base64url index value
3. Uses bitwise operations to extract default and update values:
   - `defaultVal = (value >> 2) & 3` (bits 2-3)
   - `updateVal = value & 3` (bits 0-1)

## License

MIT License

Copyright (c) 2025 Analytics Debugger S.L.U.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests for new features
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Support

For issues and questions:
- Open an issue on GitHub
- Contact Analytics Debugger S.L.U.

## Credits

Created by **Analytics Debugger S.L.U.** - David Vallejo, 2025