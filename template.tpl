___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_MKBWT",
  "version": 1,
  "displayName": "Google Consent Parser",
  "categories": [
    "AFFILIATE_MARKETING",
    "ADVERTISING",
    "ATTRIBUTION",
    "ANALYTICS",
    "UTILITY"
  ],
  "description": "Variable template to parse Google\u0027s Consent String into a readable format.",
  "containerContexts": [
    "SERVER"
  ],
  "securityGroups": []
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "SELECT",
    "name": "gcdSource",
    "displayName": "Source",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "request",
        "displayValue": "GCD Parameter"
      },
      {
        "value": "custom",
        "displayValue": "Custom Value or Variable"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "request",
    "help": "Where to read the Google consent string from. Use \u003cb\u003eCustom Value or Variable\u003c/b\u003e to pass a gcd string from another variable (e.g. event data)."
  },
  {
    "type": "TEXT",
    "name": "gcdValue",
    "displayName": "Consent String (gcd)",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "gcdSource",
        "paramValue": "custom",
        "type": "EQUALS"
      }
    ],
    "help": "A gcd string such as 13r3r3r3r5l1, or a variable that returns one."
  },
  {
    "type": "SELECT",
    "name": "dataType",
    "displayName": "Data Type",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "consent",
        "displayValue": "Consent State"
      },
      {
        "value": "isConsentModeActive",
        "displayValue": "Is Consent Mode Active"
      },
      {
        "value": "isGlobalPrivacyControlEnabled",
        "displayValue": "Is Global Privacy Control Enabled"
      },
      {
        "value": "adsSignals",
        "displayValue": "Ads Signals"
      },
      {
        "value": "raw",
        "displayValue": "Raw Details"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "consent",
    "help": "\u003cb\u003eConsent State\u003c/b\u003e returns the state of one consent type (pick the type and value below). The flag options return a single value: booleans for Consent Mode Active / GPC, \"granted\" / \"denied\" for Ads Signals. \u003cb\u003eRaw Details\u003c/b\u003e returns an object with everything decoded from the gcd string."
  },
  {
    "type": "SELECT",
    "name": "consentCategory",
    "displayName": "Consent Type",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "ad_storage",
        "displayValue": "Ad Storage"
      },
      {
        "value": "analytics_storage",
        "displayValue": "Analytics Storage"
      },
      {
        "value": "ad_user_data",
        "displayValue": "Ad User Data"
      },
      {
        "value": "ad_personalization",
        "displayValue": "Ad Personalization"
      },
      {
        "value": "all",
        "displayValue": "All (everything decoded)"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "ad_storage",
    "enablingConditions": [
      {
        "paramName": "dataType",
        "paramValue": "consent",
        "type": "EQUALS"
      }
    ],
    "help": "\u003cb\u003eAll\u003c/b\u003e returns every consent type plus flags and raw values in one object (same as the Raw Details data type); the Value field is ignored."
  },
  {
    "type": "SELECT",
    "name": "outputFormat",
    "displayName": "Value",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "object",
        "displayValue": "All"
      },
      {
        "value": "string",
        "displayValue": "Default + Update (as text)"
      },
      {
        "value": "effective",
        "displayValue": "Effective"
      },
      {
        "value": "update",
        "displayValue": "Update"
      },
      {
        "value": "default",
        "displayValue": "Default"
      },
      {
        "value": "implicit",
        "displayValue": "Implicit"
      },
      {
        "value": "declare",
        "displayValue": "Declare"
      },
      {
        "value": "delegated",
        "displayValue": "Delegated"
      },
      {
        "value": "containerScoped",
        "displayValue": "Container Scoped"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "object",
    "enablingConditions": [
      {
        "paramName": "dataType",
        "paramValue": "consent",
        "type": "EQUALS"
      }
    ],
    "help": "\u003cb\u003eAll\u003c/b\u003e returns an object with every value, \u003cb\u003eDefault + Update (as text)\u003c/b\u003e returns \"default:...|update:...\". Single values return \"granted\", \"denied\" or \"-\" (not set). \u003cb\u003eEffective\u003c/b\u003e is the final resolved state (update \u0026gt; default \u0026gt; declare \u0026gt; implicit, honouring delegation). \u003cb\u003eDelegated\u003c/b\u003e returns the consent type this one is delegated to, \"other\", or \"-\". \u003cb\u003eContainer Scoped\u003c/b\u003e returns the container scoped default for this type."
  }
]


