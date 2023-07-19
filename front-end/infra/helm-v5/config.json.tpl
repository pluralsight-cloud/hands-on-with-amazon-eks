{
    "config": {
        "api": {
            "resourceApi": "https://{{ eq .Release.Namespace "development" | ternary "api-development" "api" }}.{{ .Values.baseDomain }}/resources-api",
            "inventoryApi": "https://{{ eq .Release.Namespace "development" | ternary "api-development" "api" }}.{{ .Values.baseDomain }}/inventory-api",
            "clientApi": "https://{{ eq .Release.Namespace "development" | ternary "api-development" "api" }}.{{ .Values.baseDomain }}/clients-api",
            "rentingApi": "https://{{ eq .Release.Namespace "development" | ternary "api-development" "api" }}.{{ .Values.baseDomain }}/renting-api"
        }
    }
}