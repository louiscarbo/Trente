#!/usr/bin/env python3
"""Converts the iOS string catalog (Localizable.xcstrings) into Android string resources.

Usage: python3 -I scripts/convert_strings.py ../Trente/Localizable.xcstrings app/src/main

Sentences that exist only on Android live in scripts/android_strings.json and are merged in.

The English sentence stays the key the code uses (`localized("Needs")`); this script writes one
`strings.xml` per locale plus `StringKeys.kt`, which maps each key to its resource id.
"""
import hashlib
import json
import os
import re
import sys
from xml.sax.saxutils import escape

LOCALE_FOLDERS = {
    "en": "values",
    "en-GB": "values-en-rGB",
    "fr": "values-fr",
    "es": "values-es",
    "es-419": "values-b+es+419",
    "de": "values-de",
    "it": "values-it",
    "ko": "values-ko",
    "pt-BR": "values-pt-rBR",
    "pt-PT": "values-pt-rPT",
}

# Nouns inside Apple's `^[%lld noun](inflect: true)` markup, by language, singular -> plural.
INFLECTIONS = {
    "en": {"Month": "Months", "transaction": "transactions"},
    "en-GB": {"Month": "Months", "transaction": "transactions"},
    "fr": {"Mois": "Mois", "mois": "mois", "transaction": "transactions"},
    "es": {"Mes": "Meses", "mes": "meses", "transacción": "transacciones"},
    "es-419": {"Mes": "Meses", "mes": "meses", "transacción": "transacciones"},
    "de": {"Monat": "Monate", "Transaktion": "Transaktionen"},
    "it": {"Mese": "Mesi", "mese": "mesi", "transazione": "transazioni"},
    "ko": {},
    "pt-BR": {"Mês": "Meses", "mês": "meses", "transação": "transações"},
    "pt-PT": {"Mês": "Meses", "mês": "meses", "transação": "transações"},
}

JAVA_KEYWORDS = {
    "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class", "const", "continue", "default", "do",
    "double", "else", "enum", "extends", "final", "finally", "float", "for", "goto", "if", "implements", "import", "instanceof",
    "int", "interface", "long", "native", "new", "package", "private", "protected", "public", "return", "short", "static",
    "strictfp", "super", "switch", "synchronized", "this", "throw", "throws", "transient", "try", "void", "volatile", "while",
    "true", "false", "null",
}

PLACEHOLDER = re.compile(r"%(\d+\$)?(@|lld|ld|d|lf|f|s)")
INFLECT = re.compile(r"\^\[(.*?)\]\(inflect: true\)")


def resource_name(key: str, used: set) -> str:
    base = re.sub(r"[^a-z0-9]+", "_", key.lower()).strip("_")
    base = re.sub(r"_+", "_", base)[:48].strip("_")
    if not base:
        base = "text"
    if base[0].isdigit():
        base = "s_" + base
    if base in JAVA_KEYWORDS:
        base = base + "_"
    name = base
    if name in used:
        name = base + "_" + hashlib.sha1(key.encode("utf-8")).hexdigest()[:6]
    used.add(name)
    return name


def android_placeholders(text: str) -> str:
    index = [0]

    def replace(match):
        position = match.group(1)
        kind = match.group(2)
        if position:
            number = position[:-1]
        else:
            index[0] += 1
            number = str(index[0])
        if kind in ("@", "s"):
            return "%" + number + "$s"
        if kind in ("lf", "f"):
            return "%" + number + "$.2f"
        return "%" + number + "$d"

    return PLACEHOLDER.sub(replace, text)


def android_escape(text: str) -> str:
    text = escape(text)
    text = text.replace("\\", "\\\\")
    text = text.replace("'", "\\'").replace('"', '\\"')
    text = text.replace("\n", "\\n").replace("\t", "\\t")
    if text.startswith("@") or text.startswith("?"):
        text = "\\" + text
    return text


def inflected(text: str, language: str):
    """Returns (one, other) for a string carrying Apple's inflection markup, or None."""
    match = INFLECT.search(text)
    if not match:
        return None
    inner = match.group(1)
    words = inner.split(" ")
    noun = words[-1]
    plural_noun = INFLECTIONS.get(language, {}).get(noun, noun + "s")
    one = text[: match.start()] + inner + text[match.end():]
    other = text[: match.start()] + " ".join(words[:-1] + [plural_noun]) + text[match.end():]
    return one, other