___SANDBOXED_JS_FOR_SERVER___

// Google Consent String (gcd) Decoder
// Analytics Debugger S.L.U. 2025 - David Vallejo
// Reference: https://thyngster.com/google-consent-mode-internals-consent-decision-chain-and-the-gcd-string

const getRequestQueryParameter = require('getRequestQueryParameter');

const BASE64URL = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_";
const CONSENT_TYPES = ["ad_storage", "analytics_storage", "ad_user_data", "ad_personalization"];

// gcd layout (12 chars, older strings stop at 10):
//   0      version, always "1"
//   1-8    two chars per consent type
//            1st: delegation (bits 2-5) | implicit (bits 0-1)
//            2nd: declare (bits 4-5) | default (bits 2-3) | update (bits 0-1)
//   9      flags: gpc (bit 3) | active (bit 2) | ads signals (bits 0-1)
//   10-11  container scoped defaults (+ "used" bit 2 of char 11)
// Every 2-bit state: 2 = denied, 3 = granted, anything else = not set.

// --- Settings ---
// Field names match v1 (consentCategory, outputFormat), so existing variables keep
// their configuration whether or not they get re-saved with this version.

const consentCategory = data.consentCategory;

// v1 variables have no dataType: category "all" means raw details, anything else a consent state
const dataType = data.dataType || (consentCategory === "all" ? "raw" : "consent");

// v1 "object" / "string" are kept as the "All" / "Default + Update (as text)" values
const outputFormat = data.outputFormat || "object";

// --- Read and validate ---

// Source: request query parameter (default, also for v1 configs) or a custom value
const gcd = data.gcdSource === "custom" ? data.gcdValue : getRequestQueryParameter('gcd');

if (typeof gcd !== "string" || gcd.length < 10 || gcd.charAt(0) !== "1") return false;

const chars = [];
for (let i = 0; i < 12; i++) {
  const value = i < gcd.length ? BASE64URL.indexOf(gcd.charAt(i)) : 0;
  if (value === -1) return false;
  chars.push(value);
}

// --- State helpers ---

const toBool = (state) => state === 3 ? true : (state === 2 ? false : undefined);
const toLabel = (bool) => bool === true ? "granted" : (bool === false ? "denied" : undefined);

// --- Consent types ---

const details = {};
const raw = { gcd: gcd };

for (let i = 0; i < CONSENT_TYPES.length; i++) {
  const type = CONSENT_TYPES[i];
  const first = chars[1 + i * 2];
  const second = chars[2 + i * 2];
  const delegation = first >> 2;

  raw[type] = {
    implicit: toBool(first & 3),
    declare: toBool((second >> 4) & 3),
    default: toBool((second >> 2) & 3),
    update: toBool(second & 3)
  };

  if (delegation === 8) {
    raw[type].delegatedTo = "other";
  } else if (delegation >= 12) {
    raw[type].delegatedTo = CONSENT_TYPES[delegation - 12];
  }

  details[type] = {
    implicit: toLabel(raw[type].implicit) || "-",
    declare: toLabel(raw[type].declare) || "-",
    default: toLabel(raw[type].default) || "-",
    update: toLabel(raw[type].update) || "-",
    delegated: raw[type].delegatedTo || "-"
  };
}

// --- Effective consent ---
// Follows delegation (cycles resolve to undefined), then
// takes the first set value of: update > default > declare > implicit.

const resolveEffective = (type) => {
  const seen = [];
  let current = type;

  while (raw[current].delegatedTo && raw[current].delegatedTo !== "other") {
    if (seen.indexOf(current) !== -1) return undefined;
    seen.push(current);
    current = raw[current].delegatedTo;
  }

  const own = raw[current];
  const order = [own.update, own.default, own.declare, own.implicit];

  for (let i = 0; i < order.length; i++) {
    if (order[i] !== undefined) return toLabel(order[i]);
  }

  return undefined;
};

