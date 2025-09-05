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
    "name": "consentCategory",
    "displayName": "Consent Category",
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
        "displayValue": "All"
      }
    ],
    "simpleValueType": true
  },
  {
    "type": "SELECT",
    "name": "outputFormat",
    "displayName": "Output Format",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "object",
        "displayValue": "Object"
      },
      {
        "value": "string",
        "displayValue": "String"
      }
    ],
    "simpleValueType": true,
    "enablingConditions": [
      {
        "paramName": "consentCategory",
        "paramValue": "all",
        "type": "NOT_EQUALS"
      }
    ],
    "help": "When \"All\" categories are selected, only the Object output format will be available."
  },
  {
    "type": "SELECT",
    "name": "outputFormat_all",
    "displayName": "Output Format",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "object",
        "displayValue": "Object"
      }
    ],
    "simpleValueType": true,
    "enablingConditions": [
      {
        "paramName": "consentCategory",
        "paramValue": "all",
        "type": "EQUALS"
      }
    ],
    "help": "When \"All\" categories are selected, only the Object output format will be available."
  }
]


___SANDBOXED_JS_FOR_SERVER___

// Google Consent String Decoder
// Analytics Debugger S.L.U. 2025
// David Vallejo

// API's necesarias
const getRequestQueryParameter = require('getRequestQueryParameter');

// Create base64url lookup
const BASE64URL = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_";
const BASE64URL_INDEX = BASE64URL.split('').reduce((acc, char, index) => {
  acc[char] = index;
  return acc;
}, {});

const calculatedOutputformat = data.outputFormat_all || data.outputFormat;

const parseValue = (value) => {
  const valueMap = { 1: '-', 2: 'denied', 3: 'granted' };
  return valueMap[value] || '-';
};

const parseConsentBlock = (pair) => {
  // First chars define implicit consent, we look for the explicit part
  const explicitConsentState = BASE64URL_INDEX[pair[1]];        
  const defaultVal = (explicitConsentState >> 2) & 3;
  const updateVal = explicitConsentState & 3;
  if(calculatedOutputformat === "object"){
    return {
      default: parseValue(defaultVal),
      update: parseValue(updateVal)
    };
  }else if(calculatedOutputformat === "string"){
    return 'default:'+parseValue(defaultVal)+'|update:'+parseValue(updateVal);
  }else{
     return null;
  }
};

const consentString = getRequestQueryParameter('gcd');
if(!consentString) return false;

const parsedConsentModel = {
  ad_storage: parseConsentBlock(consentString.substring(1, 3)),
  analytics_storage: parseConsentBlock(consentString.substring(3, 5)),
  ad_user_data: parseConsentBlock(consentString.substring(5, 7)),
  ad_personalization: parseConsentBlock(consentString.substring(7, 9))
};

return data.consentCategory === "all" ? parsedConsentModel : parsedConsentModel[data.consentCategory];


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
- name: Test with valid consent string - all categories
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13r3r3r3r5';
      return undefined;
    });

    const mockData = {
      consentCategory: 'all',
      outputFormat: 'object'
    };

    let variableResult = runCode(mockData);

    assertThat(variableResult).isNotEqualTo(undefined);
    assertThat(variableResult.ad_storage).isNotEqualTo(undefined);
    assertThat(variableResult.analytics_storage).isNotEqualTo(undefined);
- name: Test with valid consent string - single category
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13r3r3r3r5';
      return undefined;
    });

    const mockData = {
      consentCategory: 'ad_storage',
      outputFormat: 'string'
    };

    let variableResult = runCode(mockData);

    assertThat(variableResult).isNotEqualTo(undefined);
    assertThat(variableResult).isNotEqualTo(false);
- name: Test with no gcd parameter
  code: |-
    mock('getRequestQueryParameter', (param) => {
      return undefined;
    });

    const mockData = {
      consentCategory: 'all',
      outputFormat: 'object'
    };

    let variableResult = runCode(mockData);

    assertThat(variableResult).isEqualTo(false);
- name: Test string vs object output format
  code: |-
    mock('getRequestQueryParameter', (param) => {
      if (param === 'gcd') return '13r3r3r3r5';
      return undefined;
    });

    const mockDataObject = {
      consentCategory: 'ad_storage',
      outputFormat: 'object'
    };

    const mockDataString = {
      consentCategory: 'ad_storage',
      outputFormat: 'string'
    };

    let objectResult = runCode(mockDataObject);
    let stringResult = runCode(mockDataString);

    assertThat(objectResult).isNotEqualTo(undefined);
    assertThat(stringResult).isNotEqualTo(undefined);
    assertThat(typeof objectResult).isEqualTo('object');
    assertThat(typeof stringResult).isEqualTo('string');


___NOTES___

Created on 8/11/2025, 11:21:34 AM