def main():
    source, output = sys.argv[1], sys.argv[2]
    with open(source, encoding="utf-8") as handle:
        catalog = json.load(handle)
    strings = catalog["strings"]
    source_language = catalog.get("sourceLanguage", "en")

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "android_strings.json"), encoding="utf-8") as handle:
        for key, translations in json.load(handle).items():
            strings[key] = {"localizations": {language: {"stringUnit": {"value": value}} for language, value in translations.items()}}

    used = set()
    names = {}
    for key in sorted(strings):
        if not key:
            continue
        names[key] = resource_name(key, used)

    def unit_value(entry, language, key):
        localization = entry.get("localizations", {}).get(language)
        if localization is None:
            if language == source_language:
                return key
            return None
        if "variations" in localization:
            plural = localization["variations"].get("plural", {})
            return {form: unit["stringUnit"]["value"] for form, unit in plural.items()}
        unit = localization.get("stringUnit")
        if unit is None:
            return None
        return unit["value"]

    def is_plural(entry, key):
        for language in LOCALE_FOLDERS:
            value = unit_value(entry, language, key)
            if isinstance(value, dict) or (isinstance(value, str) and INFLECT.search(value)):
                return True
        return False

    plural_names = set()
    for key in sorted(strings):
        if key and is_plural(strings[key], key):
            plural_names.add(names[key])

    for language, folder in LOCALE_FOLDERS.items():
        lines = ['<?xml version="1.0" encoding="utf-8"?>', "<resources>"]
        for key in sorted(strings):
            if not key:
                continue
            entry = strings[key]
            if language != source_language and entry.get("shouldTranslate") is False:
                continue
            value = unit_value(entry, language, key)
            if value is None:
                continue
            name = names[key]
            if isinstance(value, dict):
                lines.append(f'    <plurals name="{name}">')
                for form, text in value.items():
                    lines.append(f'        <item quantity="{form}">{android_escape(android_placeholders(text))}</item>')
                lines.append("    </plurals>")
                continue
            forms = inflected(value, language)
            if forms is None and name in plural_names:
                forms = (value, value)
            if forms:
                one, other = forms
                lines.append(f'    <plurals name="{name}">')
                lines.append(f'        <item quantity="one">{android_escape(android_placeholders(one))}</item>')
                lines.append(f'        <item quantity="other">{android_escape(android_placeholders(other))}</item>')
                lines.append("    </plurals>")
                continue
            lines.append(f'    <string name="{name}">{android_escape(android_placeholders(value))}</string>')
        lines.append("</resources>")
        directory = os.path.join(output, "res", folder)
        os.makedirs(directory, exist_ok=True)
        with open(os.path.join(directory, "strings.xml"), "w", encoding="utf-8") as handle:
            handle.write("\n".join(lines) + "\n")

    kotlin = [
        "// Generated by scripts/convert_strings.py from Trente/Localizable.xcstrings. Do not edit.",
        "package app.trente.l10n",
        "",
        "import app.trente.R",
        "",
        "object StringKeys {",
        "    val ids: Map<String, Int> = mapOf(",
    ]
    plain = [key for key in sorted(names) if names[key] not in plural_names]
    plurals = [key for key in sorted(names) if names[key] in plural_names]
    kotlin += [f"        {json.dumps(key, ensure_ascii=False)} to R.string.{names[key]}," for key in plain]
    kotlin += ["    )", "", "    val pluralIds: Map<String, Int> = mapOf("]
    kotlin += [f"        {json.dumps(key, ensure_ascii=False)} to R.plurals.{names[key]}," for key in plurals]
    kotlin += ["    )", "}", ""]
    directory = os.path.join(output, "java", "app", "trente", "l10n")
    os.makedirs(directory, exist_ok=True)
    with open(os.path.join(directory, "StringKeys.kt"), "w", encoding="utf-8") as handle:
        handle.write("\n".join(kotlin))
    print(f"{len(plain)} strings, {len(plurals)} plurals, {len(LOCALE_FOLDERS)} locales")


if __name__ == "__main__":
    main()