const effective = {};
for (let i = 0; i < CONSENT_TYPES.length; i++) {
  const type = CONSENT_TYPES[i];
  effective[type] = resolveEffective(type);
  details[type].effective = effective[type] || "-";
}

// --- Flags ---

raw.flags = {
  active: !!((chars[9] >> 2) & 1),
  gpc: !!((chars[9] >> 3) & 1),
  adsSignals: toBool(chars[9] & 3),
  usedContainerScopedDefaults: !!((chars[11] >> 2) & 1)
};

const flags = {
  isConsentModeActive: raw.flags.active,
  isGlobalPrivacyControlEnabled: raw.flags.gpc,
  adsSignals: toLabel(raw.flags.adsSignals),
  usedContainerScopedDefaults: raw.flags.usedContainerScopedDefaults
};

// --- Container scoped defaults ---
// [char index, bit shift] per consent type

const CONTAINER_BITS = [[10, 4], [10, 2], [10, 0], [11, 0]];

raw.containerScopedDefaults = {};
const containerScopedDefaults = {};

for (let i = 0; i < CONSENT_TYPES.length; i++) {
  const type = CONSENT_TYPES[i];
  const value = toBool((chars[CONTAINER_BITS[i][0]] >> CONTAINER_BITS[i][1]) & 3);

  raw.containerScopedDefaults[type] = value;
  if (value !== undefined) containerScopedDefaults[type] = toLabel(value);
  details[type].containerScoped = toLabel(value) || "-";
}

// --- Output ---

// Everything decoded
const rawDetails = () => {
  const all = {};
  for (let i = 0; i < CONSENT_TYPES.length; i++) {
    all[CONSENT_TYPES[i]] = details[CONSENT_TYPES[i]];
  }
  all.effective = effective;
  all.containerScopedDefaults = containerScopedDefaults;
  all.flags = flags;
  all.raw = raw;
  return all;
};

if (dataType === "consent") {
  // "All" consent type (also what v1 "All" variables map to)
  if (consentCategory === "all") return rawDetails();

  const d = details[consentCategory];
  if (!d) return undefined;

  if (outputFormat === "object") return d;
  // v1 text format, kept unchanged
  if (outputFormat === "string") return "default:" + d.default + "|update:" + d.update;

  return d[outputFormat];
}

if (dataType === "isConsentModeActive" || dataType === "isGlobalPrivacyControlEnabled" || dataType === "adsSignals") {
  return flags[dataType];
}

if (dataType === "raw") return rawDetails();

return undefined;


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "queryParametersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "queryParameterWhitelist",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "queryParameter"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "gcd"
                  }
                ]
              }
            ]
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Consent type - all values
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13r3r3r3r5l1';
      return undefined;
    });

    assertThat(runCode({ dataType: 'consent', consentCategory: 'ad_storage', outputFormat: 'object' })).isEqualTo({
      implicit: 'granted', declare: '-', default: 'denied', update: 'granted', delegated: '-', effective: 'granted', containerScoped: '-'
    });
- name: Consent type - single values
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13p3t1t1q5l1';
      return undefined;
    });

    const run = (field) => runCode({ dataType: 'consent', consentCategory: 'ad_storage', outputFormat: field });

    assertThat(run('update')).isEqualTo('-');
    assertThat(run('default')).isEqualTo('denied');
    assertThat(run('implicit')).isEqualTo('granted');
    assertThat(run('declare')).isEqualTo('-');
    assertThat(run('delegated')).isEqualTo('-');
    assertThat(run('effective')).isEqualTo('denied');
- name: Delegation - delegated value and effective consent follow the target type
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13rMt3r3r5l1';
      return undefined;
    });

    assertThat(runCode({ dataType: 'consent', consentCategory: 'analytics_storage', outputFormat: 'delegated' })).isEqualTo('ad_storage');
    assertThat(runCode({ dataType: 'consent', consentCategory: 'analytics_storage', outputFormat: 'effective' })).isEqualTo('granted');
