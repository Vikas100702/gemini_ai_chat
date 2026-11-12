// backend/eslint.config.js
import js from "@eslint/js";
import tsPlugin from "typescript-eslint";
import prettierConfig from "eslint-config-prettier";

export default [
    js.configs.recommended,
    ...tsPlugin.configs.recommended,
    prettierConfig,
    {
        languageOptions: {
            ecmaVersion: 2022,
            sourceType: "module",
        },
        rules: {
            "no-console": "warn",
            "@typescript-eslint/no-unused-vars": [
                "error",
                { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }
            ],
            "@typescript-eslint/explicit-function-return-type": "off",
            "@typescript-eslint/no-explicit-any": "error"
        }
    },
    {
        ignores: ["dist/**", "node_modules/**"]
    }
];