- name: Effective value per consent type
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13p3t1t1q5l1';
      return undefined;
    });

    const run = (type) => runCode({ dataType: 'consent', consentCategory: type, outputFormat: 'effective' });

    assertThat(run('ad_storage')).isEqualTo('denied');
    assertThat(run('analytics_storage')).isEqualTo('granted');
    assertThat(run('ad_user_data')).isEqualTo('granted');
    assertThat(run('ad_personalization')).isEqualTo('denied');
- name: Flag values
  code: |-
    let gcd = '13r3r3r3r5l1';
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return gcd;
      return undefined;
    });

    assertThat(runCode({ dataType: 'isConsentModeActive' })).isEqualTo(true);
    assertThat(runCode({ dataType: 'isGlobalPrivacyControlEnabled' })).isEqualTo(false);
    assertThat(runCode({ dataType: 'adsSignals' })).isEqualTo(undefined);

    gcd = '13r3r3r3rfl1';
    assertThat(runCode({ dataType: 'isGlobalPrivacyControlEnabled' })).isEqualTo(true);
    assertThat(runCode({ dataType: 'adsSignals' })).isEqualTo('granted');
- name: Container scoped default per consent type
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13r3r3r3r5zn';
      return undefined;
    });

    const run = (type) => runCode({ dataType: 'consent', consentCategory: type, outputFormat: 'containerScoped' });

    assertThat(run('ad_storage')).isEqualTo('denied');
    assertThat(run('analytics_storage')).isEqualTo('-');
    assertThat(run('ad_user_data')).isEqualTo('granted');
    assertThat(run('ad_personalization')).isEqualTo('granted');
- name: Raw details - full output structure
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13r3r3r3r5l1';
      return undefined;
    });

    let variableResult = runCode({ dataType: 'raw' });

    assertThat(variableResult.ad_storage.update).isEqualTo('granted');
    assertThat(variableResult.effective.analytics_storage).isEqualTo('granted');
    assertThat(variableResult.flags.isConsentModeActive).isEqualTo(true);
    assertThat(variableResult.raw.gcd).isEqualTo('13r3r3r3r5l1');
- name: v1 variables that were never re-saved keep working
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13r3r3r3r5';
      return undefined;
    });

    assertThat(runCode({ consentCategory: 'ad_storage', outputFormat: 'string' }))
      .isEqualTo('default:denied|update:granted');
    assertThat(runCode({ consentCategory: 'ad_storage', outputFormat: 'object' }).update).isEqualTo('granted');
    assertThat(runCode({ consentCategory: 'all', outputFormat_all: 'object' }).ad_storage.default).isEqualTo('denied');
- name: v1 variables re-saved with the new fields keep working
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13r3r3r3r5';
      return undefined;
    });

    const resaved = (config) => {
      config.gcdSource = 'request';
      config.dataType = 'consent';
      return runCode(config);
    };

    assertThat(resaved({ consentCategory: 'ad_storage', outputFormat: 'string' }))
      .isEqualTo('default:denied|update:granted');
    assertThat(resaved({ consentCategory: 'ad_storage', outputFormat: 'object' }).update).isEqualTo('granted');
    assertThat(resaved({ consentCategory: 'all', outputFormat_all: 'object' }).ad_storage.default).isEqualTo('denied');
- name: Invalid or missing gcd returns false
  code: |-
    let gcd = '1xyz';
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return gcd;
      return undefined;
    });

    assertThat(runCode({ dataType: 'raw' })).isEqualTo(false);
    gcd = undefined;
    assertThat(runCode({ dataType: 'raw' })).isEqualTo(false);
- name: Custom value source
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13p3t1t1q5l1';
      return undefined;
    });

    const run = (source) => runCode({
      gcdSource: source,
      gcdValue: '13r3r3r3r5l1',
      dataType: 'consent',
      consentCategory: 'ad_storage',
      outputFormat: 'update'
    });

    assertThat(run('custom')).isEqualTo('granted');
    assertThat(run('request')).isEqualTo('-');
    assertThat(runCode({ gcdSource: 'custom', gcdValue: '', dataType: 'raw' })).isEqualTo(false);


___NOTES___

Created on 8/11/2025, 11:21:34 AM


